import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/submission_provider.dart';
import '../../data/models/local_application.dart';
import 'submission_success_screen.dart';

/// Submission Progress Screen
///
/// Shows real-time progress during application submission

class SubmissionProgressScreen extends StatefulWidget {
  final LocalApplication application;

  const SubmissionProgressScreen({
    super.key,
    required this.application,
  });

  @override
  State<SubmissionProgressScreen> createState() =>
      _SubmissionProgressScreenState();
}

class _SubmissionProgressScreenState extends State<SubmissionProgressScreen> {
  @override
  void initState() {
    super.initState();
    _startSubmission();
  }

  Future<void> _startSubmission() async {
    final submissionProvider =
        Provider.of<SubmissionProvider>(context, listen: false);

    final success = await submissionProvider.submitApplication(
      widget.application,
    );

    if (mounted) {
      if (success) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SubmissionSuccessScreen(
              applicationNumber:
                  submissionProvider.submittedApplicationNumber!,
              applicationId: submissionProvider.submittedApplicationId!,
            ),
          ),
        );
      } else {
        // Show error dialog
        _showErrorDialog(submissionProvider.errorMessage);
      }
    }
  }

  void _showErrorDialog(String? errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Submission Failed'),
        content: Text(
          errorMessage ?? 'An error occurred during submission',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to review screen
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _startSubmission(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button during submission
      child: Scaffold(
        body: SafeArea(
          child: Consumer<SubmissionProvider>(
            builder: (context, submissionProvider, _) {
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Progress Circle
                      SizedBox(
                        width: 200.w,
                        height: 200.h,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: submissionProvider.uploadProgress,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              color: Colors.blue[700],
                            ),
                            Text(
                              '${(submissionProvider.uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Status Icon
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload,
                          size: 48.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Title
                      Text(
                        'Submitting Application',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),

                      // Current Step
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          submissionProvider.currentStep,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Info Message
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Please do not close the app or press back during submission.',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Progress Steps
                      _buildProgressSteps(submissionProvider.uploadProgress),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSteps(double progress) {
    final steps = [
      {'label': 'Validating', 'threshold': 0.2},
      {'label': 'Checking uploads', 'threshold': 0.4},
      {'label': 'Submitting', 'threshold': 0.9},
      {'label': 'Finalizing', 'threshold': 1.0},
    ];

    return Column(
      children: steps.map((step) {
        final isComplete = progress >= (step['threshold'] as double);
        final isCurrent = progress < (step['threshold'] as double) &&
            (steps.indexOf(step) == 0 ||
                progress >= (steps[steps.indexOf(step) - 1]['threshold'] as double));

        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Icon(
                isComplete
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                color: isComplete
                    ? Colors.green
                    : isCurrent
                        ? Colors.blue[700]
                        : Colors.grey[400],
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isComplete
                      ? Colors.green
                      : isCurrent
                          ? Colors.blue[700]
                          : Colors.grey[600],
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
