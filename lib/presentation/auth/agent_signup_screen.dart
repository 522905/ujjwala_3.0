import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/agent_auth_provider.dart';
import '../../core/utils/aadhaar_validator.dart';
import '../../core/utils/validators.dart';
import 'agent_otp_screen.dart';

/// Agent Signup Screen
///
/// Agent registration with Aadhaar OTP verification
/// Step 1: Enter Aadhaar and Phone Number to generate OTP

class AgentSignupScreen extends StatefulWidget {
  const AgentSignupScreen({super.key});

  @override
  State<AgentSignupScreen> createState() => _AgentSignupScreenState();
}

class _AgentSignupScreenState extends State<AgentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();

  bool? _aadhaarValidationState;

  @override
  void initState() {
    super.initState();
    _aadhaarController.addListener(_validateAadhaar);
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _phoneController.dispose();
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

  Future<void> _generateOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AgentAuthProvider>(context, listen: false);

    final success = await authProvider.generateOTP(
      aadhaarNumber: _aadhaarController.text.trim(),
      phoneNumber: '+91${_phoneController.text.trim()}',
    );

    if (!mounted) return;

    if (success) {
      // Navigate to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgentOTPScreen(
            aadhaarNumber: _aadhaarController.text.trim(),
            phoneNumber: '+91${_phoneController.text.trim()}',
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to generate OTP'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.verified_user,
                  size: 80.sp,
                  color: Colors.blue[700],
                ),
                SizedBox(height: 24.h),

                Text(
                  'Aadhaar OTP Verification',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),

                Text(
                  'Your data will be automatically verified from UIDAI. No manual entry required.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),

                // Aadhaar Number Input with validation
                TextFormField(
                  controller: _aadhaarController,
                  decoration: InputDecoration(
                    labelText: 'Aadhaar Number',
                    hintText: 'Enter 12-digit Aadhaar number',
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: Validators.validateAadhaar,
                ),
                SizedBox(height: 16.h),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: const Icon(Icons.phone),
                    prefix: Text(
                      '+91 ',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16.sp,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: Validators.validateMobile,
                ),
                SizedBox(height: 24.h),

                // Generate OTP Button
                Consumer<AgentAuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _generateOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Generate OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                // Info Text
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.blue[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'OTP will be sent to your Aadhaar-linked mobile number',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue[900],
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
      ),
    );
  }
}
