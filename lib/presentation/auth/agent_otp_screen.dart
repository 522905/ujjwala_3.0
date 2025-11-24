import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/agent_auth_provider.dart';
import 'agent_kyc_review_screen.dart';

/// Agent OTP Verification Screen
///
/// Screen for entering and verifying OTP sent to Aadhaar-linked mobile

class AgentOTPScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String phoneNumber;

  const AgentOTPScreen({
    super.key,
    required this.aadhaarNumber,
    required this.phoneNumber,
  });

  @override
  State<AgentOTPScreen> createState() => _AgentOTPScreenState();
}

class _AgentOTPScreenState extends State<AgentOTPScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter 6-digit OTP'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AgentAuthProvider>(context, listen: false);

    print('🔵 [OTP Screen] Verifying OTP: ${_otpController.text}');

    final success = await authProvider.verifyOTP(
      otp: _otpController.text,
      aadhaarNumber: widget.aadhaarNumber,
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    print('✅ [OTP Screen] Verification success: $success');
    print('📦 [OTP Screen] KYC Response: ${authProvider.kycResponse}');

    if (success) {
      // Check if we have all required data
      final kycResponse = authProvider.kycResponse;

      if (kycResponse == null) {
        print('❌ [OTP Screen] KYC Response is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification successful but response data is missing'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      print('🔍 [OTP Screen] KYC ID: ${kycResponse.kycId}, Name: ${kycResponse.name}');

      // Navigate to success screen with safe defaults
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgentKYCReviewScreen(
            kycId: kycResponse.kycId ?? 0,
            name: kycResponse.name ?? 'Agent',
            message: kycResponse.message,
          ),
        ),
      );
    } else {
      // Show error
      print('❌ [OTP Screen] Verification failed: ${authProvider.errorMessage}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'OTP verification failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AgentAuthProvider>(context);
    final maskedNumber = authProvider.otpResponse?.maskedNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.verified_user,
                size: 80.sp,
                color: Colors.blue[700],
              ),
              SizedBox(height: 24.h),

              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              Text(
                maskedNumber != null
                    ? 'OTP sent to Aadhaar-linked mobile:\n$maskedNumber'
                    : 'OTP sent to your Aadhaar-linked mobile',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // OTP Input
              TextFormField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter 6-digit OTP',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              SizedBox(height: 24.h),

              // Verify Button
              SizedBox(
                height: 56.h,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _verifyOTP,
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
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16.h),

              // Resend OTP
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
