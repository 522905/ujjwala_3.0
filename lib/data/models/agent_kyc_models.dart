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
    return AadhaarOTPResponse(
      success: json['success'] ?? false,
      refId: json['ref_id'] ?? '',
      message: json['message'] ?? '',
      maskedNumber: json['if_number'],
      error: json['error'],
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
    return AgentKYCResponse(
      success: json['success'] ?? false,
      kycId: json['kyc_id'],
      name: json['name'],
      message: json['message'] ?? '',
      error: json['error'],
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
