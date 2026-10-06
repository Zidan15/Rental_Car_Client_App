import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dl_parser.dart';

/// Service for extracting DL data using Groq Cloud API with Llama 4 Scout Vision.
/// Uses OpenAI-compatible chat/completions endpoint with JSON mode.
///
/// Why Groq over Gemini:
///   - No credit card / billing required for free tier
///   - ~30 req/min, ~14,400 req/day
///   - Does NOT train on your data (better privacy for DL images)
///   - Extremely fast inference (~200ms)
class CloudOCRService {
  static const String _model = 'qwen/qwen3.6-27b';
  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  String? _apiKey;

  /// Load API key from .env asset file
  Future<String?> _getApiKey() async {
    if (_apiKey != null && _apiKey!.isNotEmpty) return _apiKey;

    try {
      final envString = await rootBundle.loadString('.env');
      debugPrint('=== .env loaded (${envString.length} chars) ===');
      final lines = envString.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('GROQ_API_KEY=')) {
          var key = trimmed.substring('GROQ_API_KEY='.length).trim();
          if ((key.startsWith('"') && key.endsWith('"')) ||
              (key.startsWith("'") && key.endsWith("'"))) {
            key = key.substring(1, key.length - 1).trim();
          }
          _apiKey = key;
          debugPrint('=== Groq API key found (len: ${_apiKey!.length}) ===');
          return _apiKey;
        }
      }
      debugPrint('=== GROQ_API_KEY not found in .env ===');
    } catch (e) {
      debugPrint('=== Error loading .env: $e ===');
    }
    return null;
  }

  /// Extract DL fields from an image using Groq Vision API.
  /// Returns a [DLParseResult] with extracted fields, or null on failure.
  Future<DLParseResult?> extractFromImage(File imageFile) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('=== GROQ: API key not available ===');
      return null;
    }

    try {
      // Read and encode image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('=== GROQ: Image ${bytes.length} bytes ===');

      // Determine MIME type
      final path = imageFile.path.toLowerCase();
      String mimeType = 'image/jpeg';
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      // Build OpenAI-compatible request
      final url = Uri.parse('$_baseUrl/chat/completions');

      final requestBody = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': '''You are an expert OCR system for Indian Driving Licenses.
Extract the following fields from this driving license image.
Return ONLY a valid JSON object with these exact keys (use null for missing fields):

{
  "dl_number": "The DL/License number (e.g., MH02 20190001234)",
  "holder_name": "Full name of the license holder",
  "father_name": "Father's/Husband's name (S/O, D/O, W/O)",
  "date_of_birth": "DOB in DD/MM/YYYY format",
  "issue_date": "Issue date in DD/MM/YYYY format",
  "valid_till": "Validity/expiry date in DD/MM/YYYY format",
  "blood_group": "Blood group (e.g., O+, A-, B+)",
  "address": "Full address as shown on the license",
  "vehicle_classes": "Comma-separated vehicle classes (e.g., MCWG, LMV, TRANS)"
}

IMPORTANT:
- Return ONLY the JSON object, no markdown, no explanation.
- For dates, always use DD/MM/YYYY format.
- For DL number, include the state code prefix.
- For holder_name and father_name, extract ONLY the person's name. Do NOT include nearby text like 'Holder', 'Holder's Signature', 'Signature', etc.
- If a field is not visible or unclear, set it to null.''',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'temperature': 0.1,
        'max_completion_tokens': 4096,
        'response_format': {'type': 'json_object'},
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
          '=== GROQ API: Status ${response.statusCode} ===');

      if (response.statusCode == 429) {
        debugPrint('=== GROQ: Rate limited (429) ===');
        throw CloudOCRQuotaException('Groq API rate limit exceeded');
      }

      if (response.statusCode != 200) {
        debugPrint('=== GROQ API ERROR: ${response.body} ===');
        return null;
      }

      return _parseResponse(response.body);
    } on CloudOCRQuotaException {
      rethrow;
    } catch (e) {
      debugPrint('=== GROQ OCR EXCEPTION: $e ===');
      return null;
    }
  }

  /// Parse the Groq API response (OpenAI format) into a DLParseResult
  DLParseResult? _parseResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      final choices = json['choices'] as List?;

      if (choices == null || choices.isEmpty) {
        debugPrint('No choices in Groq response');
        return null;
      }

      String? text = choices[0]['message']?['content'] as String?;
      if (text == null || text.isEmpty) {
        debugPrint('No content in Groq response');
        return null;
      }

      debugPrint('=== GROQ RAW OUTPUT ===');
      debugPrint(text);
      debugPrint('=== END GROQ OUTPUT ===');

      // Clean up: remove reasoning thinking blocks (<think>...</think>)
      if (text.contains('</think>')) {
        text = text.split('</think>').last.trim();
      }

      // Remove markdown code fences if present
      text = text.trim();
      if (text.startsWith('```json')) {
        text = text.substring(7);
      } else if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      // Extract JSON substring bounded by first '{' and last '}'
      final firstBrace = text.indexOf('{');
      final lastBrace = text.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        text = text.substring(firstBrace, lastBrace + 1);
      }

      // Parse the JSON
      final Map<String, dynamic> data = jsonDecode(text);

      // Extract vehicle classes
      List<String> vehicleClasses = [];
      final vc = data['vehicle_classes'];
      if (vc != null && vc is String && vc.isNotEmpty) {
        vehicleClasses =
            vc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else if (vc != null && vc is List) {
        vehicleClasses = vc.map((s) => s.toString().trim()).where((s) => s.isNotEmpty).toList();
      }

      final result = DLParseResult(
        dlNumber: _cleanString(data['dl_number']),
        holderName: _cleanName(data['holder_name']),
        fatherName: _cleanName(data['father_name']),
        dateOfBirth: _cleanString(data['date_of_birth']),
        issueDate: _cleanString(data['issue_date']),
        validTill: _cleanString(data['valid_till']),
        bloodGroup: _cleanString(data['blood_group']),
        address: _cleanString(data['address']),
        vehicleClasses: vehicleClasses,
        rawText: text,
      );

      debugPrint('=== GROQ PARSED RESULT ===');
      debugPrint(result.toString());
      return result;
    } catch (e) {
      debugPrint('Error parsing Groq response: $e');
      return null;
    }
  }

  /// Clean a name string, removing trailing OCR artifacts like "HOLDER", "SIGNATURE", etc.
  String? _cleanName(dynamic value) {
    var s = _cleanString(value);
    if (s == null) return null;
    s = s.replaceAll(RegExp(r"\b(HOLDER['\x27]S|HOLDERS['\x27]|HOLDERS|HOLDER|HOLDE|SIGNATURE|SIGN|OF|THE)\b", caseSensitive: false), '').trim();
    s = s.replaceAll(RegExp(r"['\x27]S\b", caseSensitive: false), '').trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.isEmpty ? null : s;
  }

  /// Clean a string value, returning null for empty/null/"null" values
  String? _cleanString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  @visibleForTesting
  DLParseResult? parseResponse(String responseBody) => _parseResponse(responseBody);

  @visibleForTesting
  String? cleanName(dynamic value) => _cleanName(value);

  @visibleForTesting
  String? cleanString(dynamic value) => _cleanString(value);
}

/// Thrown when the Groq API rate limit is hit
class CloudOCRQuotaException implements Exception {
  final String message;
  CloudOCRQuotaException(this.message);

  @override
  String toString() => 'CloudOCRQuotaException: $message';
}
