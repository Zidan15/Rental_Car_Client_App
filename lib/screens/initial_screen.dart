import 'package:flutter/material.dart';
import 'package:client_app/screens/login_screen.dart';
import 'package:client_app/screens/signup_screen.dart';

class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text('RENT.GOA', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Log In'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                child: const Text('Sign Up'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
