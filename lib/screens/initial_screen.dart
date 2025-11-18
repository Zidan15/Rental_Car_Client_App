import 'package:flutter/material.dart';
import 'package:client_app/screens/signup_screen.dart';
import 'package:client_app/services/user_service.dart'; // Import service for login logic
import 'package:client_app/screens/search_input_screen.dart'; // Import screen for successful navigation

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  // --- LOGIN LOGIC AND STATE (Moved from login_screen.dart) ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate the form before attempting login
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Call the login service
      await _userService.login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;

      // Navigate to the main screen on success
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SearchInputScreen()),
        (route) => false, // Remove all previous routes from the stack
      );
    } catch (e) {
      if (!mounted) return;
      // Show error message on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --------------------------------------------------------------------

  void _handleSignUp() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  void _handleForgotPassword() {
    // Implement navigation or dialog for forgot password
    print('Forgot Password pressed');
  }

  @override
  Widget build(BuildContext context) {
    // Style for the black buttons
    final blackButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Form(
            key: _formKey, // Attach the form key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                
                // 🖼️ LOGO SECTION (Replaces the "RENT.GOA" Text and "Client App" Tagline)
                const SizedBox(height: 50),
                Image.asset(
                  'assets/images/Image 06-11-25 at 11.10 PM.jpg', // <-- CONFIRM THIS PATH AND FILE NAME
                  height: 120, // Adjust the size as needed for your logo
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 70), 
                // --------------------------------------------------------------------

                // --- Email Field ---
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty ?? true ? 'Email is required' : null, // Add validation
                ),

                const SizedBox(height: 16),

                // --- Password Field ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Password is required' : null, // Add validation
                ),

                const SizedBox(height: 8),

                // --- Forgot Password Link ---
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: const Text('Forgot Password?', style: TextStyle(color: Colors.black54)),
                  ),
                ),

                const SizedBox(height: 24),

                // --- LOGIN Button ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: blackButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('LOGIN'),
                ),

                const SizedBox(height: 16),

                // --- OR Separator ---
                const Text('OR', style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 16),

                // --- SIGN UP Button ---
                ElevatedButton(
                  onPressed: _handleSignUp,
                  style: blackButtonStyle,
                  child: const Text('SIGN UP'),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}