import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/models/service_provider_model.dart';
import 'package:flutter/foundation.dart';

class ServiceProviderService {
  static const String _providersKey = 'serviceProviders';

  Future<void> _initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_providersKey) != null) return;

    final now = DateTime.now();
    final sampleProviders = [
      ServiceProviderModel(
        id: '1',
        name: 'Goa Wheels Rental',
        phoneNumber: '+91 9876543210',
        distanceKm: 2.5,
        pricePerDay: 1500,
        createdAt: now,
        updatedAt: now,
      ),
      ServiceProviderModel(
        id: '2',
        name: 'Beach Cars Goa',
        phoneNumber: '+91 9876543211',
        distanceKm: 4.2,
        pricePerDay: 1800,
        createdAt: now,
        updatedAt: now,
      ),
      ServiceProviderModel(
        id: '3',
        name: 'Panjim Car Rentals',
        phoneNumber: '+91 9876543212',
        distanceKm: 1.8,
        pricePerDay: 1400,
        createdAt: now,
        updatedAt: now,
      ),
      ServiceProviderModel(
        id: '4',
        name: 'Coastal Drive',
        phoneNumber: '+91 9876543213',
        distanceKm: 5.5,
        pricePerDay: 2000,
        createdAt: now,
        updatedAt: now,
      ),
      ServiceProviderModel(
        id: '5',
        name: 'Sunrise Rentals',
        phoneNumber: '+91 9876543214',
        distanceKm: 3.2,
        pricePerDay: 1600,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final providersJson = jsonEncode(sampleProviders.map((p) => p.toJson()).toList());
    await prefs.setString(_providersKey, providersJson);
  }

  Future<List<ServiceProviderModel>> getProvidersForCar(String carId, String location) async {
    try {
      await _initializeSampleData();
      final prefs = await SharedPreferences.getInstance();
      final providersJson = prefs.getString(_providersKey);
      if (providersJson == null) return [];

      final List<dynamic> providersList = jsonDecode(providersJson);
      var providers = providersList.map((json) => ServiceProviderModel.fromJson(json)).toList();

      providers.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));

      return providers;
    } catch (e) {
      debugPrint('Error getting providers: $e');
      return [];
    }
  }
}
