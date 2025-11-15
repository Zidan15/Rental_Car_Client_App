import 'package:flutter/material.dart';
import 'package:client_app/screens/search_input_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchInputScreen()),
                  (route) => false,
                ),
                child: const Text('Back to Home'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
