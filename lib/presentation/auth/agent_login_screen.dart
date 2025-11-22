import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';
import '../dashboard/main_container.dart';

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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.business_center, size: 80.sp, color: Colors.blue[700]),
                  SizedBox(height: 24.h),
                  Text('Agent Login', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 32.h),

                  TextFormField(
                    controller: _aadhaarController,
                    decoration: InputDecoration(
                      labelText: 'Aadhaar Number',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    validator: Validators.validateAadhaar,
                  ),
                  SizedBox(height: 16.h),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword,
                  ),
                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
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
