import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';
import '../core/enums/app_enums.dart';

/// Authentication Provider
///
/// Manages authentication state across the app

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  bool _isLoggedIn = false;
  bool _isLoading = false;
  UserRole? _userRole;
  String? _userId;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  UserRole? get userRole => _userRole;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  bool get isUser => _userRole == UserRole.user;
  bool get isAgent => _userRole == UserRole.agent || _userRole == UserRole.teamLeader;

  /// Check if user is logged in (on app start)
  Future<void> checkLoginStatus() async {
    try {
      _isLoggedIn = await _authRepository.isLoggedIn();

      if (_isLoggedIn) {
        final roleStr = await _authRepository.getUserRole();
        _userRole = roleStr != null ? UserRole.fromValue(roleStr) : null;
        _userId = await _authRepository.getUserId();
      }

      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  /// Send OTP to mobile
  Future<bool> sendOtp(String mobile) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.sendOtp(mobile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Login with mobile + OTP
  Future<bool> loginWithOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authRepository.loginWithOtp(
        mobile: mobile,
        otp: otp,
      );

      _isLoggedIn = true;
      _userRole = UserRole.fromValue(response['role']);
      _userId = response['user_id'].toString();
      _isLoading = false;

      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Login with Aadhaar + Password (Agent)
  Future<bool> loginWithPassword({
    required String aadhaar,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authRepository.loginWithPassword(
        aadhaar: aadhaar,
        password: password,
      );

      _isLoggedIn = true;
      _userRole = UserRole.fromValue(response['role']);
      _userId = response['user_id'].toString();
      _isLoading = false;

      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Agent Signup
  Future<Map<String, dynamic>?> agentSignup({
    required String aadhaarNumber,
    required String mobile,
    required String name,
    required String address,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authRepository.agentSignup(
        aadhaarNumber: aadhaarNumber,
        mobile: mobile,
        name: name,
        address: address,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Forgot Password - Initiate
  Future<bool> forgotPasswordInitiate(String aadhaar) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.forgotPasswordInitiate(aadhaar);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Forgot Password - Verify OTP
  Future<bool> forgotPasswordVerifyOtp({
    required String aadhaar,
    required String otp,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.forgotPasswordVerifyOtp(
        aadhaar: aadhaar,
        otp: otp,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Forgot Password - Reset
  Future<bool> forgotPasswordReset({
    required String aadhaar,
    required String otp,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.forgotPasswordReset(
        aadhaar: aadhaar,
        otp: otp,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Change Password
  Future<bool> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authRepository.changePassword(
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    _isLoggedIn = false;
    _userRole = null;
    _userId = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
