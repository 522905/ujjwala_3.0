import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/application_provider.dart';
import '../../core/utils/validators.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/services/tus_upload_service.dart';
import '../../data/services/compression_service.dart';
import 'step3_current_address_screen.dart';

/// Step 2: Bank Details
///
/// Collects:
/// - Bank Account Name
/// - Bank Name
/// - Branch
/// - IFSC Code
/// - Account Number

class Step2BankDetailsScreen extends StatefulWidget {
  const Step2BankDetailsScreen({super.key});

  @override
  State<Step2BankDetailsScreen> createState() => _Step2BankDetailsScreenState();
}

class _Step2BankDetailsScreenState extends State<Step2BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _addressController = TextEditingController(); // For branch address

  // IFSC Lookup state
  bool _isIfscValid = false;
  bool _isFetchingIfsc = false;
  String? _ifscErrorMessage;

  // Passbook upload state
  File? _passbookFile;
  String? _passbookUrl;
  bool _isUploadingPassbook = false;

  final _imagePicker = ImagePicker();
  final _documentRepo = DocumentRepository(
    TusUploadService(),
    CompressionService(),
  );

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _ifscController.addListener(_onIfscChanged);
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app != null) {
      _accountNameController.text = app.bankAccountName ?? '';
      _bankNameController.text = app.bankName ?? '';
      _branchController.text = app.bankBranch ?? '';
      _ifscController.text = app.bankIfsc ?? '';
      _accountNumberController.text = app.bankAccountNumber ?? '';

      // Load passbook URL from documents
      final documents = appProvider.documents;
      try {
        final passbookDoc = documents.firstWhere(
          (d) => d.docType == DocumentType.bankProof.value,
        );
        _passbookUrl = passbookDoc.tusUrl;
      } catch (e) {
        // Document not found
      }

      // If IFSC already exists and bank name is filled, mark as valid
      if (app.bankIfsc != null &&
          app.bankIfsc!.length == 11 &&
          app.bankName != null &&
          app.bankName!.isNotEmpty) {
        setState(() {
          _isIfscValid = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _ifscController.removeListener(_onIfscChanged);
    _accountNameController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ifscController.dispose();
    _accountNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Listen to IFSC changes and auto-fetch bank details when 11 characters entered
  void _onIfscChanged() {
    final ifsc = _ifscController.text.trim().toUpperCase();
    if (ifsc.length == 11 && !_isFetchingIfsc) {
      _fetchBankDetailsFromIfsc(ifsc);
    } else if (ifsc.length != 11) {
      setState(() {
        _isIfscValid = false;
        _ifscErrorMessage = null;
      });
    }
  }

  /// Fetch bank details from Razorpay IFSC API
  Future<void> _fetchBankDetailsFromIfsc(String ifsc) async {
    setState(() {
      _isFetchingIfsc = true;
      _ifscErrorMessage = null;
      _isIfscValid = false;
    });

    try {
      final response = await http.get(
        Uri.parse('https://ifsc.razorpay.com/$ifsc'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _bankNameController.text = data['BANK'] ?? '';
          _branchController.text = data['BRANCH'] ?? '';
          _addressController.text = data['ADDRESS'] ?? '';
          _isIfscValid = true;
          _isFetchingIfsc = false;
        });

        // Save to provider
        _saveField('bank_name', _bankNameController.text);
        _saveField('bank_branch', _branchController.text);

        _showSuccess('Bank details fetched successfully!');
      } else if (response.statusCode == 404) {
        setState(() {
          _ifscErrorMessage = 'Invalid IFSC code. Please check and try again.';
          _isFetchingIfsc = false;
        });
      } else {
        throw Exception('Failed to fetch IFSC details');
      }
    } catch (e) {
      setState(() {
        _ifscErrorMessage = 'Could not fetch bank details. Please enter manually.';
        _isFetchingIfsc = false;
      });
    }
  }

  /// Upload passbook/cancelled cheque image
  Future<void> _pickPassbookImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _passbookFile = File(pickedFile.path);
        });

        // Auto-upload to server
        await _uploadPassbookToServer();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Upload passbook to TUS server
  Future<void> _uploadPassbookToServer() async {
    if (_passbookFile == null) return;

    setState(() {
      _isUploadingPassbook = true;
    });

    try {
      // Upload to TUS
      final url = await _documentRepo.uploadDocument(_passbookFile!);

      setState(() {
        _passbookUrl = url;
        _isUploadingPassbook = false;
      });

      // Save to provider
      _saveField('bank_passbook_url', url);

      _showSuccess('Passbook uploaded successfully!');
    } catch (e) {
      setState(() {
        _isUploadingPassbook = false;
      });
      _showError('Failed to upload passbook: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveField(String field, String value) {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    appProvider.updateBankField(field, value);
  }

  void _proceedToNextStep() {
    if (!_formKey.currentState!.validate()) return;

    // Validate IFSC
    if (!_isIfscValid) {
      _showError('Please enter a valid IFSC code');
      return;
    }

    // Validate passbook upload
    if (_passbookUrl == null && _passbookFile == null) {
      _showError('Please upload bank passbook or cancelled cheque');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step3CurrentAddressScreen(),
      ),
    );
  }

  Widget _buildPassbookUploadCard() {
    final hasImage = _passbookFile != null || _passbookUrl != null;

    return Container(
      decoration: BoxDecoration(
        color: hasImage ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasImage ? Colors.green.shade300 : Colors.grey.shade400,
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (_passbookFile != null) ...[
            // Show uploaded image preview
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                _passbookFile!,
                height: 200.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 12.h),
            if (_isUploadingPassbook)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 8.h),
                  Text(
                    'Uploading passbook...',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            else if (_passbookUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Passbook uploaded successfully!',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPassbookImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPassbookImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Change Photo'),
            ),
          ] else if (_passbookUrl != null) ...[
            // Already uploaded (from saved data)
            Icon(Icons.description, size: 64.sp, color: Colors.green[700]),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Passbook uploaded',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPassbookImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPassbookImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Change Photo'),
            ),
          ] else ...[
            // No image - show upload options
            Icon(Icons.description_outlined, size: 64.sp, color: Colors.grey[600]),
            SizedBox(height: 12.h),
            Text(
              'Upload Bank Passbook or Cancelled Cheque',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Clear photo showing Account Number, IFSC, and Account Holder Name',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickPassbookImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPassbookImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[700]!),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2: Bank Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 2 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Account Details',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Step 2 of 7',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'For DBTL (Direct Benefit Transfer) of LPG subsidy',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // IFSC Code (First - to auto-fill bank details)
                      Text(
                        'IFSC Code *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _ifscController,
                        decoration: InputDecoration(
                          hintText: 'e.g., SBIN0001234',
                          prefixIcon: const Icon(Icons.pin),
                          suffixIcon: _isFetchingIfsc
                              ? Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _isIfscValid
                                  ? Icon(Icons.check_circle, color: Colors.green[700])
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: _isIfscValid
                                  ? Colors.green
                                  : _ifscErrorMessage != null
                                      ? Colors.red
                                      : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: _isIfscValid
                                  ? Colors.green
                                  : _ifscErrorMessage != null
                                      ? Colors.red
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 11,
                        onChanged: (value) {
                          _saveField('bank_ifsc', value.toUpperCase());
                          _ifscController.value = _ifscController.value.copyWith(
                            text: value.toUpperCase(),
                            selection: TextSelection.collapsed(offset: value.length),
                          );
                        },
                        validator: Validators.validateIfsc,
                      ),
                      if (_ifscErrorMessage != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _ifscErrorMessage!,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.red[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_isIfscValid) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'IFSC verified! Bank details fetched automatically.',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),

                      // Bank Name (Auto-filled from IFSC)
                      Text(
                        'Bank Name *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          hintText: 'Will auto-fill from IFSC',
                          prefixIcon: const Icon(Icons.account_balance),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: _isIfscValid,
                          fillColor: _isIfscValid ? Colors.green[50] : null,
                        ),
                        readOnly: _isIfscValid,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_name', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter bank name or verify IFSC';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Branch Name (Auto-filled from IFSC)
                      Text(
                        'Branch Name *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _branchController,
                        decoration: InputDecoration(
                          hintText: 'Will auto-fill from IFSC',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: _isIfscValid,
                          fillColor: _isIfscValid ? Colors.green[50] : null,
                        ),
                        readOnly: _isIfscValid,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_branch', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter branch name or verify IFSC';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Account Holder Name
                      Text(
                        'Account Holder Name *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _accountNameController,
                        decoration: InputDecoration(
                          hintText: 'As per bank records',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_account_name', value),
                        validator: (value) => Validators.validateName(value, 'Account holder name'),
                      ),
                      SizedBox(height: 16.h),

                      // Account Number (Enabled only after IFSC validation)
                      Text(
                        'Account Number *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          hintText: _isIfscValid ? 'Enter account number' : 'Verify IFSC first',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: _isIfscValid,
                        onChanged: (value) => _saveField('bank_account_number', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account number';
                          }
                          if (value.trim().length < 9 || value.trim().length > 18) {
                            return 'Account number must be 9-18 digits';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Passbook/Cancelled Cheque Upload
                      Text(
                        'Bank Passbook / Cancelled Cheque *',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _buildPassbookUploadCard(),
                      SizedBox(height: 32.h),

                      // Navigation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[700],
                                side: BorderSide(color: Colors.blue[700]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: const Text('Back'),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _proceedToNextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: const Text('Next: Current Address'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
