import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Classify-First DL Parser with Blocklist Filtering.
/// 
/// Architecture:
/// 1. Extract all words with bounding boxes from ML Kit
/// 2. CLASSIFY each word into buckets (date, dl_number, blood, name, label, other)
/// 3. Use SPATIAL ANCHORS when available (labels found → get value nearby)
/// 4. Fall back to BUCKET ASSIGNMENT when anchors missing
/// 5. Apply BLOCKLIST filtering on all results
class SmartDLParser {

  // ==================== BLOCKLIST (What a field DEFINITELY is NOT) ====================
  
  static const _notAName = {
    // Government / document words
    'INDIA', 'UNION', 'GOVERNMENT', 'STATE', 'TRANSPORT', 'REPUBLIC',
    'DRIVING', 'LICENCE', 'LICENSE', 'MOTOR', 'VEHICLE', 'DEPARTMENT',
    'FORM', 'PHOTO', 'SIGN', 'SIGNATURE', 'AUTHORITY', 'COMMISSIONER',
    'REGIONAL', 'OFFICE', 'RTO', 'DTO', 'SARATHI', 'PARIVAHAN',
    'HOLDER', 'HOLDERS', 'HOLDE', 'HOLDERSIGNATURE', 'HOLDERSIGN',
    // Field labels (including sideways text like 'DATE OF FIRST ISSUE')
    'NAME', 'DATE', 'BIRTH', 'DOB', 'BLOOD', 'GROUP', 'ADDRESS',
    'ISSUE', 'ISSUED', 'VALID', 'VALIDITY', 'EXPIRY', 'CLASS', 'COV',
    'FIRST', 'RENEWAL', 'OF', 'THE', 'NO', 'NUMBER', 'TYPE',
    // Vehicle classes
    'MCWG', 'LMV', 'HMV', 'HGMV', 'NT', 'TR', 'LMVNT', 'MCWOG',
    'MC50CC', 'HTV', 'TRANS', 'HPMV', 'MGV',
    // Other
    'ORGAN', 'DONOR', 'PIN', 'MOBILE', 'PHONE', 'EMERGENCY',
    'MALE', 'FEMALE', 'SEX', 'GENDER',
  };
  
  static const _notAnAddress = {
    'MCWG', 'LMV', 'HMV', 'HGMV', 'LMVNT', 'MCWOG', 'HTV',
    'TRANSPORT', 'LICENCE', 'LICENSE', 'DRIVING', 'SIGNATURE',
  };
  
  // ==================== ANCHOR LABELS (Loose matching) ====================
  
  static const _nameLabels = ['NAME', 'NAM', 'NM', 'नाम'];
  static const _fatherLabels = ['S/D/W', 'S/W/D', 'S/O', 'D/O', 'W/O', 'SON', 'DAUGHTER', 'WIFE', 'FATHER', 'GUARDIAN', 'HUSBAND'];
  static const _dobLabels = ['DOB', 'DATE OF BIRTH', 'BIRTH', 'D.O.B', 'जन्म'];
  static const _issueLabels = ['ISSUE', 'DOI', 'ISS', 'ISSUED', 'ISSUEDATE'];
  static const _validLabels = ['VALID', 'VALIDITY', 'EXPIRY', 'EXP', 'VALIDTILL', 'VALID TILL'];
  static const _bloodLabels = ['BLOOD', 'BG', 'B.G', 'BLOODGROUP', 'BLOOD GROUP'];
  static const _addressLabels = ['ADDRESS', 'ADD', 'ADDR', 'पता'];
  static const _dlLabels = ['DL', 'LICENSE', 'LICENCE', 'DL NO', 'DLNO', 'DL.'];
  
  // ==================== PATTERNS ====================
  
  static final _datePattern = RegExp(r'\d{2}[/\-\.]\d{2}[/\-\.]\d{4}');
  static final _bloodPattern = RegExp(r'^(A|B|AB|O|U)[+\-]?$', caseSensitive: false);
  static final _vehicleClassPattern = RegExp(
    r'\b(LMV|MCWG|MC50CC|HGMV|HMV|HGM|THGM|LMVNT|MCWOG|HPMV|MGV|LMV-TR|HTV|TRANS|NT)\b',
    caseSensitive: false,
  );
  
  // Spatial tolerances
  static const double yTolerance = 60.0;
  static const double maxDistance = 300.0;
  
  // ==================== MAIN ENTRY POINT ====================
  
  static DLParseResult parseFromRecognizedText(RecognizedText recognizedText) {
    final rawText = recognizedText.text.toUpperCase();
    
    // STEP 1: Extract all word-level elements with positions
    final elements = <TextElement>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          elements.add(TextElement(
            text: element.text.trim().toUpperCase(),
            boundingBox: element.boundingBox,
          ));
        }
      }
    }
    
    debugPrint('=== Smart Parser: ${elements.length} word elements ===');
    for (final e in elements) {
      debugPrint('  "${e.text}" at (${e.boundingBox.left.toInt()}, ${e.boundingBox.top.toInt()})');
    }
    
    // STEP 2: Classify every element into buckets
    final buckets = _classifyElements(elements);
    
    debugPrint('=== Buckets ===');
    debugPrint('  Dates: ${buckets.dates.map((e) => e.text).toList()}');
    debugPrint('  DL Numbers: ${buckets.dlNumbers.map((e) => e.text).toList()}');
    debugPrint('  Blood Groups: ${buckets.bloodGroups.map((e) => e.text).toList()}');
    debugPrint('  Possible Names: ${buckets.possibleNames.map((e) => e.text).toList()}');
    debugPrint('  Labels: ${buckets.labels.map((e) => e.text).toList()}');
    
    // STEP 3: Try spatial anchor assignment first, then bucket fallback
    final result = _assignFields(elements, buckets, rawText);
    
    debugPrint('=== Parsed Result ===');
    debugPrint(result.toString());
    
    return result;
  }
  
  // ==================== STEP 2: CLASSIFY ELEMENTS ====================
  
  static _Buckets _classifyElements(List<TextElement> elements) {
    final dates = <TextElement>[];
    final dlNumbers = <TextElement>[];
    final bloodGroups = <TextElement>[];
    final possibleNames = <TextElement>[];
    final labels = <TextElement>[];
    final other = <TextElement>[];
    
    for (final e in elements) {
      final text = e.text.trim();
      if (text.isEmpty || text.length == 1) continue;
      
      // Is it a DATE?
      if (_datePattern.hasMatch(text)) {
        dates.add(e);
        continue;
      }
      
      // Is it a DL NUMBER?
      if (_looksLikeDLNumber(text)) {
        dlNumbers.add(e);
        continue;
      }
      
      // Is it a BLOOD GROUP?
      final cleanBlood = text.replaceAll(' ', '');
      if (_bloodPattern.hasMatch(cleanBlood) && cleanBlood.length <= 3) {
        bloodGroups.add(e);
        continue;
      }
      
      // Is it a LABEL/KEYWORD?
      if (_isLabel(text)) {
        labels.add(e);
        continue;
      }
      
      // Is it a possible NAME? (mostly letters, not in blocklist)
      if (_couldBeName(text)) {
        possibleNames.add(e);
        continue;
      }
      
      other.add(e);
    }
    
    return _Buckets(
      dates: dates,
      dlNumbers: dlNumbers,
      bloodGroups: bloodGroups,
      possibleNames: possibleNames,
      labels: labels,
      other: other,
    );
  }
  
  // ==================== STEP 3: ASSIGN FIELDS ====================
  
  static DLParseResult _assignFields(List<TextElement> elements, _Buckets buckets, String rawText) {
    String? dlNumber;
    String? holderName;
    String? fatherName;
    String? dateOfBirth;
    String? issueDate;
    String? validTill;
    String? bloodGroup;
    String? address;
    
    // --- DL NUMBER ---
    // Try anchor first
    dlNumber = _getValueNearLabel(elements, _dlLabels, filter: (text) => _looksLikeDLNumber(text));
    // Bucket fallback
    dlNumber ??= buckets.dlNumbers.isNotEmpty ? _normalizeDL(buckets.dlNumbers.first.text) : null;
    // Regex fallback on raw text
    dlNumber ??= _findDLInRawText(rawText);
    
    // --- DATES (using anchors to assign correctly) ---
    dateOfBirth = _getDateNearLabel(elements, _dobLabels);
    issueDate = _getDateNearLabel(elements, _issueLabels);
    validTill = _getDateNearLabel(elements, _validLabels);
    
    // SMART DATE ASSIGNMENT: ALWAYS use year logic to verify/correct
    // DOB = oldest year (e.g. 1990), Issue = recent past (e.g. 2015), Valid = future (e.g. 2035)
    final allDates = <String>{}; // Use Set to avoid duplicates
    for (final d in buckets.dates) {
      final dateStr = _extractDateFromText(d.text);
      if (dateStr != null) allDates.add(dateStr);
    }
    // Add any anchor-found dates
    if (dateOfBirth != null) allDates.add(dateOfBirth);
    if (issueDate != null) allDates.add(issueDate);
    if (validTill != null) allDates.add(validTill);
    
    // ALWAYS smart-sort ALL dates, then verify/override anchor assignments
    if (allDates.length >= 2) {
      final sorted = _smartSortDates(allDates.toList());
      debugPrint('Smart date sort: DOB=${sorted['dob']}, Issue=${sorted['issue']}, Valid=${sorted['valid']}');
      
      // Override with smart-sorted values (year logic is more reliable than anchors)
      if (sorted['dob'] != null) dateOfBirth = sorted['dob'];
      if (sorted['issue'] != null) issueDate = sorted['issue'];
      if (sorted['valid'] != null) validTill = sorted['valid'];
    } else if (allDates.length == 1) {
      final sorted = _smartSortDates(allDates.toList());
      dateOfBirth ??= sorted['dob'];
      issueDate ??= sorted['issue'];
      validTill ??= sorted['valid'];
    }
    
    // --- BLOOD GROUP ---
    bloodGroup = _getValueNearLabel(elements, _bloodLabels, filter: (text) {
      final clean = text.replaceAll(' ', '');
      return _bloodPattern.hasMatch(clean) && clean.length <= 3;
    });
    bloodGroup ??= buckets.bloodGroups.isNotEmpty ? buckets.bloodGroups.first.text : null;
    
    // --- NAMES ---
    // Try anchor-based first
    holderName = _getNameNearLabel(elements, _nameLabels, buckets);
    fatherName = _getNameNearLabel(elements, _fatherLabels, buckets);
    
    // Bucket fallback: first name-like words not yet used
    if (holderName == null && buckets.possibleNames.isNotEmpty) {
      // Sort by Y position (names usually appear first on DL)
      final sortedNames = List<TextElement>.from(buckets.possibleNames)
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      
      // Group words on the same line into full names
      final nameGroups = _groupWordsOnSameLine(sortedNames);
      
      if (nameGroups.isNotEmpty) {
        holderName = nameGroups[0];
        debugPrint('Name (bucket fallback): $holderName');
      }
      if (nameGroups.length > 1 && fatherName == null) {
        fatherName = nameGroups[1];
        debugPrint('Father (bucket fallback): $fatherName');
      }
    }
    
    // --- ADDRESS ---
    address = _getAddressNearLabel(elements, rawText);
    
    // --- VEHICLE CLASSES ---
    final vehicleClasses = _extractVehicleClasses(rawText);
    
    return DLParseResult(
      dlNumber: dlNumber,
      holderName: holderName,
      fatherName: fatherName,
      dateOfBirth: dateOfBirth,
      issueDate: issueDate,
      validTill: validTill,
      bloodGroup: bloodGroup,
      address: address,
      vehicleClasses: vehicleClasses,
      rawText: rawText,
    );
  }
  
  // ==================== SPATIAL ANCHOR METHODS ====================
  
  /// Find a label element matching any of the given label strings
  static TextElement? _findLabel(List<TextElement> elements, List<String> labelStrings) {
    for (final e in elements) {
      for (final label in labelStrings) {
        if (e.text.contains(label.toUpperCase())) {
          return e;
        }
      }
    }
    return null;
  }
  
  /// Get value near a label, with optional filter
  static String? _getValueNearLabel(List<TextElement> elements, List<String> labelStrings, {bool Function(String)? filter}) {
    final label = _findLabel(elements, labelStrings);
    if (label == null) return null;
    
    // Check for embedded value (e.g., "DL: GA0120190001234")
    if (label.text.contains(':')) {
      final afterColon = label.text.split(':').last.trim();
      if (afterColon.isNotEmpty && (filter == null || filter(afterColon))) {
        debugPrint('  Found embedded: "$afterColon" in "${label.text}"');
        return afterColon;
      }
    }
    
    // Find nearest element to the RIGHT or BELOW
    TextElement? best;
    double bestDist = double.infinity;
    
    for (final e in elements) {
      if (e.text == label.text) continue;
      if (e.text.isEmpty) continue;
      if (filter != null && !filter(e.text)) continue;
      
      final dist = _distanceBetween(label, e);
      if (dist < bestDist && dist < maxDistance) {
        // Must be to the right or below
        if (e.boundingBox.left > label.boundingBox.left || 
            e.boundingBox.top > label.boundingBox.bottom - yTolerance) {
          bestDist = dist;
          best = e;
        }
      }
    }
    
    if (best != null) {
      debugPrint('  Near label "${label.text}": "${best.text}" (dist: ${bestDist.toInt()})');
      return best.text;
    }
    return null;
  }
  
  /// Get date near a label
  static String? _getDateNearLabel(List<TextElement> elements, List<String> labelStrings) {
    final label = _findLabel(elements, labelStrings);
    if (label == null) return null;
    
    // Check embedded
    if (label.text.contains(':')) {
      final dateInText = _extractDateFromText(label.text.split(':').last);
      if (dateInText != null) {
        debugPrint('  Date embedded in "${label.text}": $dateInText');
        return dateInText;
      }
    }
    
    // Find nearest date element
    TextElement? best;
    double bestDist = double.infinity;
    
    for (final e in elements) {
      if (e.text == label.text) continue;
      final dateStr = _extractDateFromText(e.text);
      if (dateStr == null) continue;
      
      final dist = _distanceBetween(label, e);
      if (dist < bestDist && dist < maxDistance) {
        if (e.boundingBox.left > label.boundingBox.left || 
            e.boundingBox.top > label.boundingBox.bottom - yTolerance) {
          bestDist = dist;
          best = e;
        }
      }
    }
    
    if (best != null) {
      final dateStr = _extractDateFromText(best.text);
      debugPrint('  Date near "${label.text}": $dateStr (dist: ${bestDist.toInt()})');
      return dateStr;
    }
    return null;
  }
  
  /// Get name near a label (combines adjacent words on same line)
  static String? _getNameNearLabel(List<TextElement> elements, List<String> labelStrings, _Buckets buckets) {
    final label = _findLabel(elements, labelStrings);
    if (label == null) return null;
    
    // Check embedded value
    if (label.text.contains(':')) {
      final afterColon = label.text.split(':').last.trim();
      if (afterColon.isNotEmpty && _couldBeName(afterColon)) {
        debugPrint('  Name embedded: "$afterColon"');
        return afterColon;
      }
    }
    
    // Collect all name-like words on the same line, to the right
    final sameLineWords = <TextElement>[];
    for (final e in buckets.possibleNames) {
      if (e.text == label.text) continue;
      final isSameLine = (e.boundingBox.top - label.boundingBox.top).abs() < yTolerance;
      final isToRight = e.boundingBox.left > label.boundingBox.left;
      
      if (isSameLine && isToRight) {
        sameLineWords.add(e);
      }
    }
    
    // Also check "other" bucket for words that might be name parts
    for (final e in elements) {
      if (e.text == label.text) continue;
      if (sameLineWords.any((w) => w.text == e.text)) continue;
      
      final isSameLine = (e.boundingBox.top - label.boundingBox.top).abs() < yTolerance;
      final isToRight = e.boundingBox.left > label.boundingBox.left;
      
      if (isSameLine && isToRight && _couldBeName(e.text)) {
        sameLineWords.add(e);
      }
    }
    
    if (sameLineWords.isEmpty) return null;
    
    // Sort left to right and combine
    sameLineWords.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    final combined = sameLineWords.map((e) => e.text).join(' ');
    
    // Apply blocklist
    final cleaned = _applyNameBlocklist(combined);
    if (cleaned != null && cleaned.length > 2) {
      debugPrint('  Name near "${label.text}": $cleaned');
      return cleaned;
    }
    return null;
  }
  
  /// Get address near label (multi-line, tighter collection)
  static String? _getAddressNearLabel(List<TextElement> elements, String rawText) {
    final label = _findLabel(elements, _addressLabels);
    
    if (label != null) {
      // Collect text elements near and below the address label
      // Limit to ~250px below to avoid grabbing unrelated fields
      final maxYBelow = label.boundingBox.bottom + 250;
      final addressParts = <TextElement>[];
      
      for (final e in elements) {
        if (e.text == label.text) continue;
        
        // Skip very short text unless it's a number or hash (e.g. "#176" or "5")
        final isNumberOrHash = RegExp(r'^[\d#]+$').hasMatch(e.text);
        if (e.text.length < 2 && !isNumberOrHash) continue;
        
        if (_isLabel(e.text)) continue;
        if (_notAnAddress.contains(e.text.toUpperCase())) continue;
        
        // Skip dates, blood groups, DL numbers
        if (_datePattern.hasMatch(e.text)) continue;
        if (_bloodPattern.hasMatch(e.text.replaceAll(' ', ''))) continue;
        if (_looksLikeDLNumber(e.text)) continue;
        
        // Skip if it's probably a name (pure uppercase letters to the left/above)
        if (_notAName.contains(e.text.toUpperCase())) continue;
        
        final box = e.boundingBox;
        
        // Must be below or on same line as address label (relaxed tolerance)
        final isBelow = box.top >= label.boundingBox.top - 20;
        final isWithinRange = box.top < maxYBelow;
        // Must be roughly aligned horizontally (not too far right)
        final isNearX = (box.left - label.boundingBox.left).abs() < 300 ||
                        box.left > label.boundingBox.left;
        
        if (isBelow && isWithinRange && isNearX) {
          // Check it's not another field label
          bool isFieldLabel = false;
          for (final lbl in [..._nameLabels, ..._fatherLabels, ..._dobLabels, 
                             ..._issueLabels, ..._validLabels, ..._bloodLabels, ..._dlLabels]) {
            if (e.text.toUpperCase() == lbl.toUpperCase()) {
              isFieldLabel = true;
              break;
            }
          }
          if (!isFieldLabel) {
            addressParts.add(e);
          }
        }
      }
      
      if (addressParts.isNotEmpty) {
        // Sort by Y then X (top-to-bottom, left-to-right)
        addressParts.sort((a, b) {
          final yDiff = a.boundingBox.top.compareTo(b.boundingBox.top);
          return yDiff != 0 ? yDiff : a.boundingBox.left.compareTo(b.boundingBox.left);
        });
        
        // Group into lines using tighter tolerance (30px)
        final lines = <String>[];
        double lastY = -100;
        String currentLine = '';
        
        for (final part in addressParts) {
          if ((part.boundingBox.top - lastY).abs() > 30) {
            // New line
            if (currentLine.isNotEmpty) lines.add(currentLine.trim());
            currentLine = part.text;
          } else {
            // Same line - append
            currentLine += ' ${part.text}';
          }
          lastY = part.boundingBox.top;
        }
        if (currentLine.isNotEmpty) lines.add(currentLine.trim());
        
        // Join lines with commas, limit to 4 address lines max
        final limitedLines = lines.take(4).toList();
        final fullAddress = limitedLines.join(', ');
        if (fullAddress.length > 5) {
          debugPrint('Address (spatial, ${limitedLines.length} lines): $fullAddress');
          return fullAddress.length > 250 ? fullAddress.substring(0, 250) : fullAddress;
        }
      }
    }
    
    // Regex fallback
    final pattern = RegExp(r'ADDRESS\s*:?\s*(.+?)(?=\n\n|\bISSUE\b|\bVALID\b|\bBLOOD\b|$)', caseSensitive: false, dotAll: true);
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      final addr = match.group(1)!.trim().replaceAll('\n', ', ');
      if (addr.length > 5) {
        debugPrint('Address (regex): $addr');
        return addr.length > 250 ? addr.substring(0, 250) : addr;
      }
    }
    return null;
  }
  
  // ==================== CLASSIFICATION HELPERS ====================
  
  /// Check if text is a label/keyword (not a value)
  static bool _isLabel(String text) {
    final upper = text.toUpperCase().replaceAll(':', '').replaceAll('.', '').trim();
    final allLabels = [
      ..._nameLabels, ..._fatherLabels, ..._dobLabels, ..._issueLabels,
      ..._validLabels, ..._bloodLabels, ..._addressLabels, ..._dlLabels,
      'DATE', 'OF', 'BIRTH', 'GROUP', 'NO', 'NUMBER', 'FIRST', 'RENEWAL', 'TYPE', 'THE',
    ];
    for (final label in allLabels) {
      if (upper == label.toUpperCase() || upper == '${label.toUpperCase()}:') {
        return true;
      }
    }
    return false;
  }
  
  /// Check if a word could be part of a name
  static bool _couldBeName(String text) {
    final clean = text.replaceAll(RegExp(r'[^A-Za-z\s]'), '').trim();
    if (clean.isEmpty) return false;
    
    // Allow single letters (initials) if they are uppercase
    if (clean.length == 1) {
      return text == text.toUpperCase();
    }
    
    // Must be mostly letters
    final letterRatio = clean.length / text.length;
    if (letterRatio < 0.8) return false;
    
    // Must NOT be in blocklist
    if (_notAName.contains(clean.toUpperCase())) return false;
    
    // Must NOT be a vehicle class
    if (_vehicleClassPattern.hasMatch(clean)) return false;
    
    return true;
  }
  
  /// Check if text looks like a DL number
  static bool _looksLikeDLNumber(String text) {
    final clean = text.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
    if (clean.length >= 11 && clean.length <= 18) {
      final hasLetterPrefix = RegExp(r'^[A-Z]{2}').hasMatch(clean);
      final digitCount = clean.replaceAll(RegExp(r'[^0-9]'), '').length;
      return hasLetterPrefix && digitCount >= 8;
    }
    return false;
  }
  
  /// Apply blocklist to a name string
  static String? _applyNameBlocklist(String name) {
    // Remove individual blocked words
    final words = name.split(RegExp(r'\s+'));
    final filtered = words.where((w) {
      final upper = w.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
      // Allow single letters (initials)
      if (upper.length == 1) return true;
      return upper.isNotEmpty && !_notAName.contains(upper);
    }).toList();
    
    if (filtered.isEmpty) return null;
    
    final result = filtered.join(' ').trim();
    // Final cleanup: preserve dots/spaces for initials
    final cleaned = result.replaceAll(RegExp(r'[^A-Za-z\s\.]'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
  
  /// Group name-like words that are on the same line
  static List<String> _groupWordsOnSameLine(List<TextElement> words) {
    if (words.isEmpty) return [];
    
    final groups = <List<TextElement>>[];
    var currentGroup = <TextElement>[words[0]];
    
    for (int i = 1; i < words.length; i++) {
      final isSameLine = (words[i].boundingBox.top - currentGroup.last.boundingBox.top).abs() < yTolerance;
      if (isSameLine) {
        currentGroup.add(words[i]);
      } else {
        groups.add(currentGroup);
        currentGroup = [words[i]];
      }
    }
    groups.add(currentGroup);
    
    // Combine each group into a name string, apply blocklist
    return groups
        .map((group) {
          group.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
          final combined = group.map((e) => e.text).join(' ');
          return _applyNameBlocklist(combined);
        })
        .where((name) => name != null && name.length > 2)
        .cast<String>()
        .toList();
  }
  
  // ==================== UTILITY METHODS ====================
  
  static double _distanceBetween(TextElement a, TextElement b) {
    final ax = (a.boundingBox.left + a.boundingBox.right) / 2;
    final ay = (a.boundingBox.top + a.boundingBox.bottom) / 2;
    final bx = (b.boundingBox.left + b.boundingBox.right) / 2;
    final by = (b.boundingBox.top + b.boundingBox.bottom) / 2;
    
    final dx = bx - ax;
    final dy = by - ay;
    return (dx * dx + dy * dy).abs(); // squared distance for speed
  }
  
  static String _normalizeDL(String dl) {
    final clean = dl.replaceAll(' ', '');
    if (!clean.contains('-') && clean.length >= 2) {
      return '${clean.substring(0, 2)}-${clean.substring(2)}';
    }
    return clean;
  }
  
  static String? _extractDateFromText(String text) {
    final match = _datePattern.firstMatch(text);
    return match?.group(0);
  }
  
  static String? _findDLInRawText(String rawText) {
    // Pattern: 2 letters followed by digits with optional separators
    final pattern = RegExp(r'[A-Z]{2}[\s\-]?\d{2}[\s\-]?\d{4}[\s\-]?\d{5,7}');
    final match = pattern.firstMatch(rawText);
    if (match != null) {
      debugPrint('DL (raw text regex): ${match.group(0)}');
      return _normalizeDL(match.group(0)!);
    }
    return null;
  }
  
  static List<String> _extractVehicleClasses(String rawText) {
    final matches = _vehicleClassPattern.allMatches(rawText.toUpperCase());
    final classes = matches.map((m) => m.group(0)!).toSet().toList();
    if (classes.isNotEmpty) debugPrint('Vehicle Classes: $classes');
    return classes;
  }
  
  /// Extract year from a date string like "15/03/1990" or "15-03-1990"
  static int? _extractYear(String? dateStr) {
    if (dateStr == null) return null;
    final parts = dateStr.split(RegExp(r'[/\-\.]'));
    if (parts.length == 3) {
      final year = int.tryParse(parts[2]);
      if (year != null && year > 1900 && year < 2100) return year;
    }
    return null;
  }
  
  /// Smart sort dates by year: DOB = oldest, Issue = middle, Valid = newest
  /// Logic: Birth year is far in the past (1960-2005)
  ///        Issue year is recent past (2010-2026)
  ///        Valid year is in the future (2025-2046)
  static Map<String, String?> _smartSortDates(List<String> dates) {
    if (dates.isEmpty) return {'dob': null, 'issue': null, 'valid': null};
    
    // Parse years and sort
    final dated = <_DateWithYear>[];
    for (final d in dates) {
      final year = _extractYear(d);
      if (year != null) {
        dated.add(_DateWithYear(dateStr: d, year: year));
      }
    }
    
    if (dated.isEmpty) return {'dob': null, 'issue': null, 'valid': null};
    
    // Sort by year ascending
    dated.sort((a, b) => a.year.compareTo(b.year));
    
    // Remove duplicates
    final unique = <_DateWithYear>[];
    final seenYears = <int>{};
    for (final d in dated) {
      if (!seenYears.contains(d.year)) {
        unique.add(d);
        seenYears.add(d.year);
      }
    }
    
    String? dob, issue, valid;
    
    if (unique.length >= 3) {
      // 3+ dates: oldest = DOB, middle = Issue, newest = Valid
      dob = unique[0].dateStr;
      issue = unique[1].dateStr;
      valid = unique[unique.length - 1].dateStr;
    } else if (unique.length == 2) {
      // 2 dates: check year gap
      final gap = unique[1].year - unique[0].year;
      if (gap > 15) {
        // Big gap: older is DOB, newer could be Issue or Valid
        dob = unique[0].dateStr;
        if (unique[1].year > DateTime.now().year) {
          valid = unique[1].dateStr;
        } else {
          issue = unique[1].dateStr;
        }
      } else {
        // Small gap: likely Issue and Valid
        issue = unique[0].dateStr;
        valid = unique[1].dateStr;
      }
    } else {
      // 1 date: guess based on year
      final year = unique[0].year;
      final currentYear = DateTime.now().year;
      if (year < currentYear - 15) {
        dob = unique[0].dateStr;
      } else if (year > currentYear) {
        valid = unique[0].dateStr;
      } else {
        issue = unique[0].dateStr;
      }
    }
    
    debugPrint('Smart sort result: DOB=$dob, Issue=$issue, Valid=$valid');
    return {'dob': dob, 'issue': issue, 'valid': valid};
  }
}

/// Helper for date sorting
class _DateWithYear {
  final String dateStr;
  final int year;
  _DateWithYear({required this.dateStr, required this.year});
}

// ==================== DATA CLASSES ====================

/// Internal bucket holder for classified elements
class _Buckets {
  final List<TextElement> dates;
  final List<TextElement> dlNumbers;
  final List<TextElement> bloodGroups;
  final List<TextElement> possibleNames;
  final List<TextElement> labels;
  final List<TextElement> other;
  
  _Buckets({
    required this.dates,
    required this.dlNumbers,
    required this.bloodGroups,
    required this.possibleNames,
    required this.labels,
    required this.other,
  });
}

/// Simple text element with bounding box
class TextElement {
  final String text;
  final Rect boundingBox;
  
  TextElement({required this.text, required this.boundingBox});
}

/// Result of parsing a driving license
class DLParseResult {
  final String? dlNumber;
  final String? holderName;
  final String? fatherName;
  final String? dateOfBirth;
  final String? validTill;
  final String? bloodGroup;
  final String? address;
  final List<String> vehicleClasses;
  final String? issueDate;
  final String rawText;

  DLParseResult({
    this.dlNumber,
    this.holderName,
    this.fatherName,
    this.dateOfBirth,
    this.validTill,
    this.bloodGroup,
    this.address,
    this.vehicleClasses = const [],
    this.issueDate,
    this.rawText = '',
  });

  bool get hasEssentialFields => dlNumber != null;

  @override
  String toString() {
    return '''
DLParseResult:
  DL Number: $dlNumber
  Name: $holderName
  Father: $fatherName
  DOB: $dateOfBirth
  Valid Till: $validTill
  Blood Group: $bloodGroup
  Address: $address
  Classes: $vehicleClasses
  Issue Date: $issueDate
''';
  }
}
