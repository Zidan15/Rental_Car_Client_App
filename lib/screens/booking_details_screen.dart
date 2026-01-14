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
            // Vehicle Info
            Text('Vehicle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Vehicle', _booking!.vehicleDisplayName),
            if (_booking!.vehicleBrand != null)
              _buildInfoRow('Brand', _booking!.vehicleBrand!),
            if (_booking!.vehicleModel != null)
              _buildInfoRow('Model', _booking!.vehicleModel!),
            if (_booking!.vehicleYear != null)
              _buildInfoRow('Year', '${_booking!.vehicleYear}'),
            
            const SizedBox(height: 24),
            
            // Location Info
            Text('Pickup Location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Location', _booking!.pickupLocation ?? 'Not specified'),
            // Map placeholder for future integration
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map coming soon', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Booking Info
            Text('Booking Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildInfoRow('Start Date', DateFormat('dd MMM yyyy').format(_booking!.startDate)),
            _buildInfoRow('End Date', DateFormat('dd MMM yyyy').format(_booking!.endDate)),
            _buildInfoRow('Duration', '${_booking!.numberOfDays} day${_booking!.numberOfDays > 1 ? 's' : ''}'),
            _buildInfoRow('Status', _booking!.status.toUpperCase()),
            _buildInfoRow('Booked On', DateFormat('dd MMM yyyy').format(_booking!.bookingDate)),
            
            const SizedBox(height: 24),
            
            // Price
            Text('Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Divider(),
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

