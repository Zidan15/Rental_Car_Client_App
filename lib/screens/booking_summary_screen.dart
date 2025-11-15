import 'package:flutter/material.dart';
import 'package:client_app/models/car_model.dart';
import 'package:client_app/models/service_provider_model.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:client_app/screens/payment_screen.dart';
import 'package:intl/intl.dart';

class BookingSummaryScreen extends StatelessWidget {
  final CarModel car;
  final ServiceProviderModel provider;
  final DateTime startDate;
  final DateTime endDate;
  final String location;

  const BookingSummaryScreen({
    super.key,
    required this.car,
    required this.provider,
    required this.startDate,
    required this.endDate,
    required this.location,
  });

  int get numberOfDays => endDate.difference(startDate).inDays + 1;
  double get totalPrice => provider.pricePerDay * numberOfDays;

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
            _buildInfoRow('Car', car.name),
            _buildInfoRow('Category', car.category),
            _buildInfoRow('Transmission', car.transmission),
            _buildInfoRow('Fuel Type', car.fuelType),
            _buildInfoRow('Seats', '${car.seats}'),
            const SizedBox(height: 24),
            Text('Provider Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Provider', provider.name),
            _buildInfoRow('Phone', provider.phoneNumber),
            const SizedBox(height: 24),
            Text('Booking Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Pickup Location', location),
            _buildInfoRow('Start Date', DateFormat('dd MMM yyyy').format(startDate)),
            _buildInfoRow('End Date', DateFormat('dd MMM yyyy').format(endDate)),
            const SizedBox(height: 24),
            Text('Price Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Price per Day', '₹${provider.pricePerDay.toStringAsFixed(0)}'),
            _buildInfoRow('Number of Days', '$numberOfDays'),
            const Divider(height: 32),
            _buildInfoRow('Total Price', '₹${totalPrice.toStringAsFixed(0)}', isBold: true),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _confirmAndProceed(context),
              child: const Text('Confirm & Proceed to Payment'),
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
    final userService = UserService();
    final bookingService = BookingService();
    
    final user = await userService.getCurrentUser();
    if (user == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      return;
    }

    try {
      await bookingService.createBooking(
        userId: user.id,
        car: car,
        provider: provider,
        startDate: startDate,
        endDate: endDate,
        pickupLocation: location,
        totalPrice: totalPrice,
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(totalPrice: totalPrice),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
