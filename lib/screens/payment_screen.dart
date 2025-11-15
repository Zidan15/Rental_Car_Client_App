import 'package:flutter/material.dart';
import 'package:client_app/screens/booking_confirmation_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentScreen extends StatelessWidget {
  final double totalPrice;

  const PaymentScreen({super.key, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              QrImageView(
                data: 'DUMMY_PAYMENT_QR_${totalPrice.toStringAsFixed(0)}',
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text('Scan to Pay (Dummy Transaction)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text('₹${totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingConfirmationScreen()),
                ),
                child: const Text('Confirm Payment'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
