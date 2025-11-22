import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/splash_screen.dart';

/// Profile Screen
///
/// Shows user information and settings

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                // Profile Header
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
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          authProvider.isAgent
                              ? Icons.business_center
                              : Icons.person,
                          size: 48.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        authProvider.isAgent ? 'Agent' : 'Consumer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Ujjwala 3.0',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Account Information
                _buildSectionTitle('Account Information'),
                SizedBox(height: 12.h),
                _buildInfoTile(
                  icon: Icons.badge,
                  title: 'User ID',
                  value: authProvider.userId?.toString() ?? 'N/A',
                ),
                _buildInfoTile(
                  icon: Icons.security,
                  title: 'Role',
                  value: authProvider.isAgent ? 'Agent' : 'Consumer',
                ),
                SizedBox(height: 24.h),

                // App Settings
                _buildSectionTitle('Settings'),
                SizedBox(height: 12.h),
                _buildMenuTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings - Coming soon'),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language settings - Coming soon'),
                      ),
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Ujjwala 3.0',
                      applicationVersion: 'v1.0.0',
                      applicationLegalese: '© 2024 Arun Gas Services',
                      children: [
                        SizedBox(height: 16.h),
                        const Text(
                          'PMUY for Migrant Households\n'
                          'LPG Connection Application System',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & Support - Coming soon'),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // App Version
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[700]),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 13.sp),
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}
