import 'package:flutter/material.dart';
import 'package:client_app/models/booking_model.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final _bookingService = BookingService();
  BookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final booking = await _bookingService.getBookingById(widget.bookingId);
    setState(() {
      _booking = booking;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Car', _booking!.car.name),
            _buildInfoRow('Category', _booking!.car.category),
            _buildInfoRow('Transmission', _booking!.car.transmission),
            _buildInfoRow('Fuel Type', _booking!.car.fuelType),
            _buildInfoRow('Seats', '${_booking!.car.seats}'),
            const SizedBox(height: 24),
            Text('Provider Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Provider', _booking!.provider.name),
            _buildInfoRow('Phone', _booking!.provider.phoneNumber),
            const SizedBox(height: 24),
            Text('Booking Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Pickup Location', _booking!.pickupLocation),
            _buildInfoRow('Start Date', DateFormat('dd MMM yyyy').format(_booking!.startDate)),
            _buildInfoRow('End Date', DateFormat('dd MMM yyyy').format(_booking!.endDate)),
            _buildInfoRow('Status', _booking!.status),
            const SizedBox(height: 24),
            Text('Price Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Price per Day', '₹${_booking!.pricePerDay.toStringAsFixed(0)}'),
            _buildInfoRow('Number of Days', '${_booking!.numberOfDays}'),
            const Divider(height: 32),
            _buildInfoRow('Total Price', '₹${_booking!.totalPrice.toStringAsFixed(0)}', isBold: true),
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
}
