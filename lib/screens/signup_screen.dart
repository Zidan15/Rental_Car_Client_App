import 'package:flutter/material.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/screens/search_input_screen.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dobController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date of birth')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userService.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _phoneController.text.trim(),
        _addressController.text.trim(),
        _selectedDate!,
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SearchInputScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v?.isEmpty ?? true ? 'Email is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty ?? true ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                  validator: (v) => v?.isEmpty ?? true ? 'Address is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  decoration: const InputDecoration(labelText: 'Date of Birth', suffixIcon: Icon(Icons.calendar_today, color: Colors.black)),
                  readOnly: true,
                  onTap: _selectDate,
                  validator: (v) => v?.isEmpty ?? true ? 'Date of birth is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign Up'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
