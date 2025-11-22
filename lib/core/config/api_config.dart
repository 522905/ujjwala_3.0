/// API Configuration
///
/// Configure base URLs for different environments here.
/// This file should be updated with actual URLs for dev/staging/production.

class ApiConfig {
  // Environment Selection
  static const Environment currentEnvironment = Environment.development;

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
  static const String productionBaseUrl = 'https://api.arungas.com';

  // API Endpoints
  static const String authLoginEndpoint = '/auth/login/';
  static const String authSendOtpEndpoint = '/auth/send-otp/';
  static const String authRefreshTokenEndpoint = '/auth/token/refresh/';
  static const String authAgentSignupEndpoint = '/auth/agent/signup/';
  static const String authAgentForgotPasswordEndpoint = '/auth/agent/forgot-password/';
  static const String authAgentChangePasswordEndpoint = '/auth/agent/change-password/';

  static const String applicationsEndpoint = '/api/ujjwala-v3/applications/';
  static const String applicationsFormsEndpoint = '/api/ujjwala-v3/applications/{id}/forms/';
  static const String applicationsSubmitFormsEndpoint = '/api/ujjwala-v3/applications/{id}/submit-forms/';

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
