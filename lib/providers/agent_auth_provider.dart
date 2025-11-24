/// Agent Authentication Provider
///
/// State management for Agent Aadhaar OTP verification flow

import 'package:flutter/foundation.dart';
import '../data/services/agent_auth_service.dart';
import '../data/models/agent_kyc_models.dart';

class AgentAuthProvider extends ChangeNotifier {
  final AgentAuthService _authService;

  AgentAuthProvider(this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  AadhaarOTPResponse? _otpResponse;
  AgentKYCResponse? _kycResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AadhaarOTPResponse? get otpResponse => _otpResponse;
  AgentKYCResponse? get kycResponse => _kycResponse;

  /// Generate OTP for Aadhaar verification
  Future<bool> generateOTP({
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _otpResponse = await _authService.initiateAadhaarVerification(
        aadhaarNumber: aadhaarNumber,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AgentKYCException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit OTP and complete KYC
  Future<bool> verifyOTP({
    required String otp,
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    if (_otpResponse == null) {
      _errorMessage = 'Please generate OTP first';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kycResponse = await _authService.submitAadhaarOTP(
        refId: _otpResponse!.refId,
        otp: otp,
        aadhaarNumber: aadhaarNumber,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AgentKYCException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear state
  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _otpResponse = null;
    _kycResponse = null;
    notifyListeners();
  }
}
