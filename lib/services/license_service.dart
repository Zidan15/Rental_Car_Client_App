import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/models/license_model.dart';

class LicenseService {
  final _supabase = Supabase.instance.client;
  static const _bucketName = 'license-images';

  /// Upload image to Supabase Storage and return public URL
  Future<String?> uploadLicenseImage(File imageFile, String userId, String type) async {
    try {
      final fileName = '${userId}_${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.storage.from(_bucketName).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      
      // Get public URL
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      debugPrint('Uploaded image: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Submit or update user's license with all OCR data
  Future<void> submitLicense({
    required String userId,
    required String licenseNumber,
    String? frontPhotoUrl,
    String? backPhotoUrl,
    String? holderName,
    String? fatherName,
    String? dateOfBirth,
    String? bloodGroup,
    String? address,
    String? validTill,
    List<String>? vehicleClasses,
    String? issueDate,
  }) async {
    try {
      // Check if license already exists
      final existing = await getUserLicense(userId);
      
      final data = {
        'license_number': licenseNumber,
        'front_photo_url': frontPhotoUrl,
        'back_photo_url': backPhotoUrl,
        'holder_name': holderName,
        'father_name': fatherName,
        'date_of_birth': dateOfBirth,
        'blood_group': bloodGroup,
        'address': address,
        'valid_till': validTill,
        'vehicle_classes': vehicleClasses,
        'issue_date': issueDate,
        'verification_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (existing != null) {
        // Update existing license
        await _supabase.from('licenses').update(data).eq('user_id', userId);
      } else {
        // Insert new license
        data['user_id'] = userId;
        await _supabase.from('licenses').insert(data);
      }
    } catch (e) {
      debugPrint('Error submitting license: $e');
      throw Exception('Failed to submit license: $e');
    }
  }

  /// Verify license against dummy database
  Future<VerificationResult> verifyAgainstDatabase(String licenseNumber) async {
    try {
      final record = await _supabase
          .from('valid_dl_records')
          .select()
          .eq('dl_number', licenseNumber.toUpperCase().replaceAll(' ', ''))
          .maybeSingle();
      
      if (record == null) {
        return VerificationResult(
          isVerified: false,
          message: 'License not found in database. Will be manually reviewed.',
        );
      }
      
      // Check if license is active
      final status = record['status'] as String?;
      if (status != 'active') {
        return VerificationResult(
          isVerified: false,
          message: 'License is $status. Cannot be used for booking.',
        );
      }
      
      // Check if license is expired
      final validTillStr = record['valid_till'] as String?;
      if (validTillStr != null) {
        final validTill = DateTime.tryParse(validTillStr);
        if (validTill != null && validTill.isBefore(DateTime.now())) {
          return VerificationResult(
            isVerified: false,
            message: 'License has expired on $validTillStr.',
          );
        }
      }
      
      return VerificationResult(
        isVerified: true,
        message: 'License verified successfully!',
        databaseRecord: record,
      );
    } catch (e) {
      debugPrint('Error verifying license: $e');
      return VerificationResult(
        isVerified: false,
        message: 'Verification failed. Will be manually reviewed.',
      );
    }
  }

  /// Update license verification status
  Future<void> updateVerificationStatus(String userId, String status) async {
    try {
      await _supabase.from('licenses').update({
        'verification_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error updating verification status: $e');
      throw Exception('Failed to update verification status: $e');
    }
  }

  /// Get user's license
  Future<LicenseModel?> getUserLicense(String userId) async {
    try {
      final data = await _supabase
          .from('licenses')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return LicenseModel.fromJson(data);
    } catch (e) {
      debugPrint('Error getting user license: $e');
      return null;
    }
  }

  /// Check if user has submitted a license (for booking gate)
  Future<bool> hasSubmittedLicense(String userId) async {
    final license = await getUserLicense(userId);
    return license != null;
  }

  /// Check if user's license is verified
  Future<bool> isLicenseVerified(String userId) async {
    final license = await getUserLicense(userId);
    return license?.verificationStatus == 'verified';
  }

  /// [TEST MODE] Enroll a license number into the valid_dl_records table
  /// This populates the demo database so auto-verification works.
  Future<bool> enrollLicenseInDatabase({
    required String dlNumber,
    String? holderName,
    String? dateOfBirth,
    String? validTill,
  }) async {
    try {
      final cleanDL = dlNumber.toUpperCase().replaceAll(' ', '');
      
      // Check if already enrolled
      final existing = await _supabase
          .from('valid_dl_records')
          .select()
          .eq('dl_number', cleanDL)
          .maybeSingle();
      
      if (existing != null) {
        debugPrint('License $cleanDL already enrolled in database');
        return true; // Already exists, treat as success
      }

      // Default valid_till to 5 years from now
      final defaultValidTill = DateTime.now().add(const Duration(days: 365 * 5));
      
      final insertData = <String, dynamic>{
        'dl_number': cleanDL,
        'status': 'active',
        'valid_till': validTill ?? defaultValidTill.toIso8601String().split('T').first,
      };
      // Only add holder_name if available (column may not exist in older schemas)
      if (holderName != null && holderName.isNotEmpty) {
        insertData['holder_name'] = holderName;
      }
      
      // Add date_of_birth, parsing to YYYY-MM-DD if needed 
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        try {
          if (dateOfBirth.contains('/')) {
            final parts = dateOfBirth.split('/');
            if (parts.length == 3) {
              final d = parts[0].padLeft(2, '0');
              final m = parts[1].padLeft(2, '0');
              final y = parts[2];
              insertData['date_of_birth'] = '$y-$m-$d';
            } else {
              insertData['date_of_birth'] = dateOfBirth; 
            }
          } else if (dateOfBirth.contains('-')) {
             final parts = dateOfBirth.split('-');
             if (parts.length == 3 && parts[0].length <= 2) {
               final d = parts[0].padLeft(2, '0');
               final m = parts[1].padLeft(2, '0');
               final y = parts[2];
               insertData['date_of_birth'] = '$y-$m-$d';
             } else {
               insertData['date_of_birth'] = dateOfBirth;
             }
          } else {
            insertData['date_of_birth'] = dateOfBirth;
          }
        } catch (_) {
          insertData['date_of_birth'] = '2000-01-01'; // Fallback
        }
      } else {
        insertData['date_of_birth'] = '2000-01-01'; // DB requires a value
      }
      
      await _supabase.from('valid_dl_records').insert(insertData);
      
      debugPrint('License $cleanDL enrolled in test database');
      return true;
    } catch (e) {
      debugPrint('Error enrolling license: $e');
      rethrow;
    }
  }
}

class VerificationResult {
  final bool isVerified;
  final String message;
  final Map<String, dynamic>? databaseRecord;

  VerificationResult({
    required this.isVerified,
    required this.message,
    this.databaseRecord,
  });
}
