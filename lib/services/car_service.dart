import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/models/car_model.dart';
import 'package:flutter/foundation.dart';

class CarService {
  static const String _carsKey = 'cars';

  Future<void> _initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_carsKey) != null) return;

    final now = DateTime.now();
    final sampleCars = [
      CarModel(
        id: '1',
        name: 'Maruti Swift',
        category: 'Hatchback',
        transmission: 'Manual',
        fuelType: 'Petrol',
        seats: 5,
        imageUrl: 'assets/images/hatchback_car_null_1763115874464.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '2',
        name: 'Honda City',
        category: 'Sedan',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        seats: 5,
        imageUrl: 'assets/images/sedan_car_null_1763115872585.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '3',
        name: 'Hyundai Creta',
        category: 'Compact SUV',
        transmission: 'Automatic',
        fuelType: 'Diesel',
        seats: 5,
        imageUrl: 'assets/images/SUV_car_null_1763115873526.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '4',
        name: 'Toyota Fortuner',
        category: 'Full-Size SUV',
        transmission: 'Automatic',
        fuelType: 'Diesel',
        seats: 7,
        imageUrl: 'assets/images/SUV_car_null_1763115873526.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '5',
        name: 'Maruti Ertiga',
        category: 'MUV/7-Seater',
        transmission: 'Manual',
        fuelType: 'Petrol',
        seats: 7,
        imageUrl: 'assets/images/compact_car_null_1763115876489.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '6',
        name: 'BMW 5 Series',
        category: 'Luxury/Premium',
        transmission: 'Automatic',
        fuelType: 'Petrol',
        seats: 5,
        imageUrl: 'assets/images/luxury_car_null_1763115875303.png',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '7',
        name: 'Tata Nexon',
        category: 'Compact SUV',
        transmission: 'Automatic',
        fuelType: 'Electric',
        seats: 5,
        imageUrl: 'assets/images/compact_car_null_1763115876489.jpg',
        createdAt: now,
        updatedAt: now,
      ),
      CarModel(
        id: '8',
        name: 'Hyundai i20',
        category: 'Hatchback',
        transmission: 'Manual',
        fuelType: 'Petrol',
        seats: 5,
        imageUrl: 'assets/images/hatchback_car_null_1763115874464.jpg',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final carsJson = jsonEncode(sampleCars.map((c) => c.toJson()).toList());
    await prefs.setString(_carsKey, carsJson);
  }

  Future<List<CarModel>> searchCars({String? category, String? transmission}) async {
    try {
      await _initializeSampleData();
      final prefs = await SharedPreferences.getInstance();
      final carsJson = prefs.getString(_carsKey);
      if (carsJson == null) return [];

      final List<dynamic> carsList = jsonDecode(carsJson);
      var cars = carsList.map((json) => CarModel.fromJson(json)).toList();

      if (category != null && category.isNotEmpty) {
        cars = cars.where((car) => car.category == category).toList();
      }
      if (transmission != null && transmission.isNotEmpty) {
        cars = cars.where((car) => car.transmission == transmission).toList();
      }

      return cars;
    } catch (e) {
      debugPrint('Error searching cars: $e');
      return [];
    }
  }

  Future<CarModel?> getCarById(String id) async {
    try {
      final cars = await searchCars();
      return cars.firstWhere((car) => car.id == id);
    } catch (e) {
      debugPrint('Error getting car by id: $e');
      return null;
    }
  }
}
