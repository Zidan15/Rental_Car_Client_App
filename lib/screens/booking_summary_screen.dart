import 'package:flutter/material.dart';
import 'package:client_app/models/listing.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:client_app/services/license_service.dart';
import 'package:client_app/screens/payment_screen.dart';
import 'package:client_app/screens/license_verification_screen.dart';
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
    final licenseService = LicenseService();
    
    debugPrint('BookingSummary: Getting current user...');
    final user = await userService.getCurrentUser();
    if (user == null) {
      debugPrint('BookingSummary: User is NULL!');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      return;
    }

    // ========== LICENSE VERIFICATION CHECK ==========
    debugPrint('BookingSummary: Checking license status...');
    final hasLicense = await licenseService.hasSubmittedLicense(user.id);
    
    if (!hasLicense) {
      debugPrint('BookingSummary: No license found - showing verification prompt');
      if (!context.mounted) return;
      
      // Show modal prompting user to verify
      final shouldVerify = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('License Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To complete your booking, please verify your driving license first.'),
              SizedBox(height: 12),
              Text(
                'This is a one-time verification to ensure safe rentals.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Now'),
            ),
          ],
        ),
      );
      
      if (shouldVerify == true && context.mounted) {
        // Navigate to license verification
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LicenseVerificationScreen()),
        );
        // After returning, user can tap button again
      }
      return; // Stop here - don't proceed with booking
    }
    // ================================================

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



      
      debugPrint('BookingSummary: Booking created successfully! ID: $bookingId');
      
      if (!context.mounted) return;
      
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
