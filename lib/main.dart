import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/theme.dart';
import 'package:client_app/screens/initial_screen.dart';
import 'package:client_app/screens/search_input_screen.dart';
import 'package:client_app/services/user_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:client_app/utils/maps_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize Google Maps (Web only)
  await loadGoogleMaps();

  await Supabase.initialize(
    url: 'https://ojmzdmtpxdoaisvtefln.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qbXpkbXRweGRvYWlzdnRlZmxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTg1NTQsImV4cCI6MjA3ODU5NDU1NH0.YPU2PxWMo_9gPKuH23WaO1RVjMsQZLi8By00b4iA3rM',
  );

  runApp(const RentGoaApp());
}

class RentGoaApp extends StatelessWidget {
  const RentGoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RENT.GOA',
      debugShowCheckedModeBanner: false,
      // Assuming AppTheme.lightTheme is correctly defined
      theme: AppTheme.lightTheme, 
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  Future<void> _navigateUser() async {
    try {
      // 🎯 CRITICAL CHANGE: Use getLoginState() to check the persistent flag.
      // This is the auto-login check we are implementing.
      final bool isLoggedIn = await _userService.getLoginState() 
          .timeout(const Duration(seconds: 5), onTimeout: () => false);

      // Slight splash delay for UX
      await Future.delayed(const Duration(milliseconds: 400));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const SearchInputScreen()
              : const InitialScreen(),
        ),
      );
    } catch (e) {
      // If something crashes, show a readable error screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ErrorScreen(message: e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Text(
          'Error:\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}