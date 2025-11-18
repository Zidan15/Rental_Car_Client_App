import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Placeholder for your actual Privacy Policy text
  final String policyContent = """
## 1. Information We Collect

We collect information to provide better services to all our users. This includes:
a. **Personal Information:** Name, email address, phone number, and driver's license details (for verification).
b. **Transaction Data:** Booking history, payment details (processed by a third party), and rental duration.
c. **Location Data:** We access location data with your permission for pickup/drop-off services and tracking during the rental period.

## 2. How We Use Your Information

We use the data collected for the following purposes:
a. To process your bookings and payments.
b. To verify your identity and eligibility to rent a vehicle.
c. To improve our services and app functionality.
d. To communicate with you regarding your bookings or security updates.

## 3. Data Sharing

We only share your information with third parties necessary to operate the service, including:
a. **Service Providers:** The Lessor (car owner) receives your contact and verification details to finalize the rental.
b. **Payment Processors:** Secure third-party vendors handle payment information.

## 4. Data Security

We implement security measures to protect your data. However, no internet transmission is 100% secure, and we cannot guarantee absolute security.

## 5. Your Rights

You have the right to access, correct, or delete your personal data, subject to legal and contractual limitations.

... [INSERT YOUR FULL LEGAL TEXT HERE] ...
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: Colors.black, // Consistent header styling
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the policy using a simple text style.
            Text(
              policyContent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}