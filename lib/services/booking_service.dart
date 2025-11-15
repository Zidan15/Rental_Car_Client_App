import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:client_app/models/booking_model.dart';
import 'package:client_app/models/car_model.dart';
import 'package:client_app/models/service_provider_model.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  static const String _bookingsKey = 'bookings';

  Future<void> createBooking({
    required String userId,
    required CarModel car,
    required ServiceProviderModel provider,
    required DateTime startDate,
    required DateTime endDate,
    required String pickupLocation,
    required double totalPrice,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_bookingsKey) ?? '[]';
      final List<dynamic> bookingsList = jsonDecode(bookingsJson);

      final newBooking = BookingModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        car: car,
        provider: provider,
        startDate: startDate,
        endDate: endDate,
        pickupLocation: pickupLocation,
        totalPrice: totalPrice,
        status: 'Upcoming',
        bookingDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bookingsList.add(newBooking.toJson());
      await prefs.setString(_bookingsKey, jsonEncode(bookingsList));
    } catch (e) {
      debugPrint('Error creating booking: $e');
      throw Exception('Failed to create booking');
    }
  }

  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_bookingsKey) ?? '[]';
      final List<dynamic> bookingsList = jsonDecode(bookingsJson);

      final userBookings = bookingsList
          .map((json) => BookingModel.fromJson(json))
          .where((booking) => booking.userId == userId)
          .toList();

      userBookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

      return userBookings;
    } catch (e) {
      debugPrint('Error getting user bookings: $e');
      return [];
    }
  }

  Future<BookingModel?> getBookingById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_bookingsKey) ?? '[]';
      final List<dynamic> bookingsList = jsonDecode(bookingsJson);

      final bookingJson = bookingsList.firstWhere((b) => b['id'] == id, orElse: () => null);
      if (bookingJson == null) return null;

      return BookingModel.fromJson(bookingJson);
    } catch (e) {
      debugPrint('Error getting booking by id: $e');
      return null;
    }
  }
}
