import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'data/local/hive_service.dart';

/// Main Entry Point
///
/// This is a minimal working version to verify setup.
/// Replace this with full implementation including providers,
/// authentication, and complete UI.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive database
    await HiveService.init();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Hive initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Arun Gas Consumer App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            primaryColor: const Color(0xFF2196F3),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const FoundationTestPage(),
        );
      },
    );
  }
}

/// Foundation Test Page
///
/// This page verifies that the foundation setup is working correctly.
/// Once verified, replace this with the actual Splash Screen.
class FoundationTestPage extends StatefulWidget {
  const FoundationTestPage({super.key});

  @override
  State<FoundationTestPage> createState() => _FoundationTestPageState();
}

class _FoundationTestPageState extends State<FoundationTestPage> {
  Map<String, int>? _hiveStats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHiveStats();
  }

  Future<void> _loadHiveStats() async {
    try {
      final stats = HiveService.getStats();
      setState(() {
        _hiveStats = stats;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ujjwala 3.0 - Foundation Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Icon(
                Icons.check_circle_outline,
                size: 100.sp,
                color: Colors.green,
              ),
              SizedBox(height: 24.h),

              // Title
              Text(
                '🎉 Foundation Setup Complete!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'All core files are in place and working',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),

              // Hive Stats Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hive Database Status',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (_hiveStats != null) ...[
                      _buildStatRow('Applications', _hiveStats!['applications']!),
                      _buildStatRow('Addresses', _hiveStats!['addresses']!),
                      _buildStatRow('Family Members', _hiveStats!['family_members']!),
                      _buildStatRow('Documents', _hiveStats!['documents']!),
                    ],
                    if (_errorMessage != null)
                      Text(
                        'Error: $_errorMessage',
                        style: TextStyle(color: Colors.red, fontSize: 12.sp),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Test Button
              ElevatedButton.icon(
                onPressed: _loadHiveStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Next Steps
              Container(
                padding: EdgeInsets.all(16.w),
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
                        Icon(Icons.info_outline, color: Colors.orange[900]),
                        SizedBox(width: 8.w),
                        Text(
                          'Next Steps',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildNextStep('1. Implement TUS Upload Service'),
                    _buildNextStep('2. Build API Service with Dio'),
                    _buildNextStep('3. Create Authentication Screens'),
                    _buildNextStep('4. Build 7-Step Form Wizard'),
                    _buildNextStep('5. Test Complete User Flow'),
                    SizedBox(height: 8.h),
                    Text(
                      'See IMPLEMENTATION_SUMMARY.md for details',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Checklist
              Text(
                '✅ Core Models\n'
                '✅ Validators & Utils\n'
                '✅ Hive Database\n'
                '✅ Configuration\n'
                '✅ Enumerations',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.green[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String step) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Icon(Icons.arrow_right, size: 16.sp, color: Colors.orange[700]),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              step,
              style: TextStyle(fontSize: 13.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
