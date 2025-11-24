import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/aadhaar_validator.dart';
import '../../core/utils/validators.dart';

/// Customer Signup Screen
///
/// Customer registration with Aadhaar verification

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  bool? _aadhaarValidationState;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _aadhaarController.addListener(_validateAadhaar);
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _mobileController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _validateAadhaar() {
    final validation = AadhaarValidator.getValidationState(
      _aadhaarController.text.trim(),
    );
    setState(() => _aadhaarValidationState = validation);
  }

  Widget? _buildAadhaarValidationIcon() {
    if (_aadhaarValidationState == null) return null;

    return Icon(
      _aadhaarValidationState! ? Icons.check_circle : Icons.warning,
      color: _aadhaarValidationState! ? Colors.green : Colors.orange,
      size: 20.sp,
    );
  }

  Color _getAadhaarBorderColor() {
    if (_aadhaarValidationState == null) return Colors.grey[300]!;
    return _aadhaarValidationState! ? Colors.green : Colors.orange;
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Implement customer signup API call
    // For now, just show a success message
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30.sp),
            SizedBox(width: 12.w),
            const Text('Registration Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your registration has been submitted successfully!',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'You can now login with your Aadhaar number.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to splash
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Signup'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_add,
                  size: 80.sp,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 16.h),

                Text(
                  'Register as Customer',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),

                Text(
                  'Create your account to get started',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 32.h),

                // Aadhaar Number with validation
                TextFormField(
                  controller: _aadhaarController,
                  decoration: InputDecoration(
                    labelText: 'Aadhaar Number',
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: _buildAadhaarValidationIcon(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _getAadhaarBorderColor()),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _getAadhaarBorderColor()),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: Validators.validateAadhaar,
                ),
                SizedBox(height: 16.h),

                // Mobile Number
                TextFormField(
                  controller: _mobileController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: Validators.validateMobile,
                ),
                SizedBox(height: 16.h),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) => Validators.validateName(value, 'Name'),
                ),
                SizedBox(height: 16.h),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  validator: (value) =>
                      Validators.validateRequired(value, 'Address'),
                ),
                SizedBox(height: 32.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
