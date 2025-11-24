import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../dashboard/main_container.dart';
import 'agent_signup_screen.dart';
import 'forgot_password_screen.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithPassword(
      aadhaar: _aadhaarController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainContainer()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Login'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Professional Agent Icon with gradient background
                  Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[700]!, Colors.blue[500]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(60.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      size: 60.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Text(
                    'Agent Login',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Text(
                    'Enter your credentials to continue',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Aadhaar Number Field with professional styling
                  TextFormField(
                    controller: _aadhaarController,
                    decoration: InputDecoration(
                      labelText: 'Aadhaar Number',
                      prefixIcon: Icon(Icons.badge, color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    validator: Validators.validateAadhaar,
                  ),
                  SizedBox(height: 16.h),

                  // Password Field with professional styling
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_rounded, color: Colors.blue[700]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                  ),
                  SizedBox(height: 24.h),

                  // Login Button with icon
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _login,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.login, size: 20.sp),
                      label: Text(
                        _isLoading ? 'Logging in...' : 'Login',
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
                  SizedBox(height: 24.h),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AgentSignupScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.person_add, size: 18.sp),
                      label: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        side: BorderSide(color: Colors.blue[700]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Forgot Password Button
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.help_outline, size: 18.sp),
                    label: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 14.sp,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
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
}
