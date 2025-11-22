import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import '../forms/step1_applicant_details_screen.dart';

/// Home Screen
///
/// Shows welcome message and action buttons based on user role:
/// - End Users: Start new application or continue draft
/// - Agents: Quick stats and actions

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startNewApplication(BuildContext context) async {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    await appProvider.createNewApplication();

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Step1ApplicantDetailsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ApplicationProvider>(
      builder: (context, authProvider, appProvider, _) {
        final isAgent = authProvider.isAgent;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Text(
                  isAgent ? 'Welcome, Agent' : 'Welcome',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  isAgent
                      ? 'Manage applications and Pre-Sureksha inspections'
                      : 'Apply for LPG connection under Ujjwala 3.0',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32.h),

                // Info Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Ujjwala 3.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'PMUY for Migrant Households',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // User-specific content
                if (!isAgent) ...[
                  // New Application Button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: () => _startNewApplication(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Start New Application'),
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

                  // Information Cards
                  _buildInfoCard(
                    icon: Icons.check_circle_outline,
                    title: 'Easy Process',
                    description: 'Complete your application in 7 simple steps',
                    color: Colors.green,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    icon: Icons.cloud_upload_outlined,
                    title: 'Upload Documents',
                    description: 'Submit required documents from your phone',
                    color: Colors.orange,
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoCard(
                    icon: Icons.timer_outlined,
                    title: 'Quick Verification',
                    description: 'Get verified within 72 hours',
                    color: Colors.purple,
                  ),
                ] else ...[
                  // Agent Dashboard Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.pending_actions,
                          title: 'Pending',
                          count: '0',
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          title: 'Completed',
                          count: '0',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.camera_alt,
                          title: 'Pre-Sureksha',
                          count: '0',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.sync,
                          title: 'To Sync',
                          count: '0',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 8.h),
          Text(
            count,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
