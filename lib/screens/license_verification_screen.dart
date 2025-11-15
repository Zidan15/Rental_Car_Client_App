import 'package:flutter/material.dart';
import 'package:client_app/models/license_model.dart';
import 'package:client_app/services/license_service.dart';
import 'package:client_app/services/user_service.dart';
import 'package:file_picker/file_picker.dart';

class LicenseVerificationScreen extends StatefulWidget {
  const LicenseVerificationScreen({super.key});

  @override
  State<LicenseVerificationScreen> createState() => _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _licenseService = LicenseService();
  final _userService = UserService();
  
  String? _frontPhotoPath;
  String? _backPhotoPath;
  LicenseModel? _existingLicense;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingLicense();
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLicense() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      final license = await _licenseService.getUserLicense(user.id);
      if (license != null) {
        setState(() {
          _existingLicense = license;
          _licenseNumberController.text = license.licenseNumber;
          _frontPhotoPath = license.frontPhotoPath;
          _backPhotoPath = license.backPhotoPath;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickFrontPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _frontPhotoPath = result.files.single.name);
    }
  }

  Future<void> _pickBackPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => _backPhotoPath = result.files.single.name);
    }
  }

  Future<void> _submitLicense() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await _userService.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _licenseService.submitLicense(
        userId: user.id,
        licenseNumber: _licenseNumberController.text.trim(),
        frontPhotoPath: _frontPhotoPath,
        backPhotoPath: _backPhotoPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License submitted successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('License Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_existingLicense != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Verification Status: ${_existingLicense!.verificationStatus}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(labelText: 'License Number'),
                  validator: (v) => v?.isEmpty ?? true ? 'License number is required' : null,
                ),
                const SizedBox(height: 24),
                const Text('Upload License Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickFrontPhoto,
                  icon: const Icon(Icons.upload_file, color: Colors.black),
                  label: Text(_frontPhotoPath ?? 'Upload Front Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickBackPhoto,
                  icon: const Icon(Icons.upload_file, color: Colors.black),
                  label: Text(_backPhotoPath ?? 'Upload Back Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitLicense,
                  child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit'),
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
