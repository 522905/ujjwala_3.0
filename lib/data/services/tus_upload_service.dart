import 'dart:io';
import 'package:tusc/tusc.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import '../../core/config/api_config.dart';

/// TUS Upload Service
///
/// Handles resumable file uploads to TUS server using tusc package.
/// Returns permanent TUS URLs after successful upload.

class TusUploadService {
  /// Upload file to TUS server
  ///
  /// Returns the permanent TUS URL
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

      // Convert File to XFile for TusClient
      final xFile = XFile(file.path);

      // Create TUS client with minimal required parameters
      final client = TusClient(
        url: ApiConfig.tusUploadUrl,
        file: xFile,
      );

      // Note: tusc 2.1.0 doesn't support metadata or progress callbacks
      // in the constructor. These features may need to be implemented
      // differently or the package may need to be updated.

      // Start upload and get URL
      await client.start();

      final tusUrl = client.uploadUrl;

      if (tusUrl == null || tusUrl.isEmpty) {
        throw Exception('TUS upload returned empty URL');
      }

      return tusUrl;
    } catch (e) {
      throw Exception('TUS upload failed: $e');
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
          throw Exception('TUS upload failed after $maxRetries attempts: $e');
        }

        // Wait before retry (exponential backoff: 2s, 4s, 8s)
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw lastError ?? Exception('TUS upload failed');
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
}
