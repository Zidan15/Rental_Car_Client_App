import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/models/listing.dart';
import 'package:client_app/models/booking_model.dart';

class BookingService {
  final _supabase = Supabase.instance.client;

  Future<String> createBooking({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
    required String pickupLocation,
    double? pickupLat,
    double? pickupLng,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase.from('bookings').insert({
        'vehicle_id': listing.id,
        'renter_id': userId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_price': totalPrice,
        'pickup_location': pickupLocation,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'status': 'pending', // Default status
      }).select().single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _supabase.from('bookings').update({'status': status}).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Fetch bookings for the current user
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      debugPrint('Fetching bookings for renter: $userId');
      
      // Join with vehicles to get vehicle details
      final data = await _supabase
          .from('bookings')
          .select('*, vehicles(brand, model, year)')
          .eq('renter_id', userId)
          .order('created_at', ascending: false);

      debugPrint('Bookings received: ${data.length} items');

      return (data as List<dynamic>)
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
      return [];
    }
  }

  // Fetch a single booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final data = await _supabase
          .from('bookings')
          .select('*, vehicles(brand, model, year)')
          .eq('id', bookingId)
          .single();

      return BookingModel.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
      return null;
    }
  }
}

