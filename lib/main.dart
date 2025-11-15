import 'package:flutter/material.dart';
import 'package:client_app/theme.dart';
import 'package:client_app/screens/initial_screen.dart';
import 'package:client_app/screens/search_input_screen.dart';
import 'package:client_app/services/user_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RentGoaApp());
}

class RentGoaApp extends StatelessWidget {
  const RentGoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RENT.GOA',
      debugShowCheckedModeBanner: false,
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
      // Add timeout safety to prevent infinite wait on web
      final bool isLoggedIn = await _userService.isLoggedIn()
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
