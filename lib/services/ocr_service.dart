import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dl_parser.dart';
import 'cloud_ocr_service.dart';

/// Service for OCR operations — Groq Cloud AI + ML Kit fallback
class OCRService {
  final ImagePicker _picker = ImagePicker();
  final CloudOCRService _cloudService = CloudOCRService();
  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Capture photo from camera
  Future<File?> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Pick image from gallery (for testing)
  Future<File?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Extract text from image using ML Kit (returns RecognizedText with bounding boxes)
  Future<RecognizedText?> extractTextWithPositions(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      return await textRecognizer.processImage(inputImage);
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return null;
    }
  }
  
  /// Legacy method - extract just raw text
  Future<String> extractText(File imageFile) async {
    final result = await extractTextWithPositions(imageFile);
    return result?.text ?? '';
  }

  /// Primary OCR: Uses Groq Cloud AI (Llama 4 Scout Vision).
  /// If Groq fails, returns an error with [geminiUnavailable] flag
  /// so the UI can prompt the user to connect to internet or choose offline mode.
  Future<OCRResult> processLicenseImage(File imageFile) async {
    try {
      debugPrint('=== Trying Groq Cloud OCR ===');
      final cloudResult = await _cloudService.extractFromImage(imageFile);

      if (cloudResult != null && cloudResult.hasEssentialFields) {
        debugPrint('=== Groq OCR SUCCESS ===');
        return OCRResult(
          success: true,
          parseResult: cloudResult,
          imageFile: imageFile,
          source: 'Groq AI',
        );
      } else if (cloudResult != null) {
        // Cloud returned partial data (no DL number)
        debugPrint('=== Groq OCR: Partial result ===');
        return OCRResult(
          success: true,
          warning: 'Could not detect DL number. Please verify or enter manually.',
          parseResult: cloudResult,
          imageFile: imageFile,
          source: 'Groq AI',
        );
      }
    } on CloudOCRQuotaException catch (e) {
      // Rate limit hit
      debugPrint('Groq rate limit: $e');
      return OCRResult(
        success: false,
        error: 'Cloud AI rate limit reached. Please wait a moment and try again.',
        imageFile: imageFile,
        geminiUnavailable: true,
      );
    } catch (e) {
      debugPrint('Cloud OCR error: $e');
    }

    // Cloud OCR failed — don't auto-fallback, let UI decide
    debugPrint('=== Cloud OCR unavailable ===');
    return OCRResult(
      success: false,
      error: 'Cloud AI requires an internet connection for best accuracy.',
      imageFile: imageFile,
      geminiUnavailable: true,
    );
  }

  /// Explicit offline OCR: Uses on-device ML Kit + SmartDLParser.
  /// Called only when user explicitly chooses offline mode.
  Future<OCRResult> processLicenseImageOffline(File imageFile) async {
    try {
      debugPrint('=== Using On-Device ML Kit OCR ===');
      final recognizedText = await extractTextWithPositions(imageFile);

      if (recognizedText == null || recognizedText.text.isEmpty) {
        return OCRResult(
          success: false,
          error: 'Could not detect any text. Please ensure the license is clearly visible.',
          imageFile: imageFile,
        );
      }

      debugPrint('=== ML Kit RAW TEXT START ===');
      debugPrint(recognizedText.text);
      debugPrint('=== ML Kit RAW TEXT END ===');

      final parseResult = SmartDLParser.parseFromRecognizedText(recognizedText);

      if (!parseResult.hasEssentialFields) {
        return OCRResult(
          success: true,
          warning: 'Could not detect DL number. Please verify or enter manually.',
          parseResult: parseResult,
          imageFile: imageFile,
          source: 'On-Device OCR',
        );
      }

      return OCRResult(
        success: true,
        parseResult: parseResult,
        imageFile: imageFile,
        source: 'On-Device OCR',
      );
    } catch (e) {
      debugPrint('Error processing license offline: $e');
      return OCRResult(
        success: false,
        error: 'Error processing image: $e',
        imageFile: imageFile,
      );
    }
  }

  /// Check image quality with specific feedback
  ImageQualityResult checkImageQuality(File imageFile) {
    final fileSize = imageFile.lengthSync();
    
    // Very small file - likely corrupted or severely compressed
    if (fileSize < 30000) { // Less than 30KB
      return ImageQualityResult(
        isAcceptable: false,
        issueType: ImageQualityIssue.corrupted,
        issue: '📷 Image appears corrupted or too compressed.',
        suggestion: 'Please retake the photo.',
      );
    }
    
    // Small file - likely blurry or low quality
    if (fileSize < 80000) { // Less than 80KB
      return ImageQualityResult(
        isAcceptable: false,
        issueType: ImageQualityIssue.blurry,
        issue: '📷 Photo may be blurry or out of focus.',
        suggestion: 'Hold your phone steady and tap to focus before capturing.',
      );
    }
    
    // Medium-low size might indicate poor lighting
    if (fileSize < 150000) { // Less than 150KB
      return ImageQualityResult(
        isAcceptable: true,  // Allow but warn
        issueType: ImageQualityIssue.poorLighting,
        warning: '💡 Photo quality may be low due to lighting.',
        suggestion: 'Move to a well-lit area for best results.',
      );
    }
    
    // Very large file is fine
    if (fileSize > 10000000) { // More than 10MB
      return ImageQualityResult(
        isAcceptable: true,
        warning: 'Large image - processing may take a moment.',
      );
    }

    return ImageQualityResult(isAcceptable: true);
  }
  
  /// Analyze OCR result quality and provide feedback
  OCRQualityFeedback analyzeOCRQuality(OCRResult ocrResult) {
    if (ocrResult.parseResult == null) {
      return OCRQualityFeedback(
        quality: OCRQuality.poor,
        message: '❌ Could not read any text from the license.',
        suggestions: [
          'Ensure the entire license is visible in the frame',
          'Avoid glare and reflections on the card',
          'Hold the camera steady and ensure good lighting',
        ],
        canRetry: true,
        shouldShowManualEntry: true,
      );
    }
    
    final result = ocrResult.parseResult!;
    final extractedFields = <String>[];
    final missingFields = <String>[];
    
    if (result.dlNumber != null) extractedFields.add('DL Number');
    else missingFields.add('DL Number');
    
    if (result.holderName != null) extractedFields.add('Name');
    else missingFields.add('Name');
    
    if (result.dateOfBirth != null) extractedFields.add('DOB');
    else missingFields.add('DOB');
    
    if (result.fatherName != null) extractedFields.add('Father\'s Name');
    if (result.bloodGroup != null) extractedFields.add('Blood Group');
    if (result.issueDate != null) extractedFields.add('Issue Date');
    if (result.address != null) extractedFields.add('Address');
    
    // Good extraction
    if (extractedFields.length >= 4) {
      return OCRQualityFeedback(
        quality: OCRQuality.good,
        message: '✅ License data extracted successfully!',
        extractedFields: extractedFields,
        suggestions: [],
        canRetry: true,
        shouldShowManualEntry: false,
      );
    }
    
    // Partial extraction
    if (extractedFields.isNotEmpty) {
      return OCRQualityFeedback(
        quality: OCRQuality.partial,
        message: '⚠️ Some fields could not be extracted.',
        extractedFields: extractedFields,
        missingFields: missingFields,
        suggestions: [
          'You can retake for better results',
          'Or manually fill in the missing fields below',
        ],
        canRetry: true,
        shouldShowManualEntry: true,
      );
    }
    
    // Poor extraction
    return OCRQualityFeedback(
      quality: OCRQuality.poor,
      message: '❌ Could not extract license information.',
      missingFields: missingFields,
      suggestions: [
        'Ensure the license is not damaged or faded',
        'Try capturing in better lighting',
        'You can enter details manually',
      ],
      canRetry: true,
      shouldShowManualEntry: true,
    );
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer?.close();
  }
}

/// Result of OCR processing
class OCRResult {
  final bool success;
  final String? error;
  final String? warning;
  final DLParseResult? parseResult;
  final File? imageFile;
  final String? source; // 'Gemini AI' or 'On-Device OCR'
  final bool geminiUnavailable; // true when Gemini failed, UI should prompt user

  OCRResult({
    required this.success,
    this.error,
    this.warning,
    this.parseResult,
    this.imageFile,
    this.source,
    this.geminiUnavailable = false,
  });
}

/// Types of image quality issues
enum ImageQualityIssue {
  blurry,
  poorLighting,
  corrupted,
  tooLarge,
}

/// Result of image quality check
class ImageQualityResult {
  final bool isAcceptable;
  final ImageQualityIssue? issueType;
  final String? issue;
  final String? warning;
  final String? suggestion;

  ImageQualityResult({
    required this.isAcceptable,
    this.issueType,
    this.issue,
    this.warning,
    this.suggestion,
  });
}

/// Quality level of OCR extraction
enum OCRQuality { good, partial, poor }

/// Detailed feedback about OCR quality
class OCRQualityFeedback {
  final OCRQuality quality;
  final String message;
  final List<String> extractedFields;
  final List<String> missingFields;
  final List<String> suggestions;
  final bool canRetry;
  final bool shouldShowManualEntry;

  OCRQualityFeedback({
    required this.quality,
    required this.message,
    this.extractedFields = const [],
    this.missingFields = const [],
    required this.suggestions,
    required this.canRetry,
    required this.shouldShowManualEntry,
  });
}
