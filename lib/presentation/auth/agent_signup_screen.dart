import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/aadhaar_validator.dart';
import '../../core/utils/validators.dart';

/// Agent Signup Screen
///
/// Agent registration with Aadhaar verification and KYC

class AgentSignupScreen extends StatefulWidget {
  const AgentSignupScreen({super.key});

  @override
  State<AgentSignupScreen> createState() => _AgentSignupScreenState();
}

class _AgentSignupScreenState extends State<AgentSignupScreen> {
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.agentSignup(
      aadhaarNumber: _aadhaarController.text.trim(),
      mobile: _mobileController.text.trim(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (response != null) {
      _showSuccessDialog(response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30.sp),
            SizedBox(width: 12.w),
            const Text('KYC Submitted'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your KYC has been submitted successfully!',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Your application is under review. You will receive your Agent ID and temporary password via SMS once approved.',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC ID: ${response['kyc_id']}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Please save this for reference',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
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
        title: const Text('Agent Signup'),
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
                  Icons.business_center,
                  size: 80.sp,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 16.h),

                Text(
                  'Register as Agent',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),

                Text(
                  'Submit your KYC details for verification',
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
                        : const Text('Submit KYC'),
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
