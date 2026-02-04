import 'package:flutter/material.dart';
import 'package:client_app/models/listing.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:client_app/screens/payment_screen.dart';
import 'package:intl/intl.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Listing listing;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final double? locationLat;
  final double? locationLng;

  const BookingSummaryScreen({
    super.key,
    required this.listing,
    required this.startDate,
    required this.endDate,
    required this.location,
    this.locationLat,
    this.locationLng,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;
  double get totalPrice => listing.pricePerDay * numberOfDays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Car', '${listing.brand} ${listing.model}'),
            _buildInfoRow('Year', '${listing.year}'),
            _buildInfoRow('Transmission', listing.transmission ?? 'N/A'),
            _buildInfoRow('Fuel Type', listing.fuelType ?? 'N/A'),
            const SizedBox(height: 24),
            
            Text('Booking Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Pickup Location', location),
            _buildInfoRow('Start Date', DateFormat('dd MMM yyyy').format(startDate)),
            _buildInfoRow('End Date', DateFormat('dd MMM yyyy').format(endDate)),
            const SizedBox(height: 24),
            
            Text('Price Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Price per Day', '₹${listing.pricePerDay.toStringAsFixed(0)}'),
            _buildInfoRow('Number of Days', '$numberOfDays'),
            const Divider(height: 32),
            _buildInfoRow('Total Price', '₹${totalPrice.toStringAsFixed(0)}', isBold: true),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () => _confirmAndProceed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm & Request Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndProceed(BuildContext context) async {
    debugPrint('BookingSummary: Confirm button pressed');
    
    final userService = UserService();
    final bookingService = BookingService();
    
    debugPrint('BookingSummary: Getting current user...');
    final user = await userService.getCurrentUser();
    if (user == null) {
      debugPrint('BookingSummary: User is NULL!');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      return;
    }

    debugPrint('BookingSummary: User found: ${user.id}');
    debugPrint('BookingSummary: Creating booking...');
    
    try {
      final bookingId = await bookingService.createBooking(
        listing: listing,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        pickupLocation: location,
        pickupLat: locationLat,
        pickupLng: locationLng,
      );

      debugPrint('BookingSummary: Booking created successfully!');
      
      debugPrint('BookingSummary: Booking created successfully! ID: $bookingId');
      
      if (!context.mounted) return;
      
      // Navigate to My Bookings Screen (Index 1 is usually the specific tab, adjust if needed)
      // Assuming SearchInputScreen has a way to go to bookings or we pop to root
      // Ideally, we want to go MyBookings.
      
      // For now, let's pop until we are back at the main screen and switch tab, 
      // or just push MyBookingsScreen for immediate feedback.
      // Better UX: Show Success Dialog then go to Home.
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Booking Requested!'),
          content: const Text('Your booking is now pending approval from the provider. You will be notified once it is approved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // Go to home
                // Optionally trigger tab switch to My Bookings here if accessible
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      debugPrint('BookingSummary: Error creating booking: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
