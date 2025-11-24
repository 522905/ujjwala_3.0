/// API Configuration
///
/// Configure base URLs for different environments here.
/// This file should be updated with actual URLs for dev/staging/production.

class ApiConfig {
  // Environment Selection
  static const Environment currentEnvironment = Environment.production;

  // Base URLs
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return developmentBaseUrl;
      case Environment.staging:
        return stagingBaseUrl;
      case Environment.production:
        return productionBaseUrl;
    }
  }

  // TUS Upload Server (same for all environments as per backend doc)
  static const String tusUploadUrl = 'https://tus.dca.arungas.com/files/';

  // Environment-specific URLs
  static const String developmentBaseUrl = 'https://dev.arungas.com';
  static const String stagingBaseUrl = 'https://staging.arungas.com';
  static const String productionBaseUrl = 'http://192.168.171.49:8000';
  // static const String productionBaseUrl = 'https://dca.arungas.com';

  // API Endpoints (use static getters to access current environment's baseUrl)
  static String get authLoginEndpoint => '${baseUrl}/auth/login/';
  static String get authSendOtpEndpoint => '${baseUrl}/auth/send-otp/';
  static String get authRefreshTokenEndpoint => '${baseUrl}/auth/token/refresh/';
  static String get authAgentSignupEndpoint => '${baseUrl}/auth/agent/signup/';
  static String get authAgentForgotPasswordEndpoint => '${baseUrl}/auth/agent/forgot-password/';
  static String get authAgentChangePasswordEndpoint => '${baseUrl}/auth/agent/change-password/';

  // Agent Aadhaar KYC Endpoints (NEW)
  static String get authAgentInitiateAadhaarEndpoint => '${baseUrl}/auth/agent/initiate-aadhaar/';
  static String get authAgentSubmitAadhaarOTPEndpoint => '${baseUrl}/auth/agent/submit-aadhaar-otp/';

  static String get applicationsEndpoint => '${baseUrl}/api/ujjwala-v3/applications/';
  static String get applicationsFormsEndpoint => '${baseUrl}/api/ujjwala-v3/applications/{id}/forms/';
  static String get applicationsSubmitFormsEndpoint => '${baseUrl}/api/ujjwala-v3/applications/{id}/submit-forms/';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // JWT Token Keys
  static const String accessTokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';

  // App Constants
  static const String appName = 'Arun Gas Consumer App';
  static const String appVersion = '1.0.0';

  // Image Compression
  static const int aadhaarImageQuality = 92;
  static const int documentImageQuality = 90;
  static const int maxImageWidth = 2048;
  static const int maxAadhaarImageWidth = 1520;
  static const int maxFileSizeMB = 5;

  // Polling Intervals
  static const Duration statusPollingInterval = Duration(minutes: 30);

  // Local Storage
  static const int maxStoredUsernames = 5;
  static const String usernamesListKey = 'saved_usernames';
  static const String isLoggedInKey = 'is_logged_in';
}

enum Environment {
  development,
  staging,
  production,
}
