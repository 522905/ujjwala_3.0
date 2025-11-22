import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/config/api_config.dart';

/// Image Compression Service
///
/// Compresses images before upload to reduce file size.
/// Target: ≤1MB per image

class CompressionService {
  /// Compress image with specified quality
  ///
  /// Returns compressed file
  Future<File> compressImage({
    required File originalFile,
    int quality = 90,
    int maxWidth = 2048,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(
        dir.path,
        'compressed_$timestamp.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxWidth,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw Exception('Image compression failed');
      }

      return File(result.path);
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Compress Aadhaar photo (higher quality)
  Future<File> compressAadhaarPhoto(File originalFile) async {
    return await compressImage(
      originalFile: originalFile,
      quality: ApiConfig.aadhaarImageQuality,
      maxWidth: ApiConfig.maxAadhaarImageWidth,
    );
  }

  /// Compress document photo (standard quality)
  Future<File> compressDocumentPhoto(File originalFile) async {
    return await compressImage(
      originalFile: originalFile,
      quality: ApiConfig.documentImageQuality,
      maxWidth: ApiConfig.maxImageWidth,
    );
  }

  /// Compress until file size is below target
  Future<File> compressToTargetSize({
    required File originalFile,
    int targetSizeBytes = 1024 * 1024, // 1MB default
    int maxAttempts = 5,
  }) async {
    int quality = 90;
    int attempt = 0;
    File? compressedFile;

    while (attempt < maxAttempts) {
      compressedFile = await compressImage(
        originalFile: originalFile,
        quality: quality,
      );

      final size = await compressedFile.length();

      if (size <= targetSizeBytes) {
        return compressedFile;
      }

      // Reduce quality for next attempt
      quality -= 10;
      attempt++;

      if (quality < 50) {
        quality = 50; // Don't go below 50% quality
        break;
      }
    }

    return compressedFile ?? originalFile;
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Get file size in MB
  Future<double> getFileSizeMB(File file) async {
    final bytes = await getFileSize(file);
    return bytes / (1024 * 1024);
  }

  /// Check if compression is needed (file > 1MB)
  Future<bool> needsCompression(File file) async {
    final size = await getFileSize(file);
    return size > 1048576; // 1MB in bytes
  }

  /// Get compression stats
  Future<Map<String, dynamic>> getCompressionStats({
    required File originalFile,
    required File compressedFile,
  }) async {
    final originalSize = await getFileSize(originalFile);
    final compressedSize = await getFileSize(compressedFile);
    final reduction = ((originalSize - compressedSize) / originalSize * 100);

    return {
      'original_size_bytes': originalSize,
      'compressed_size_bytes': compressedSize,
      'original_size_mb': originalSize / (1024 * 1024),
      'compressed_size_mb': compressedSize / (1024 * 1024),
      'reduction_percentage': reduction.toStringAsFixed(1),
    };
  }

  /// Validate image file
  Future<bool> isValidImage(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }

      final extension = path.extension(file.path).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png'];

      return validExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }
}
