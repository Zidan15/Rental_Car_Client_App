import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/models/license_model.dart';
import 'package:flutter/foundation.dart';

class LicenseService {
  static const String _licensesKey = 'licenses';

  Future<void> submitLicense({
    required String userId,
    required String licenseNumber,
    String? frontPhotoPath,
    String? backPhotoPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final licensesJson = prefs.getString(_licensesKey) ?? '[]';
      final List<dynamic> licensesList = jsonDecode(licensesJson);

      final existingIndex = licensesList.indexWhere((l) => l['userId'] == userId);

      final license = LicenseModel(
        id: existingIndex != -1 ? licensesList[existingIndex]['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        licenseNumber: licenseNumber,
        frontPhotoPath: frontPhotoPath,
        backPhotoPath: backPhotoPath,
        verificationStatus: 'Pending',
        createdAt: existingIndex != -1 ? DateTime.parse(licensesList[existingIndex]['createdAt']) : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingIndex != -1) {
        licensesList[existingIndex] = license.toJson();
      } else {
        licensesList.add(license.toJson());
      }

      await prefs.setString(_licensesKey, jsonEncode(licensesList));
    } catch (e) {
      debugPrint('Error submitting license: $e');
      throw Exception('Failed to submit license');
    }
  }

  Future<LicenseModel?> getUserLicense(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final licensesJson = prefs.getString(_licensesKey) ?? '[]';
      final List<dynamic> licensesList = jsonDecode(licensesJson);

      final licenseJson = licensesList.firstWhere((l) => l['userId'] == userId, orElse: () => null);
      if (licenseJson == null) return null;

      return LicenseModel.fromJson(licenseJson);
    } catch (e) {
      debugPrint('Error getting user license: $e');
      return null;
    }
  }
}
