/// Agent KYC Models for Aadhaar OTP Verification
///
/// Data models for Cashfree Aadhaar OTP verification integration

/// Agent KYC status enum
enum AgentKYCStatus {
  pending,
  aadhaarVerified,
  approved,
  rejected;

  String toServerValue() {
    switch (this) {
      case AgentKYCStatus.aadhaarVerified:
        return 'aadhaar_verified';
      case AgentKYCStatus.approved:
        return 'approved';
      case AgentKYCStatus.rejected:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  static AgentKYCStatus fromServerValue(String value) {
    switch (value) {
      case 'aadhaar_verified':
        return AgentKYCStatus.aadhaarVerified;
      case 'approved':
        return AgentKYCStatus.approved;
      case 'rejected':
        return AgentKYCStatus.rejected;
      default:
        return AgentKYCStatus.pending;
    }
  }
}

/// Response from initiate Aadhaar verification
class AadhaarOTPResponse {
  final bool success;
  final String refId;
  final String message;
  final String? maskedNumber;
  final String? error;

  AadhaarOTPResponse({
    required this.success,
    required this.refId,
    required this.message,
    this.maskedNumber,
    this.error,
  });

  factory AadhaarOTPResponse.fromJson(Map<String, dynamic> json) {
    // If we have a ref_id, consider it successful even if success field is missing
    final hasRefId = json['ref_id'] != null && json['ref_id'].toString().isNotEmpty;
    final explicitSuccess = json['success'];

    // Determine success: explicit true OR (no explicit false AND has ref_id)
    final isSuccessful = explicitSuccess == true ||
                        (explicitSuccess != false && hasRefId);

    print('🔍 [Model] Parsing response: success=$explicitSuccess, ref_id=${json['ref_id']}, determined=$isSuccessful');

    return AadhaarOTPResponse(
      success: isSuccessful,
      refId: json['ref_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      maskedNumber: json['if_number']?.toString(),
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'ref_id': refId,
      'message': message,
      'if_number': maskedNumber,
      'error': error,
    };
  }
}

/// Response from OTP submission
class AgentKYCResponse {
  final bool success;
  final int? kycId;
  final String? name;
  final String message;
  final String? error;

  AgentKYCResponse({
    required this.success,
    this.kycId,
    this.name,
    required this.message,
    this.error,
  });

  factory AgentKYCResponse.fromJson(Map<String, dynamic> json) {
    // If we have a kyc_id, consider it successful even if success field is missing
    final hasKycId = json['kyc_id'] != null;
    final explicitSuccess = json['success'];

    // Determine success: explicit true OR (no explicit false AND has kyc_id)
    final isSuccessful = explicitSuccess == true ||
                        (explicitSuccess != false && hasKycId);

    print('🔍 [Model] Parsing KYC response: success=$explicitSuccess, kyc_id=${json['kyc_id']}, determined=$isSuccessful');

    return AgentKYCResponse(
      success: isSuccessful,
      kycId: json['kyc_id'],
      name: json['name']?.toString(),
      message: json['message']?.toString() ?? '',
      error: json['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'kyc_id': kycId,
      'name': name,
      'message': message,
      'error': error,
    };
  }
}

/// Exception for Agent KYC errors
class AgentKYCException implements Exception {
  final String message;
  final int? statusCode;

  AgentKYCException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
