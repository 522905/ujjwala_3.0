/// Agent Authentication Service
///
/// Service for Agent Aadhaar OTP verification API calls

import 'package:dio/dio.dart';
import '../models/agent_kyc_models.dart';
import '../../core/config/api_config.dart';

class AgentAuthService {
  final Dio _dio;

  AgentAuthService(this._dio);

  /// Step 1: Initiate Aadhaar verification and generate OTP
  Future<AadhaarOTPResponse> initiateAadhaarVerification({
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.authAgentInitiateAadhaarEndpoint,
        data: {
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      final otpResponse = AadhaarOTPResponse.fromJson(response.data);

      if (!otpResponse.success) {
        throw AgentKYCException(
          otpResponse.error ?? 'Failed to generate OTP',
        );
      }

      return otpResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AgentKYCException(
          'Agent with this Aadhaar already exists',
          statusCode: 409,
        );
      }

      final errorMessage = e.response?.data?['error'] ??
          e.message ??
          'Failed to initiate verification';
      throw AgentKYCException(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      throw AgentKYCException('Unexpected error: ${e.toString()}');
    }
  }

  /// Step 2: Submit OTP and complete KYC
  Future<AgentKYCResponse> submitAadhaarOTP({
    required String refId,
    required String otp,
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.authAgentSubmitAadhaarOTPEndpoint,
        data: {
          'ref_id': refId,
          'otp': otp,
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      final kycResponse = AgentKYCResponse.fromJson(response.data);

      if (!kycResponse.success) {
        throw AgentKYCException(
          kycResponse.error ?? 'OTP verification failed',
        );
      }

      return kycResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AgentKYCException(
          'Agent with this Aadhaar already exists',
          statusCode: 409,
        );
      }

      final errorMessage = e.response?.data?['error'] ??
          e.message ??
          'OTP verification failed';
      throw AgentKYCException(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      throw AgentKYCException('Unexpected error: ${e.toString()}');
    }
  }
}
