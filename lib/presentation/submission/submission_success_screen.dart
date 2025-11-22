import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../dashboard/main_container.dart';

/// Submission Success Screen
///
/// Shows success message with application number and next steps

class SubmissionSuccessScreen extends StatelessWidget {
  final String applicationNumber;
  final int applicationId;

  const SubmissionSuccessScreen({
    super.key,
    required this.applicationNumber,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation/Icon
                  Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80.sp,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Success Title
                  Text(
                    'Application Submitted!',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),

                  // Success Message
                  Text(
                    'Your application has been submitted successfully',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),

                  // Application Number Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Application Number',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          applicationNumber,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Submitted on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Next Steps Info
                  Container(
                    padding: EdgeInsets.all(20.w),
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
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            SizedBox(width: 12.w),
                            Text(
                              'Next Steps',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildNextStep(
                          '1',
                          'Your application will be verified within 72 hours',
                        ),
                        _buildNextStep(
                          '2',
                          'After verification, you can download forms for signature',
                        ),
                        _buildNextStep(
                          '3',
                          'Upload signed forms back to complete the process',
                        ),
                        _buildNextStep(
                          '4',
                          'You will be notified about further updates',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Important Note
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark, color: Colors.blue[700]),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Please save your application number for future reference',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainContainer(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Go to Home'),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Secondary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Navigate to application detail screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('View application details - Coming soon'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('View Application Details'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: Colors.orange[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
