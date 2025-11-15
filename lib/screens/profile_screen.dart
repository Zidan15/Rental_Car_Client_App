import 'package:flutter/material.dart';
import 'package:client_app/models/user_model.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/screens/initial_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _userService = UserService();
  
  UserModel? _user;
  DateTime? _selectedDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      setState(() {
        _user = user;
        _nameController.text = user.fullName;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber;
        _addressController.text = user.address;
        _selectedDate = user.dateOfBirth;
        _dobController.text = DateFormat('dd/MM/yyyy').format(user.dateOfBirth);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _user == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedUser = _user!.copyWith(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _selectedDate,
      );

      await _userService.updateUser(updatedUser);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Changes'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Logout'),
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
