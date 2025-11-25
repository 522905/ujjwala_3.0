import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/enums/app_enums.dart';
import '../../data/repositories/document_repository.dart';
import 'step2_bank_details_screen.dart';

/// Step 1: Aadhaar Upload & Applicant Details
///
/// New Features:
/// - Aadhaar photo upload (front + back)
/// - OCR auto-fill (30 seconds)
/// - Mobile OTP verification (agents only)
/// - Gender validation (Female only)
/// - Age validation (≥18 years)

class Step1ApplicantDetailsScreen extends StatefulWidget {
  const Step1ApplicantDetailsScreen({super.key});

  @override
  State<Step1ApplicantDetailsScreen> createState() =>
      _Step1ApplicantDetailsScreenState();
}

class _Step1ApplicantDetailsScreenState
    extends State<Step1ApplicantDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  Gender? _selectedGender;
  DateTime? _selectedDob;
  Caste? _selectedCaste;

  // Aadhaar upload state
  File? _aadhaarFrontFile;
  File? _aadhaarBackFile;
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;
  bool _isProcessingOCR = false;
  bool _ocrCompleted = false;

  // OTP state
  bool _mobileVerified = false;
  bool _otpSent = false;
  bool _showOtpField = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _checkUserRole();
  }

  void _checkUserRole() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // If customer, auto-verify mobile (no OTP needed)
    if (authProvider.isUser) {
      setState(() => _mobileVerified = true);
    }
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app != null) {
      _fullNameController.text = app.applicantFullName ?? '';
      _aadhaarController.text = app.applicantAadhaar ?? '';
      _mobileController.text = app.applicantMobile ?? '';
      _selectedGender = app.applicantGender != null
          ? Gender.fromValue(app.applicantGender!)
          : null;
      _selectedDob = app.applicantDob;
      _selectedCaste = app.caste != null
          ? Caste.fromValue(app.caste!)
          : null;

      // Load existing Aadhaar URLs from documents
      final documents = appProvider.documents;
      try {
        final frontDoc = documents.firstWhere(
          (d) => d.docType == DocumentType.aadhaarFront,
        );
        if (frontDoc.tusUrl != null) {
          _aadhaarFrontUrl = frontDoc.tusUrl;
        }
      } catch (e) {
        // Document not found
      }

      try {
        final backDoc = documents.firstWhere(
          (d) => d.docType == DocumentType.aadhaarBack,
        );
        if (backDoc.tusUrl != null) {
          _aadhaarBackUrl = backDoc.tusUrl;
        }
      } catch (e) {
        // Document not found
      }

      _ocrCompleted = _aadhaarFrontUrl != null && _aadhaarBackUrl != null;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _aadhaarController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _saveField(String field, dynamic value) {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    appProvider.updateApplicantField(field, value);
  }

  // ==================== MOBILE OTP ====================
  Future<void> _sendOTP() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || mobile.length != 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _showOtpField = true);

    try {
      // TODO: Replace with your actual OTP API endpoint
      final response = await http.post(
        Uri.parse('YOUR_API_BASE_URL/communication_log/send-otp-generic/'),
        body: {
          'mobile': mobile,
          'purpose': 'ujjwala_v3_verification',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _otpSent = true);
          _showSuccess('OTP sent to $mobile');
        } else {
          _showError(data['message'] ?? 'Failed to send OTP');
        }
      } else {
        _showError('Error sending OTP. Please try again.');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  Future<void> _verifyOTP() async {
    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    try {
      // TODO: Replace with your actual OTP verification API endpoint
      final response = await http.post(
        Uri.parse('YOUR_API_BASE_URL/communication_log/verify-otp-generic/'),
        body: {
          'mobile': mobile,
          'otp': otp,
          'purpose': 'ujjwala_v3_verification',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _mobileVerified = true);
          _saveField('applicant_mobile', mobile);
          _showSuccess('Mobile verified successfully! ✓');
        } else {
          _showError(data['message'] ?? 'Invalid OTP');
        }
      } else {
        _showError('Error verifying OTP. Please try again.');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    }
  }

  // ==================== AADHAAR UPLOAD ====================
  Future<void> _pickAadhaarImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1520,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _aadhaarFrontFile = File(image.path);
          } else {
            _aadhaarBackFile = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error picking image: ${e.toString()}');
    }
  }

  Future<void> _captureAadhaarImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1520,
      );

      if (image != null) {
        setState(() {
          if (isFront) {
            _aadhaarFrontFile = File(image.path);
          } else {
            _aadhaarBackFile = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error capturing image: ${e.toString()}');
    }
  }

  // ==================== OCR PROCESSING ====================
  Future<void> _processAadhaarOCR() async {
    if (_aadhaarFrontFile == null || _aadhaarBackFile == null) {
      _showError('Please upload both Aadhaar front and back images');
      return;
    }

    setState(() => _isProcessingOCR = true);

    try {
      // Step 1: Upload images to TUS server
      final frontUrl = await _uploadToTUS(_aadhaarFrontFile!);
      final backUrl = await _uploadToTUS(_aadhaarBackFile!);

      if (frontUrl == null || backUrl == null) {
        throw Exception('Failed to upload Aadhaar images');
      }

      setState(() {
        _aadhaarFrontUrl = frontUrl;
        _aadhaarBackUrl = backUrl;
      });

      // Step 2: Call OCR API
      // TODO: Replace with your actual OCR API endpoint
      final response = await http.post(
        Uri.parse('YOUR_API_BASE_URL/app_utilities/application-utilities/get_details_for_aadhar/'),
        body: {
          'uid_front_url': frontUrl,
          'uid_back_url': backUrl,
        },
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final ocrData = json.decode(data['data']['text']);
          _prefillFromOCR(ocrData);

          // Save Aadhaar URLs
          _saveField('uid_front_link', frontUrl);
          _saveField('uid_back_link', backUrl);

          setState(() => _ocrCompleted = true);
          _showSuccess('Aadhaar verified! Details auto-filled ✓');
        } else {
          throw Exception(data['message'] ?? 'OCR failed');
        }
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('OCR failed: ${e.toString()}');
      _showManualEntryOption();
    } finally {
      setState(() => _isProcessingOCR = false);
    }
  }

  Future<String?> _uploadToTUS(File file) async {
    try {
      // TODO: Implement TUS upload
      // For now, using DocumentRepository if available
      final docRepo = DocumentRepository();
      return await docRepo.uploadFile(file);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  void _prefillFromOCR(Map<String, dynamic> ocrData) {
    // Extract name
    if (ocrData['name'] != null && ocrData['name']['value'] != null) {
      final fullName = ocrData['name']['value'].toString().trim();
      _fullNameController.text = fullName;
      _splitAndSaveFullName();
    }

    // Extract gender
    if (ocrData['gender'] != null && ocrData['gender']['value'] != null) {
      final genderStr = ocrData['gender']['value'].toString().toUpperCase();
      setState(() {
        if (genderStr == 'MALE' || genderStr == 'M') {
          _selectedGender = Gender.male;
        } else if (genderStr == 'FEMALE' || genderStr == 'F') {
          _selectedGender = Gender.female;
        } else {
          _selectedGender = Gender.other;
        }
      });
      _saveField('applicant_gender', _selectedGender?.value);
    }

    // Extract DOB
    if (ocrData['dob'] != null && ocrData['dob']['value'] != null) {
      try {
        final dobStr = ocrData['dob']['value'].toString();
        final parts = dobStr.split('/');

        if (parts.length == 3) {
          // DD/MM/YYYY format
          final dob = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          setState(() => _selectedDob = dob);
          _saveField('applicant_dob', dob);
        } else if (parts.length == 1) {
          // Year only
          final dob = DateTime(int.parse(parts[0]), 1, 1);
          setState(() => _selectedDob = dob);
          _saveField('applicant_dob', dob);
        }
      } catch (e) {
        debugPrint('DOB parsing error: $e');
      }
    }

    // Extract Aadhaar number
    if (ocrData['aadhaar'] != null && ocrData['aadhaar']['value'] != null) {
      final aadhaar = ocrData['aadhaar']['value'].toString().replaceAll(' ', '');
      _aadhaarController.text = aadhaar;
      _saveField('applicant_aadhaar', aadhaar);
    }

    // Note: Address and pincode from Aadhaar are typically for current address, not permanent
    // Users will manually enter permanent address in Step 4
  }

  void _showManualEntryOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Failed'),
        content: const Text(
          'Unable to extract details from Aadhaar.\n\n'
          'You can:\n'
          '1. Retry with better quality images\n'
          '2. Enter details manually',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Enter Manually'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _aadhaarFrontFile = null;
                _aadhaarBackFile = null;
              });
            },
            child: const Text('Retry Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
      _saveField('applicant_dob', picked);
    }
  }

  void _splitAndSaveFullName() {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) return;

    final parts = fullName.split(' ');
    String firstName = '';
    String? middleName;
    String? lastName;

    if (parts.length == 1) {
      firstName = parts[0];
    } else if (parts.length == 2) {
      firstName = parts[0];
      lastName = parts[1];
    } else {
      firstName = parts[0];
      middleName = parts.sublist(1, parts.length - 1).join(' ');
      lastName = parts.last;
    }

    _saveField('applicant_full_name', fullName);
    _saveField('applicant_first_name', firstName);
    _saveField('applicant_middle_name', middleName);
    _saveField('applicant_last_name', lastName);
  }

  int _calculateAge() {
    if (_selectedDob == null) return 0;

    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }

  void _proceedToNextStep() {
    // Check mobile verification for agents
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAgent && !_mobileVerified) {
      _showError('Please verify your mobile number first');
      return;
    }

    // Check Aadhaar upload/OCR or manual entry
    if (!_ocrCompleted && _fullNameController.text.isEmpty) {
      _showError('Please upload Aadhaar and process OCR, or enter details manually');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Gender validation - MUST be Female
    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }

    if (_selectedGender != Gender.female) {
      _showError(
        'This scheme is exclusively for female applicants.\n'
        'केवल महिलाएं ही इस योजना के लिए आवेदन कर सकती हैं।\n'
        'ਇਹ ਯੋਜਨਾ ਸਿਰਫ਼ ਔਰਤਾਂ ਲਈ ਹੈ।'
      );
      return;
    }

    // Age validation - MUST be >= 18
    if (_selectedDob == null) {
      _showError('Please select date of birth');
      return;
    }

    final age = _calculateAge();
    if (age < 18) {
      _showError(
        'Applicant must be at least 18 years old to apply.\n'
        'आवेदक की आयु कम से कम 18 वर्ष होनी चाहिए।'
      );
      return;
    }

    if (_selectedCaste == null) {
      _showError('Please select caste');
      return;
    }

    // Save and proceed
    _splitAndSaveFullName();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step2BankDetailsScreen(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAgent = authProvider.isAgent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1: Aadhaar & Applicant'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 1 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aadhaar Upload & Applicant Details',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Step 1 of 7',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Mobile Verification Section
                    if (isAgent && !_mobileVerified) ...[
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.phone_android, color: Colors.blue[700]),
                                SizedBox(width: 8.w),
                                Text(
                                  'Mobile Verification',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            TextFormField(
                              controller: _mobileController,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                            ),
                            if (!_otpSent) ...[
                              SizedBox(height: 12.h),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _sendOTP,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send OTP'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (_showOtpField) ...[
                              SizedBox(height: 16.h),
                              TextFormField(
                                controller: _otpController,
                                decoration: InputDecoration(
                                  labelText: 'Enter OTP *',
                                  prefixIcon: const Icon(Icons.pin),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _verifyOTP,
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Verify OTP'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[700],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  ElevatedButton.icon(
                                    onPressed: _sendOTP,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Resend'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Verified Mobile Indicator
                    if (_mobileVerified) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Mobile ${_mobileController.text} verified ✓',
                                style: TextStyle(
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Aadhaar Upload Section
                    if (!_ocrCompleted) ...[
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.credit_card, color: Colors.orange[700]),
                                SizedBox(width: 8.w),
                                Text(
                                  'Upload Aadhaar Card',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Upload both sides for automatic verification',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16.h),

                            // Aadhaar Front
                            _buildAadhaarUploadCard(
                              label: 'Aadhaar Front',
                              file: _aadhaarFrontFile,
                              isFront: true,
                            ),
                            SizedBox(height: 16.h),

                            // Aadhaar Back
                            _buildAadhaarUploadCard(
                              label: 'Aadhaar Back',
                              file: _aadhaarBackFile,
                              isFront: false,
                            ),
                            SizedBox(height: 16.h),

                            // Process OCR Button
                            if (_aadhaarFrontFile != null && _aadhaarBackFile != null) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 56.h,
                                child: ElevatedButton.icon(
                                  onPressed: _isProcessingOCR ? null : _processAadhaarOCR,
                                  icon: _isProcessingOCR
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.h,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isProcessingOCR
                                        ? 'Processing OCR (30s)...'
                                        : 'Process & Auto-Fill Details',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // OCR Success Message
                    if (_ocrCompleted) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green[700]),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Aadhaar verified! Details auto-filled ✓',
                                style: TextStyle(
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],

                    // Applicant Details Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Applicant Information',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Full Name
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'First Middle Last',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onChanged: (value) => _saveField('applicant_full_name', value),
                            validator: (value) => Validators.validateName(value, 'Full name'),
                          ),
                          SizedBox(height: 16.h),

                          // Gender
                          DropdownButtonFormField<Gender>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender *',
                              prefixIcon: const Icon(Icons.wc),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            items: Gender.values.map((gender) {
                              return DropdownMenuItem(
                                value: gender,
                                child: Text(gender.display),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                              _saveField('applicant_gender', value?.value);
                            },
                            validator: (value) {
                              if (value == null) return 'Please select gender';
                              if (value != Gender.female) {
                                return 'Only Female applicants eligible';
                              }
                              return null;
                            },
                          ),
                          if (_selectedGender != null && _selectedGender != Gender.female) ...[
                            SizedBox(height: 8.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red[700]),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'This scheme is only for female applicants\nयह योजना केवल महिलाओं के लिए है',
                                      style: TextStyle(
                                        color: Colors.red[900],
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: 16.h),

                          // Date of Birth
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date of Birth *',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                _selectedDob != null
                                    ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: _selectedDob != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          if (_selectedDob != null) ...[
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text(
                                  'Age: ${_calculateAge()} years',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: _calculateAge() >= 18
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                if (_calculateAge() < 18)
                                  Icon(Icons.error, color: Colors.red[700], size: 16),
                              ],
                            ),
                            if (_calculateAge() < 18) ...[
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red[700]),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        'Applicant must be at least 18 years old\nआवेदक की आयु कम से कम 18 वर्ष होनी चाहिए',
                                        style: TextStyle(
                                          color: Colors.red[900],
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          SizedBox(height: 16.h),

                          // Aadhaar
                          TextFormField(
                            controller: _aadhaarController,
                            decoration: InputDecoration(
                              labelText: 'Aadhaar Number *',
                              prefixIcon: const Icon(Icons.credit_card),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 12,
                            onChanged: (value) => _saveField('applicant_aadhaar', value),
                            validator: Validators.validateAadhaar,
                          ),
                          SizedBox(height: 16.h),

                          // Mobile (readonly if verified)
                          TextFormField(
                            controller: _mobileController,
                            decoration: InputDecoration(
                              labelText: 'Mobile Number *',
                              prefixIcon: const Icon(Icons.phone),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            readOnly: _mobileVerified,
                            onChanged: (value) => _saveField('applicant_mobile', value),
                            validator: Validators.validateMobile,
                          ),
                          SizedBox(height: 16.h),

                          // Caste
                          DropdownButtonFormField<Caste>(
                            value: _selectedCaste,
                            decoration: InputDecoration(
                              labelText: 'Caste/Category *',
                              prefixIcon: const Icon(Icons.category),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            items: Caste.values.map((caste) {
                              return DropdownMenuItem(
                                value: caste,
                                child: Text(caste.display),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCaste = value);
                              _saveField('caste', value?.value);
                            },
                            validator: (value) =>
                                value == null ? 'Please select caste' : null,
                          ),
                          SizedBox(height: 24.h),

                          // Next Button
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton.icon(
                              onPressed: _proceedToNextStep,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Next: Bank Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAadhaarUploadCard({
    required String label,
    required File? file,
    required bool isFront,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: file != null ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (file != null)
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
            ],
          ),
          SizedBox(height: 12.h),

          if (file != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                file,
                height: 150.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12.h),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAadhaarImage(isFront),
                  icon: const Icon(Icons.photo_library),
                  label: Text(file != null ? 'Change' : 'Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _captureAadhaarImage(isFront),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
