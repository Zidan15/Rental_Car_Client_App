import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  // Placeholder for your actual Terms and Conditions text
  final String termsContent = """
## 1. Acceptance of Terms

By using the RENT.GOA Client App, you agree to these Terms and Conditions. If you do not agree, you may not use the Service.

## 2. Rental Agreement

All vehicle rentals are subject to a separate rental agreement between the Client and the Service Provider (Lessor). RENT.GOA acts only as a platform facilitator and is not a party to the rental contract.

## 3. Client Responsibilities

You are responsible for:
a. Providing accurate and valid identification (including driver's license).
b. Returning the vehicle on time and in the condition it was received, subject to normal wear and tear.
c. Adhering to all local traffic laws in Goa.

## 4. Payment and Fees

All fees are displayed at the time of booking. Cancellation fees, late return fees, and damage assessment fees may apply as detailed in the separate Rental Agreement.

## 5. Limitation of Liability

RENT.GOA is not liable for any direct, indirect, incidental, special, or consequential damages resulting from the use or inability to use the Service or any vehicle rented through the Service.

## 6. Governing Law

These Terms are governed by the laws of India, specifically the jurisdiction of the courts in Goa.

... [INSERT YOUR FULL LEGAL TEXT HERE] ...
""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
        backgroundColor: Colors.black, // Consistent header styling
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the terms using a simple text style.
            // Note: If you want to render the Markdown (#, ##), you need the flutter_markdown package.
            // For now, it's displayed as plain text.
            Text(
              termsContent,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}