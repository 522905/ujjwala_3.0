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
      print('🔵 Initiating Aadhaar verification for: ${aadhaarNumber.substring(0, 4)}****');

      final response = await _dio.post(
        ApiConfig.authAgentInitiateAadhaarEndpoint,
        data: {
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      print('✅ API Response Status: ${response.statusCode}');
      print('📦 API Response Data: ${response.data}');

      // Check if response.data is null or not a Map
      if (response.data == null) {
        throw AgentKYCException('API returned null response');
      }

      final otpResponse = AadhaarOTPResponse.fromJson(response.data);

      print('🔍 Parsed OTP Response - Success: ${otpResponse.success}, RefId: ${otpResponse.refId}');

      if (!otpResponse.success) {
        throw AgentKYCException(
          otpResponse.error ?? 'Failed to generate OTP',
        );
      }

      return otpResponse;
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');

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
    } on AgentKYCException {
      rethrow;
    } catch (e) {
      print('❌ Unexpected Error: ${e.toString()}');
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
      print('🔵 Submitting OTP for ref_id: $refId');

      final response = await _dio.post(
        ApiConfig.authAgentSubmitAadhaarOTPEndpoint,
        data: {
          'ref_id': refId,
          'otp': otp,
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      print('✅ OTP Verification Response Status: ${response.statusCode}');
      print('📦 OTP Verification Response Data: ${response.data}');

      // Check if response.data is null or not a Map
      if (response.data == null) {
        throw AgentKYCException('API returned null response');
      }

      final kycResponse = AgentKYCResponse.fromJson(response.data);

      print('🔍 Parsed KYC Response - Success: ${kycResponse.success}, KYC ID: ${kycResponse.kycId}, Name: ${kycResponse.name}');

      if (!kycResponse.success) {
        throw AgentKYCException(
          kycResponse.error ?? 'OTP verification failed',
        );
      }

      return kycResponse;
    } on DioException catch (e) {
      print('❌ DioException during OTP verification: ${e.message}');
      print('❌ Response Status: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');

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
    } on AgentKYCException {
      rethrow;
    } catch (e) {
      print('❌ Unexpected Error during OTP verification: ${e.toString()}');
      throw AgentKYCException('Unexpected error: ${e.toString()}');
    }
  }
}
