import 'package:flutter/material.dart';
import 'package:client_app/models/booking_model.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/screens/booking_details_screen.dart';
import 'package:intl/intl.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _bookingService = BookingService();
  final _userService = UserService();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = await _userService.getCurrentUser();
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final bookings = await _bookingService.getUserBookings(user.id);
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AppBar is removed as the main Scaffold in SearchInputScreen will provide it.
    return Scaffold( 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _bookings.isEmpty
              ? const Center(child: Text('No bookings found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    return BookingCard(
                      booking: booking,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailsScreen(bookingId: booking.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const BookingCard({super.key, required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(booking.car.name, style: Theme.of(context).textTheme.titleLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status == 'Upcoming' ? Colors.black : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: booking.status == 'Upcoming' ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(booking.provider.name, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('${DateFormat('dd MMM').format(booking.startDate)} - ${DateFormat('dd MMM yyyy').format(booking.endDate)}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(booking.pickupLocation, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${booking.totalPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
                Text(booking.provider.phoneNumber, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}