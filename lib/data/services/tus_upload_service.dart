import 'dart:io';
import 'package:tus_client/tus_client.dart';
import 'package:path/path.dart' as path;
import '../../core/config/api_config.dart';

/// TUS Upload Service
///
/// Handles resumable file uploads to TUS server.
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
      final client = TusClient(
        Uri.parse(ApiConfig.tusUploadUrl),
        file,
        store: TusMemoryStore(),
      );

      // Set metadata
      client.metadata = {
        'filename': filename,
        'filetype': _getMimeType(filename),
      };

      // Set progress callback
      if (onProgress != null) {
        client.progressCallback = (count, total) {
          final progress = (count / total) * 100;
          onProgress(progress);
        };
      }

      // Upload with retry
      await client.upload();

      // Return the permanent TUS URL
      final tusUrl = client.uploadUrl.toString();

      if (tusUrl.isEmpty) {
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

        // Wait before retry (exponential backoff)
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
