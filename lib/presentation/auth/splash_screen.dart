import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'user_login_screen.dart';
import 'agent_login_screen.dart';
import 'agent_signup_screen.dart';
import 'customer_signup_screen.dart';
import 'forgot_password_screen.dart';

/// Splash Screen
///
/// Entry point of the app with options:
/// 1. Login as Agent
/// 2. Login as Customer
/// 3. Sign Up
/// 4. Forgot Password

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo with cylinder icon
                Container(
                  width: 200.w,
                  height: 200.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.propane_tank,
                    size: 100.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),

                // App Name
                Text(
                  'Arun Gas Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  'Ujjwala 3.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 48.h),

                // Login Section
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16.h),

                // Login with Agent Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgentLoginScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.business_center, size: 20.sp),
                    label: Text(
                      'Login with Agent',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),

                // Login with Customer Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UserLoginScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.person, size: 20.sp),
                    label: Text(
                      'Login with Customer',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),

                // Sign Up Section
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'New User?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[400], thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showSignupOptions(context);
                    },
                    icon: Icon(Icons.person_add, size: 20.sp),
                    label: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[700]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Forgot Password Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(height: 40.h),

                // Version
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign Up As',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24.h),

            // Sign Up as Customer
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerSignupScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.person, size: 20.sp),
                label: Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Sign Up as Agent
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AgentSignupScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.business_center, size: 20.sp),
                label: Text(
                  'Agent',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
