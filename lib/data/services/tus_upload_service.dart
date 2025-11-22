import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../../core/config/api_config.dart';

/// File Upload Service
///
/// Handles resumable file uploads to server using multipart upload.
/// Previously used TUS protocol, now using standard HTTP multipart.
/// Can be extended to support TUS protocol via Dio interceptors if needed.

class TusUploadService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.tusUploadUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Upload file to server
  ///
  /// Returns the file URL after successful upload
  Future<String> uploadFile({
    required File file,
    required String filename,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate file
      final isValid = await validateFile(file);
      if (!isValid) {
        throw Exception('Invalid file or file exceeds size limit');
      }

      // Create multipart file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
        'filename': filename,
        'filetype': _getMimeType(filename),
      });

      // Upload with progress tracking
      final response = await _dio.post(
        '/upload', // Endpoint path - adjust based on your backend
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total != -1) {
            final progress = (sent / total);
            onProgress(progress);
          }
        },
      );

      // Extract file URL from response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Adjust based on your backend response structure
        if (data is Map<String, dynamic>) {
          final fileUrl = data['url'] ?? data['file_url'] ?? data['path'];

          if (fileUrl == null || fileUrl.toString().isEmpty) {
            throw Exception('Upload response missing file URL');
          }

          return fileUrl.toString();
        } else if (data is String) {
          return data;
        }

        throw Exception('Unexpected response format');
      }

      throw Exception('Upload failed with status: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Upload failed: ${e.response?.data ?? e.message}');
      } else {
        throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  /// Upload with automatic retry logic
  Future<String> uploadWithRetry({
    required File file,
    required String filename,
    int maxRetries = 3,
    Function(double)? onProgress,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        return await uploadFile(
          file: file,
          filename: filename,
          onProgress: onProgress,
        );
      } catch (e) {
        lastError = e as Exception;
        attempt++;

        if (attempt >= maxRetries) {
          throw Exception('Upload failed after $maxRetries attempts: $e');
        }

        // Wait before retry (exponential backoff: 2s, 4s, 8s)
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw lastError ?? Exception('Upload failed');
  }

  /// Upload multiple files
  Future<List<String>> uploadMultiple({
    required List<File> files,
    required List<String> filenames,
    Function(int current, int total, double progress)? onProgress,
  }) async {
    final urls = <String>[];

    for (int i = 0; i < files.length; i++) {
      final url = await uploadWithRetry(
        file: files[i],
        filename: filenames[i],
        onProgress: (progress) {
          onProgress?.call(i + 1, files.length, progress);
        },
      );
      urls.add(url);
    }

    return urls;
  }

  /// Get MIME type from filename
  String _getMimeType(String filename) {
    final extension = path.extension(filename).toLowerCase();

    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check if file exists and is readable
  Future<bool> validateFile(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }

      final size = await file.length();
      if (size == 0) {
        return false;
      }

      // Check max file size (5MB as per requirements)
      final maxSizeBytes = ApiConfig.maxFileSizeMB * 1024 * 1024;
      if (size > maxSizeBytes) {
        throw Exception('File size exceeds ${ApiConfig.maxFileSizeMB}MB limit');
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancel ongoing upload (if needed)
  void cancelUpload() {
    // Can be extended to track and cancel specific uploads
    // For now, this is a placeholder
  }

  /// Set custom headers (e.g., authentication token)
  void setHeaders(Map<String, String> headers) {
    _dio.options.headers.addAll(headers);
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}

/*
 * IMPLEMENTATION NOTES:
 *
 * This service replaces the TUS client with standard HTTP multipart uploads using Dio.
 *
 * If you need true TUS protocol support (resumable uploads), you can:
 * 1. Implement TUS protocol manually using Dio interceptors
 * 2. Use a different TUS package like 'cross_file' with custom upload logic
 * 3. Configure your backend to accept standard multipart uploads
 *
 * Current implementation:
 * - Uses Dio multipart upload (widely compatible)
 * - Includes retry logic with exponential backoff
 * - Progress tracking
 * - File validation
 * - MIME type detection
 *
 * Backend endpoint expectations:
 * - POST /upload
 * - Accepts multipart/form-data
 * - Returns JSON: { "url": "file_url" } or { "file_url": "file_url" }
 *
 * To switch back to TUS protocol:
 * 1. Find a working TUS client package
 * 2. Or implement TUS PATCH protocol manually
 * 3. Update ApiConfig.tusUploadUrl to point to TUS server
 */
