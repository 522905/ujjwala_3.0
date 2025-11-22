import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../../core/config/api_config.dart';

/// Authentication Repository
///
/// Handles all authentication-related operations

class AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._apiService);

  /// Send OTP to mobile number (End User)
  Future<void> sendOtp(String mobile) async {
    try {
      await _apiService.post(
        ApiConfig.authSendOtpEndpoint,
        data: {'mobile': mobile},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Login with mobile + OTP (End User)
  Future<Map<String, dynamic>> loginWithOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authLoginEndpoint,
        data: {
          'username': mobile,
          'password': otp,
        },
      );

      final data = response.data;

      // Store tokens
      await _storeTokens(
        accessToken: data['token'],
        refreshToken: data['refresh'],
        role: data['role'],
        userId: data['user_id'].toString(),
      );

      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Login with Aadhaar + Password (Agent)
  Future<Map<String, dynamic>> loginWithPassword({
    required String aadhaar,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authLoginEndpoint,
        data: {
          'username': aadhaar,
          'password': password,
        },
      );

      final data = response.data;

      // Store tokens
      await _storeTokens(
        accessToken: data['token'],
        refreshToken: data['refresh'],
        role: data['role'],
        userId: data['user_id'].toString(),
      );

      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// Agent Signup (Aadhaar + OTP)
  Future<Map<String, dynamic>> agentSignup({
    required String aadhaarNumber,
    required String mobile,
    required String name,
    required String address,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.authAgentSignupEndpoint,
        data: {
          'aadhaar_number': aadhaarNumber,
          'mobile': mobile,
          'name': name,
          'address': address,
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Forgot Password - Initiate (Aadhaar + OTP)
  Future<void> forgotPasswordInitiate(String aadhaar) async {
    try {
      await _apiService.post(
        '${ApiConfig.authAgentForgotPasswordEndpoint}/initiate/',
        data: {'aadhaar_number': aadhaar},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Forgot Password - Verify OTP
  Future<void> forgotPasswordVerifyOtp({
    required String aadhaar,
    required String otp,
  }) async {
    try {
      await _apiService.post(
        '${ApiConfig.authAgentForgotPasswordEndpoint}/verify-otp/',
        data: {
          'aadhaar_number': aadhaar,
          'otp': otp,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Forgot Password - Reset
  Future<void> forgotPasswordReset({
    required String aadhaar,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '${ApiConfig.authAgentForgotPasswordEndpoint}/reset/',
        data: {
          'aadhaar_number': aadhaar,
          'otp': otp,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Change Password (Agent - logged in)
  Future<void> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _apiService.post(
        ApiConfig.authAgentChangePasswordEndpoint,
        data: {
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Store authentication tokens
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required String role,
    required String userId,
  }) async {
    await Future.wait([
      _secureStorage.write(key: ApiConfig.accessTokenKey, value: accessToken),
      _secureStorage.write(key: ApiConfig.refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: ApiConfig.userRoleKey, value: role),
      _secureStorage.write(key: ApiConfig.userIdKey, value: userId),
      _secureStorage.write(key: ApiConfig.isLoggedInKey, value: 'true'),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final isLoggedIn = await _secureStorage.read(key: ApiConfig.isLoggedInKey);
    return isLoggedIn == 'true';
  }

  /// Get current user role
  Future<String?> getUserRole() async {
    return await _secureStorage.read(key: ApiConfig.userRoleKey);
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: ApiConfig.userIdKey);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: ApiConfig.accessTokenKey);
  }

  /// Logout
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }
}
