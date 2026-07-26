import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:client_app/models/booking_model.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:client_app/screens/payment_screen.dart';

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
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  // ... (existing _loadBooking method)

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    try {
      await _bookingService.updateBookingStatus(widget.bookingId, 'cancelled');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
      _loadBooking(); // Refresh to show updated status
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cancelling: $e')));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
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
            _buildMapWidget(),
            
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
            
            const SizedBox(height: 32),
            
            // ACTION BUTTONS
            if (_booking!.status == 'pending')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for Approval',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The provider will review your request shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else if (_booking!.status == 'approved')
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        bookingId: _booking!.id,
                        amount: _booking!.totalPrice,
                        vehicleName: _booking!.vehicleDisplayName,
                      ),
                    ),
                  ).then((_) => _loadBooking()); // Refresh when coming back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Pay Now to Confirm'),
              )
            else if (_booking!.status == 'confirmed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Booking Confirmed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              )
            else if (_booking!.status == 'rejected')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cancel, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Booking Rejected',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[800]),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The provider has declined this booking request.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            // Cancel Button - Available for pending, approved, and confirmed bookings
            if (['pending', 'approved', 'confirmed'].contains(_booking!.status) && _booking!.status != 'rejected') ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isCancelling ? null : _cancelBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      )
                    : const Text('Cancel Booking'),
              ),
            ],
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

  Widget _buildMapWidget() {
    // If we have coordinates, show the map
    if (_booking!.pickupLat != null && _booking!.pickupLng != null) {
      final location = LatLng(_booking!.pickupLat!, _booking!.pickupLng!);
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: location,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static map
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.client_app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: location,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                  alignment: Alignment.topCenter,
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // No coordinates - show placeholder
    return Container(
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
            Icon(Icons.location_on, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Location selected from list', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

