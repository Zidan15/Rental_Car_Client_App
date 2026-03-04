import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:client_app/models/license_model.dart';
import 'package:client_app/services/license_service.dart';
import 'package:client_app/services/user_service.dart';
import 'package:client_app/services/ocr_service.dart';
import 'package:client_app/services/dl_parser.dart';

class LicenseVerificationScreen extends StatefulWidget {
  const LicenseVerificationScreen({super.key});

  @override
  State<LicenseVerificationScreen> createState() => _LicenseVerificationScreenState();
}

class _LicenseVerificationScreenState extends State<LicenseVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseService = LicenseService();
  final _userService = UserService();
  final _ocrService = OCRService();
  
  // Text controllers
  final _dlNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  final _validTillController = TextEditingController();
  final _issueDateController = TextEditingController();

  // State
  File? _frontPhoto;
  File? _backPhoto;
  LicenseModel? _existingLicense;
  bool _isLoading = true;
  bool _isProcessingFront = false;
  bool _isProcessingBack = false;
  bool _isSubmitting = false;
  String? _processingError;
  List<String> _vehicleClasses = [];
  
  // OCR Feedback (persistent UI)
  bool _isDLDetected = false;  // Only true if valid DL scanned
  String? _ocrFeedbackMessage;
  List<String> _ocrMissingFields = [];
  String? _ocrFeedbackType; // 'success', 'warning', 'error'

  // [TEST MODE] Enrollment tab state
  File? _enrollPhoto;
  bool _isEnrolling = false;
  bool _isEnrollProcessing = false;
  String? _enrollDLNumber;
  String? _enrollHolderName;
  String? _enrollDOB;
  String? _enrollFeedback;
  bool _enrollSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadExistingLicense();
  }

  @override
  void dispose() {
    _dlNumberController.dispose();
    _holderNameController.dispose();
    _fatherNameController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _validTillController.dispose();
    _issueDateController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLicense() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      final license = await _licenseService.getUserLicense(user.id);
      if (license != null) {
        setState(() {
          _existingLicense = license;
          _dlNumberController.text = license.licenseNumber;
          _holderNameController.text = license.holderName ?? '';
          _fatherNameController.text = license.fatherName ?? '';
          _dobController.text = license.dateOfBirth != null 
              ? '${license.dateOfBirth!.day.toString().padLeft(2, '0')}/${license.dateOfBirth!.month.toString().padLeft(2, '0')}/${license.dateOfBirth!.year}'
              : '';
          _bloodGroupController.text = license.bloodGroup ?? '';
          _addressController.text = license.address ?? '';
          _validTillController.text = license.validTill != null 
              ? '${license.validTill!.day.toString().padLeft(2, '0')}/${license.validTill!.month.toString().padLeft(2, '0')}/${license.validTill!.year}'
              : '';
          _issueDateController.text = license.issueDate != null 
              ? '${license.issueDate!.day.toString().padLeft(2, '0')}/${license.issueDate!.month.toString().padLeft(2, '0')}/${license.issueDate!.year}'
              : '';
          _vehicleClasses = license.vehicleClasses ?? [];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _captureFrontPhoto() async {
    if (kIsWeb) {
      _showWebWarning();
      return;
    }

    setState(() {
      _isProcessingFront = true;
      _processingError = null;
    });

    try {
      // Show option to use camera or gallery
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() => _isProcessingFront = false);
        return;
      }

      File? photo;
      if (source == ImageSourceOption.camera) {
        photo = await _ocrService.capturePhoto();
      } else {
        photo = await _ocrService.pickFromGallery();
      }

      if (photo == null) {
        setState(() => _isProcessingFront = false);
        return;
      }

      // Check image quality with detailed feedback
      final qualityResult = _ocrService.checkImageQuality(photo);
      
      if (!qualityResult.isAcceptable) {
        // Show error with suggestion
        setState(() {
          _processingError = '${qualityResult.issue}\n${qualityResult.suggestion ?? ''}';
          _isProcessingFront = false;
        });
        _showQualityDialog(qualityResult);
        return;
      }
      
      // Show warning but continue if acceptable
      if (qualityResult.warning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${qualityResult.warning}\n${qualityResult.suggestion ?? ''}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() => _frontPhoto = photo);

      // Process with OCR (Cloud AI)
      final ocrResult = await _ocrService.processLicenseImage(photo);

      // If Cloud AI is unavailable, show dialog to retry/use offline
      if (ocrResult.cloudUnavailable && mounted) {
        setState(() => _isProcessingFront = false);
        _showCloudUnavailableDialog(photo, ocrResult.error);
        return;
      }

      _handleOCRResult(ocrResult);
    } catch (e) {
      setState(() => _processingError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingFront = false);
    }
  }

  /// Handle OCR result from either Cloud AI or ML Kit
  void _handleOCRResult(OCRResult ocrResult) {
    // Always try to populate fields if parseResult is available
    if (ocrResult.parseResult != null) {
      _populateFieldsFromOCR(ocrResult.parseResult!);
    }

    // Use enhanced feedback - PERSISTENT UI instead of SnackBars
    final feedback = _ocrService.analyzeOCRQuality(ocrResult);

    if (mounted) {
      setState(() {
        // Check if this looks like a DL (has DL number or vehicle classes)
        _isDLDetected = ocrResult.parseResult?.dlNumber != null ||
            (ocrResult.parseResult?.vehicleClasses.isNotEmpty ?? false);

        if (feedback.quality == OCRQuality.good) {
          _ocrFeedbackType = 'success';
          _ocrFeedbackMessage = feedback.message;
          _ocrMissingFields = [];
        } else if (feedback.quality == OCRQuality.partial) {
          _ocrFeedbackType = 'warning';
          _ocrFeedbackMessage = feedback.message;
          _ocrMissingFields = feedback.missingFields;
        } else {
          _ocrFeedbackType = 'error';
          _ocrFeedbackMessage = feedback.message;
          _ocrMissingFields = feedback.missingFields;
          _processingError = '${feedback.message}\n• ${feedback.suggestions.join('\n• ')}';
        }

        // If not a DL, show specific error
        if (!_isDLDetected) {
          _ocrFeedbackType = 'error';
          _ocrFeedbackMessage = 'This does not appear to be a Driving License. Please scan a valid Indian DL.';
          _ocrMissingFields = ['DL Number'];
        }
      });
    }
  }

  /// Show dialog when Cloud AI is unavailable
  void _showCloudUnavailableDialog(File photo, [String? errorMessage]) {
    final isQuotaError = errorMessage?.contains('quota') == true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isQuotaError ? Icons.timer_off : Icons.cloud_off,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(isQuotaError ? 'API Quota Reached' : 'Cloud AI Unavailable'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage ?? 'An internet connection is needed for accurate license scanning.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (!isQuotaError) const Text('• Connect to WiFi/data and retry'),
            if (isQuotaError) const Text('• Wait and try again later'),
            const Text('• Use offline mode (less accurate)'),
            const Text('• Enter details manually'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // User will enter manually
            },
            child: const Text('Enter Manually'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessingFront = true);
              try {
                final offlineResult =
                    await _ocrService.processLicenseImageOffline(photo);
                _handleOCRResult(offlineResult);
              } finally {
                if (mounted) setState(() => _isProcessingFront = false);
              }
            },
            child: const Text('Use Offline'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessingFront = true);
              try {
                final retryResult =
                    await _ocrService.processLicenseImage(photo);
                if (retryResult.cloudUnavailable && mounted) {
                  setState(() => _isProcessingFront = false);
                  _showCloudUnavailableDialog(photo, retryResult.error);
                  return;
                }
                _handleOCRResult(retryResult);
              } finally {
                if (mounted) setState(() => _isProcessingFront = false);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  void _showQualityDialog(ImageQualityResult qualityResult) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              qualityResult.issueType == ImageQualityIssue.blurry 
                  ? Icons.blur_on 
                  : qualityResult.issueType == ImageQualityIssue.poorLighting
                      ? Icons.wb_sunny
                      : Icons.error_outline,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Photo Quality Issue')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(qualityResult.issue ?? 'Image quality is not acceptable'),
            const SizedBox(height: 12),
            if (qualityResult.suggestion != null) ...[
              const Text('Suggestion:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(qualityResult.suggestion!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Enter Manually'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _captureFrontPhoto();
            },
            child: const Text('Retake Photo'),
          ),
        ],
      ),
    );
  }

  Future<void> _captureBackPhoto() async {
    if (kIsWeb) {
      _showWebWarning();
      return;
    }

    setState(() {
      _isProcessingBack = true;
      _processingError = null;
    });

    try {
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() => _isProcessingBack = false);
        return;
      }

      File? photo;
      if (source == ImageSourceOption.camera) {
        photo = await _ocrService.capturePhoto();
      } else {
        photo = await _ocrService.pickFromGallery();
      }

      if (photo == null) {
        setState(() => _isProcessingBack = false);
        return;
      }

      setState(() => _backPhoto = photo);

      // Process back photo for additional info (issue dates, etc.)
      final ocrResult = await _ocrService.processLicenseImage(photo);
      
      if (ocrResult.success && ocrResult.parseResult != null) {
        // Only fill in fields that are still empty
        final result = ocrResult.parseResult!;
        if (_issueDateController.text.isEmpty && result.issueDate != null) {
          _issueDateController.text = result.issueDate!;
        }
        if (_vehicleClasses.isEmpty && result.vehicleClasses.isNotEmpty) {
          setState(() => _vehicleClasses = result.vehicleClasses);
        }
      }
    } catch (e) {
      setState(() => _processingError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingBack = false);
    }
  }

  void _populateFieldsFromOCR(DLParseResult result) {
    setState(() {
      if (result.dlNumber != null) _dlNumberController.text = result.dlNumber!;
      if (result.holderName != null) _holderNameController.text = result.holderName!;
      if (result.fatherName != null) _fatherNameController.text = result.fatherName!;
      if (result.dateOfBirth != null) _dobController.text = result.dateOfBirth!;
      if (result.bloodGroup != null) _bloodGroupController.text = result.bloodGroup!;
      if (result.address != null) _addressController.text = result.address!;
      if (result.validTill != null) _validTillController.text = result.validTill!;
      if (result.issueDate != null) _issueDateController.text = result.issueDate!;
      if (result.vehicleClasses.isNotEmpty) _vehicleClasses = result.vehicleClasses;
    });
  }

  Future<ImageSourceOption?> _showImageSourceDialog() async {
    return showDialog<ImageSourceOption>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSourceOption.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSourceOption.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showWebWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OCR requires a mobile device. Please use the Android/iOS app.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? _convertDateToISO(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Try to parse DD/MM/YYYY or DD-MM-YYYY
    final parts = dateStr.split(RegExp(r'[/\-\.]'));
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
    return null;
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
      // Upload images to Supabase Storage
      String? frontPhotoUrl;
      String? backPhotoUrl;

      if (_frontPhoto != null) {
        frontPhotoUrl = await _licenseService.uploadLicenseImage(_frontPhoto!, user.id, 'front');
      }
      if (_backPhoto != null) {
        backPhotoUrl = await _licenseService.uploadLicenseImage(_backPhoto!, user.id, 'back');
      }

      // Submit license data
      await _licenseService.submitLicense(
        userId: user.id,
        licenseNumber: _dlNumberController.text.trim(),
        frontPhotoUrl: frontPhotoUrl ?? _existingLicense?.frontPhotoUrl,
        backPhotoUrl: backPhotoUrl ?? _existingLicense?.backPhotoUrl,
        holderName: _holderNameController.text.trim().isNotEmpty ? _holderNameController.text.trim() : null,
        fatherName: _fatherNameController.text.trim().isNotEmpty ? _fatherNameController.text.trim() : null,
        dateOfBirth: _convertDateToISO(_dobController.text.trim()),
        bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        validTill: _convertDateToISO(_validTillController.text.trim()),
        vehicleClasses: _vehicleClasses.isNotEmpty ? _vehicleClasses : null,
        issueDate: _convertDateToISO(_issueDateController.text.trim()),
      );

      // Try to verify against database
      final verificationResult = await _licenseService.verifyAgainstDatabase(_dlNumberController.text.trim());
      
      if (verificationResult.isVerified) {
        await _licenseService.updateVerificationStatus(user.id, 'verified');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ ${verificationResult.message}'), backgroundColor: Colors.green),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verificationResult.message)),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ===== [TEST MODE] Enrollment Logic =====
  Future<void> _captureEnrollPhoto() async {
    if (kIsWeb) {
      _showWebWarning();
      return;
    }

    setState(() {
      _isEnrollProcessing = true;
      _enrollFeedback = null;
      _enrollSuccess = false;
    });

    try {
      final source = await _showImageSourceDialog();
      if (source == null) {
        setState(() => _isEnrollProcessing = false);
        return;
      }

      File? photo;
      if (source == ImageSourceOption.camera) {
        photo = await _ocrService.capturePhoto();
      } else {
        photo = await _ocrService.pickFromGallery();
      }

      if (photo == null) {
        setState(() => _isEnrollProcessing = false);
        return;
      }

      setState(() => _enrollPhoto = photo);

      // Run OCR
      final ocrResult = await _ocrService.processLicenseImage(photo);

      if (ocrResult.cloudUnavailable) {
        // Try offline
        final offlineResult = await _ocrService.processLicenseImageOffline(photo);
        if (offlineResult.success && offlineResult.parseResult?.dlNumber != null) {
          setState(() {
            _enrollDLNumber = offlineResult.parseResult!.dlNumber;
            _enrollHolderName = offlineResult.parseResult!.holderName;
            _enrollDOB = offlineResult.parseResult!.dateOfBirth;
            _enrollFeedback = 'DL Number detected: $_enrollDLNumber (offline mode)';
          });
        } else {
          setState(() => _enrollFeedback = '❌ Could not detect DL number. Try again.');
        }
      } else if (ocrResult.success && ocrResult.parseResult?.dlNumber != null) {
        setState(() {
          _enrollDLNumber = ocrResult.parseResult!.dlNumber;
          _enrollHolderName = ocrResult.parseResult!.holderName;
          _enrollDOB = ocrResult.parseResult!.dateOfBirth;
          _enrollFeedback = 'DL Number detected: $_enrollDLNumber';
        });
      } else {
        setState(() => _enrollFeedback = '❌ Could not detect DL number. Try again.');
      }
    } catch (e) {
      setState(() => _enrollFeedback = '❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isEnrollProcessing = false);
    }
  }

  Future<void> _enrollLicense() async {
    if (_enrollDLNumber == null) return;
    setState(() => _isEnrolling = true);

    try {
      await _licenseService.enrollLicenseInDatabase(
        dlNumber: _enrollDLNumber!,
        holderName: _enrollHolderName,
        dateOfBirth: _enrollDOB,
      );

      setState(() {
        _enrollFeedback = '✅ License "$_enrollDLNumber" enrolled in test database!';
        _enrollSuccess = true;
      });
    } catch (e) {
      setState(() => _enrollFeedback = '❌ Failed to enroll: $e');
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('License Verification'),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Verify License'),
              Tab(text: 'Enroll [TEST]'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVerifyTab(),
            _buildEnrollTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Existing license status
              if (_existingLicense != null) ...[
                _buildStatusCard(),
                const SizedBox(height: 24),
              ],

              // Web warning
              if (kIsWeb) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'OCR verification requires a mobile device. Use the Android/iOS app for best experience.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Front Photo Section
              const Text('Step 1: Capture License Front', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoCapture(
                photo: _frontPhoto,
                isProcessing: _isProcessingFront,
                onCapture: _captureFrontPhoto,
                label: 'Front of License',
              ),
              const SizedBox(height: 24),

              // Back Photo Section
              const Text('Step 2: Capture License Back (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPhotoCapture(
                photo: _backPhoto,
                isProcessing: _isProcessingBack,
                onCapture: _captureBackPhoto,
                label: 'Back of License',
              ),
              const SizedBox(height: 24),

              // ===== OCR FEEDBACK CARD (Persistent) =====
              if (_ocrFeedbackMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _ocrFeedbackType == 'success' 
                        ? Colors.green[50] 
                        : _ocrFeedbackType == 'warning' 
                            ? Colors.orange[50] 
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _ocrFeedbackType == 'success' 
                          ? Colors.green[300]! 
                          : _ocrFeedbackType == 'warning' 
                              ? Colors.orange[300]! 
                              : Colors.red[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _ocrFeedbackType == 'success' 
                                ? Icons.check_circle 
                                : _ocrFeedbackType == 'warning' 
                                    ? Icons.warning_amber_rounded 
                                    : Icons.error_outline,
                            color: _ocrFeedbackType == 'success' 
                                ? Colors.green 
                                : _ocrFeedbackType == 'warning' 
                                    ? Colors.orange 
                                    : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ocrFeedbackMessage!,
                              style: TextStyle(
                                color: _ocrFeedbackType == 'success' 
                                    ? Colors.green[800] 
                                    : _ocrFeedbackType == 'warning' 
                                        ? Colors.orange[800] 
                                        : Colors.red[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_ocrMissingFields.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Missing: ${_ocrMissingFields.join(', ')}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (!_isDLDetected && _ocrFeedbackType == 'error') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Text fields are locked. Please scan a valid Driving License.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Processing error (separate)
              if (_processingError != null && _ocrFeedbackMessage == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_processingError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Extracted/Manual Fields
              const Text('Step 3: Verify Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _isDLDetected 
                    ? 'Fields auto-filled from OCR. Edit if needed.' 
                    : 'Scan a valid Driving License to fill these fields.',
                style: TextStyle(color: _isDLDetected ? Colors.grey : Colors.red[400], fontSize: 13),
              ),
              const SizedBox(height: 16),

              // DL Number (Required)
              TextFormField(
                controller: _dlNumberController,
                enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                decoration: InputDecoration(
                  labelText: 'DL Number *',
                  suffixIcon: _dlNumberController.text.isNotEmpty 
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20) 
                      : null,
                ),
                validator: (v) => v?.isEmpty ?? true ? 'DL number is required' : null,
              ),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _holderNameController,
                enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                decoration: const InputDecoration(labelText: 'Name on License'),
              ),
              const SizedBox(height: 16),

              // Father's Name
              TextFormField(
                controller: _fatherNameController,
                enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                decoration: const InputDecoration(labelText: 'Father\'s Name'),
              ),
              const SizedBox(height: 16),

              // DOB and Blood Group Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dobController,
                      enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                      decoration: const InputDecoration(labelText: 'Date of Birth'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _bloodGroupController,
                      enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                      decoration: const InputDecoration(labelText: 'Blood Group'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Issue Date and Valid Till Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _issueDateController,
                      enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                      decoration: const InputDecoration(labelText: 'Issue Date'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _validTillController,
                      enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                      decoration: const InputDecoration(labelText: 'Valid Till'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                enabled: (_existingLicense != null && _frontPhoto == null) || _isDLDetected,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 2,
              ),
              const SizedBox(height: 16),

              // Vehicle Classes
              if (_vehicleClasses.isNotEmpty) ...[
                const Text('Vehicle Classes', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _vehicleClasses.map((c) => Chip(label: Text(c))).toList(),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Submit Button
              ElevatedButton(
                onPressed: (_isSubmitting || !(_isDLDetected || (_existingLicense != null && _frontPhoto == null))) 
                    ? null 
                    : _submitLicense,
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : Text(!_isDLDetected && (_existingLicense == null || _frontPhoto != null)
                        ? 'Scan Valid DL First' 
                        : 'Submit for Verification'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// [TEST MODE] Enrollment tab — scans license and inserts into valid_dl_records
  Widget _buildEnrollTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TEST MODE WARNING BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science, color: Colors.amber, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ TEST MODE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This tab populates the demo verification database. '
                          'Scan a real license here first, then verify it in the "Verify License" tab. '
                          'Not present in production.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scan Section
            const Text('Step 1: Scan License to Enroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPhotoCapture(
              photo: _enrollPhoto,
              isProcessing: _isEnrollProcessing,
              onCapture: _captureEnrollPhoto,
              label: 'Scan License for Enrollment',
            ),
            const SizedBox(height: 24),

            // Detected DL info
            if (_enrollDLNumber != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detected DL Number:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(_enrollDLNumber!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_enrollHolderName != null) ...[
                      const SizedBox(height: 8),
                      Text('Holder: $_enrollHolderName', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Feedback
            if (_enrollFeedback != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _enrollSuccess ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _enrollSuccess ? Colors.green[300]! : Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _enrollSuccess ? Icons.check_circle : Icons.info_outline,
                      color: _enrollSuccess ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _enrollFeedback!,
                        style: TextStyle(
                          color: _enrollSuccess ? Colors.green[800] : Colors.orange[800],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Enroll Button
            ElevatedButton(
              onPressed: (_enrollDLNumber == null || _isEnrolling || _enrollSuccess)
                  ? null
                  : _enrollLicense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: _enrollSuccess ? Colors.green[100] : null,
              ),
              child: _isEnrolling
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_enrollSuccess
                      ? '✅ Enrolled — Now verify in Tab 1'
                      : _enrollDLNumber == null
                          ? 'Scan a License First'
                          : 'Enroll in Test Database'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _existingLicense!.verificationStatus;
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'verified':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                const SizedBox(height: 4),
                Text(status.toUpperCase(), style: TextStyle(color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCapture({
    required File? photo,
    required bool isProcessing,
    required VoidCallback onCapture,
    required String label,
  }) {
    return GestureDetector(
      onTap: isProcessing ? null : onCapture,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(height: 12),
                    Text('Processing...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : photo != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(photo, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 16),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: ElevatedButton.icon(
                          onPressed: onCapture,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retake'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Tap to capture', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
      ),
    );
  }
}

enum ImageSourceOption { camera, gallery }
