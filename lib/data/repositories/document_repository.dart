import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../services/tus_upload_service.dart';
import '../services/compression_service.dart';
import '../local/hive_service.dart';
import '../models/local_document.dart';
import '../models/local_family_member.dart';
import '../../core/enums/app_enums.dart';

/// Document Repository
///
/// Handles document capture, compression, and upload

class DocumentRepository {
  final TusUploadService _tusService;
  final CompressionService _compressionService;
  final ImagePicker _imagePicker = ImagePicker();

  DocumentRepository(this._tusService, this._compressionService);

  /// Capture photo from camera
  Future<LocalDocument?> capturePhoto({
    required String applicationLocalId,
    required DocumentType docType,
    String? description,
    Function(double)? onUploadProgress,
  }) async {
    try {
      // Capture photo
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (photo == null) return null;

      return await _processAndUploadImage(
        imagePath: photo.path,
        applicationLocalId: applicationLocalId,
        docType: docType,
        description: description,
        onUploadProgress: onUploadProgress,
      );
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Pick photo from gallery
  Future<LocalDocument?> pickPhotoFromGallery({
    required String applicationLocalId,
    required DocumentType docType,
    String? description,
    Function(double)? onUploadProgress,
  }) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo == null) return null;

      return await _processAndUploadImage(
        imagePath: photo.path,
        applicationLocalId: applicationLocalId,
        docType: docType,
        description: description,
        onUploadProgress: onUploadProgress,
      );
    } catch (e) {
      throw Exception('Failed to pick photo: $e');
    }
  }

  /// Pick PDF document
  Future<LocalDocument?> pickPdfDocument({
    required String applicationLocalId,
    required DocumentType docType,
    String? description,
    Function(double)? onUploadProgress,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return null;

      final filePath = result.files.single.path;
      if (filePath == null) return null;

      final file = File(filePath);

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final docDir = Directory('${appDir.path}/app_documents/$applicationLocalId/documents');
      await docDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${docDir.path}/${docType.value}_$timestamp.pdf';
      await file.copy(savedPath);

      final fileSize = await File(savedPath).length();

      // Upload to TUS
      final tusUrl = await _tusService.uploadWithRetry(
        file: File(savedPath),
        filename: '${docType.value}.pdf',
        onProgress: onUploadProgress,
      );

      // Create local document record
      final document = LocalDocument(
        localId: const Uuid().v4(),
        applicationLocalId: applicationLocalId,
        docType: docType.value,
        originalFilePath: savedPath,
        fileName: '${docType.value}.pdf',
        fileSizeOriginal: fileSize,
        mimeType: 'application/pdf',
        description: description,
        tusUrl: tusUrl,
        isUploaded: true,
        uploadedAt: DateTime.now(),
      );

      // Save to Hive
      await HiveService.documentsBox.put(document.localId, document);

      return document;
    } catch (e) {
      throw Exception('Failed to pick PDF: $e');
    }
  }

  /// Process and upload image
  Future<LocalDocument> _processAndUploadImage({
    required String imagePath,
    required String applicationLocalId,
    required DocumentType docType,
    String? description,
    Function(double)? onUploadProgress,
  }) async {
    final originalFile = File(imagePath);

    // Save original to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${appDir.path}/app_documents/$applicationLocalId/documents');
    await docDir.create(recursive: true);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalPath = '${docDir.path}/${docType.value}_${timestamp}_original.jpg';
    await originalFile.copy(originalPath);

    final originalSize = await File(originalPath).length();

    // Compress image
    final compressedFile = docType == DocumentType.aadhaarFront ||
            docType == DocumentType.aadhaarBack
        ? await _compressionService.compressAadhaarPhoto(File(originalPath))
        : await _compressionService.compressDocumentPhoto(File(originalPath));

    final compressedPath = '${docDir.path}/${docType.value}_${timestamp}_compressed.jpg';
    await compressedFile.copy(compressedPath);
    final compressedSize = await File(compressedPath).length();

    // Upload to TUS
    final tusUrl = await _tusService.uploadWithRetry(
      file: File(compressedPath),
      filename: '${docType.value}.jpg',
      onProgress: onUploadProgress,
    );

    // Create local document record
    final document = LocalDocument(
      localId: const Uuid().v4(),
      applicationLocalId: applicationLocalId,
      docType: docType.value,
      originalFilePath: originalPath,
      compressedFilePath: compressedPath,
      fileName: '${docType.value}.jpg',
      fileSizeOriginal: originalSize,
      fileSizeCompressed: compressedSize,
      mimeType: 'image/jpeg',
      description: description,
      tusUrl: tusUrl,
      isUploaded: true,
      uploadedAt: DateTime.now(),
    );

    // Save to Hive
    await HiveService.documentsBox.put(document.localId, document);

    return document;
  }

  /// Capture and upload family member Aadhaar photos
  Future<void> captureFamilyAadhaarPhoto({
    required LocalFamilyMember member,
    required bool isFront,
    Function(double)? onUploadProgress,
  }) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (photo == null) return;

      final originalFile = File(photo.path);

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final memberDir = Directory(
        '${appDir.path}/app_documents/${member.applicationLocalId}/family/${member.localId}',
      );
      await memberDir.create(recursive: true);

      final filename = isFront ? 'aadhaar_front.jpg' : 'aadhaar_back.jpg';
      final savedPath = '${memberDir.path}/$filename';
      await originalFile.copy(savedPath);

      // Compress
      final compressedFile = await _compressionService.compressAadhaarPhoto(
        File(savedPath),
      );

      // Upload to TUS
      final tusUrl = await _tusService.uploadWithRetry(
        file: compressedFile,
        filename: filename,
        onProgress: onUploadProgress,
      );

      // Update member record
      if (isFront) {
        member.uidFrontLocalPath = savedPath;
        member.uidFrontTusUrl = tusUrl;
      } else {
        member.uidBackLocalPath = savedPath;
        member.uidBackTusUrl = tusUrl;
      }

      member.touch();
      await member.save();
    } catch (e) {
      throw Exception('Failed to capture Aadhaar photo: $e');
    }
  }

  /// Delete document
  Future<void> deleteDocument(LocalDocument document) async {
    try {
      // Delete files
      if (document.originalFilePath != null) {
        final originalFile = File(document.originalFilePath!);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
      }

      if (document.compressedFilePath != null) {
        final compressedFile = File(document.compressedFilePath!);
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }
      }

      // Delete from Hive
      await document.delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
