import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

/// API Service
///
/// Handles all HTTP requests to the backend with JWT authentication,
/// automatic token refresh, and error handling.

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor(_secureStorage, _dio));
    _dio.interceptors.add(_ErrorInterceptor());
  }

  /// GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH request
  Future<Response> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.patch(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Download file
  Future<Response> downloadFile(
    String endpoint,
    String savePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      return await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: onProgress,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Authentication Interceptor
///
/// Automatically adds JWT token to requests and refreshes expired tokens
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final token = await _storage.read(key: ApiConfig.accessTokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized (token expired)
    if (err.response?.statusCode == 401) {
      try {
        // Try to refresh token
        final refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);

        if (refreshToken != null && refreshToken.isNotEmpty) {
          // Call refresh token endpoint
          final response = await _dio.post(
            ApiConfig.authRefreshTokenEndpoint,
            data: {'refresh': refreshToken},
            options: Options(
              headers: {
                'Authorization': null, // Don't send old token
              },
            ),
          );

          final newToken = response.data['access'];

          // Store new token
          await _storage.write(
            key: ApiConfig.accessTokenKey,
            value: newToken,
          );

          // Retry original request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';

          final cloneReq = await _dio.fetch(opts);
          return handler.resolve(cloneReq);
        }
      } catch (e) {
        // Refresh failed, clear tokens and let user re-login
        await _storage.delete(key: ApiConfig.accessTokenKey);
        await _storage.delete(key: ApiConfig.refreshTokenKey);
      }
    }

    handler.next(err);
  }
}

/// Error Interceptor
///
/// Handles and formats errors from API
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Format error message
    String errorMessage = 'An error occurred';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Connection timeout. Please check your internet connection.';
    } else if (err.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection. Please check your network.';
    } else if (err.response != null) {
      final statusCode = err.response!.statusCode;
      final data = err.response!.data;

      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data is Map && data.containsKey('error')) {
        errorMessage = data['error'];
      } else {
        switch (statusCode) {
          case 400:
            errorMessage = 'Invalid request. Please check your input.';
            break;
          case 401:
            errorMessage = 'Session expired. Please login again.';
            break;
          case 403:
            errorMessage = 'You do not have permission to perform this action.';
            break;
          case 404:
            errorMessage = 'Resource not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Error: $statusCode';
        }
      }
    }

    // Create custom DioException with formatted message
    final formattedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );

    handler.next(formattedError);
  }
}

/// API Exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? fieldErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  @override
  String toString() => message;
}
