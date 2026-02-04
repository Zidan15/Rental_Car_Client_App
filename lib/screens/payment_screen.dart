import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:client_app/services/booking_service.dart';
import 'package:client_app/screens/my_bookings_screen.dart';
import 'package:client_app/screens/search_input_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String vehicleName;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.vehicleName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _bookingService = BookingService();
  bool _isProcessing = false;
  String _paymentMethod = 'pay_at_pickup'; // 'upi' or 'pay_at_pickup'

  Future<void> _confirmBooking() async {
    setState(() => _isProcessing = true);

    try {
      // Update status based on payment method
      // If Paid via UPI -> 'confirmed'
      // If Pay at Pickup -> 'confirmed_unpaid' (or just 'confirmed' if simplified)
      
      // For MVP Demo, we mark both as 'confirmed' but maybe add a note
      await _bookingService.updateBookingStatus(widget.bookingId, 'confirmed');

      if (!mounted) return;

      // Success! Go to My Bookings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Confirmed! 🎉')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SearchInputScreen(initialIndex: 1)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Total Amount', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.vehicleName,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Option 1: Pay at Pickup
            _buildPaymentOption(
              value: 'pay_at_pickup',
              title: 'Pay at Pickup',
              subtitle: 'Cash or Card when you collect the vehicle',
              icon: Icons.storefront_outlined,
            ),
            
            const SizedBox(height: 16),

            // Option 2: Pay Now (UPI)
            _buildPaymentOption(
              value: 'upi',
              title: 'Pay Now (UPI)',
              subtitle: 'GPay, PhonePe, Paytm',
              icon: Icons.qr_code_scanner,
            ),

            const SizedBox(height: 32),

            // UPI QR Code Section (Only if UPI selected)
            if (_paymentMethod == 'upi') ...[
              Center(
                child: Column(
                  children: [
                    const Text('Scan to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                        ],
                      ),
                      child: QrImageView(
                        data: 'upi://pay?pa=rentgoa@upi&pn=RentGoa&am=${widget.amount}&tn=Booking_${widget.bookingId}',
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This is a demo QR code.\nIn production, this would open your UPI app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Action Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _paymentMethod == 'upi' ? 'I Have Paid' : 'Confirm Booking',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    
    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.grey[50] : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.black)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
