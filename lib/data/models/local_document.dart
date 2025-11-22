import 'package:hive/hive.dart';

part 'local_document.g.dart';

/// Local Document Model
///
/// Stores document metadata with local file paths and TUS URLs.

@HiveType(typeId: 3)
class LocalDocument extends HiveObject {
  @HiveField(0)
  String localId;

  @HiveField(1)
  String applicationLocalId; // Reference to parent application

  @HiveField(2)
  String docType; // Document type (e.g., CURRENT_ADDRESS_POA, BANK_PROOF)

  @HiveField(3)
  String? originalFilePath; // Local file path (original quality)

  @HiveField(4)
  String? compressedFilePath; // Local file path (compressed for upload)

  @HiveField(5)
  String? fileName;

  @HiveField(6)
  int? fileSizeOriginal; // File size in bytes (original)

  @HiveField(7)
  int? fileSizeCompressed; // File size in bytes (compressed)

  @HiveField(8)
  String? mimeType; // e.g., image/jpeg, application/pdf

  @HiveField(9)
  String? description;

  @HiveField(10)
  DateTime capturedAt;

  @HiveField(11)
  String? tusUrl; // TUS URL after successful upload

  @HiveField(12)
  bool isUploaded;

  @HiveField(13)
  DateTime? uploadedAt;

  @HiveField(14)
  DateTime updatedAt;

  LocalDocument({
    required this.localId,
    required this.applicationLocalId,
    required this.docType,
    this.originalFilePath,
    this.compressedFilePath,
    this.fileName,
    this.fileSizeOriginal,
    this.fileSizeCompressed,
    this.mimeType,
    this.description,
    DateTime? capturedAt,
    this.tusUrl,
    this.isUploaded = false,
    this.uploadedAt,
    DateTime? updatedAt,
  })  : capturedAt = capturedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for server submission
  Map<String, dynamic> toServerJson() {
    return {
      'doc_type': docType,
      'tus_url': tusUrl,
      'file_name': fileName,
      'file_size': fileSizeCompressed ?? fileSizeOriginal,
      'mime_type': mimeType,
      'description': description,
    };
  }

  /// Get file path for display (original quality)
  String? get displayFilePath => originalFilePath;

  /// Get file path for upload (compressed if available, otherwise original)
  String? get uploadFilePath => compressedFilePath ?? originalFilePath;

  /// Get file size for upload
  int get uploadFileSize => fileSizeCompressed ?? fileSizeOriginal ?? 0;

  /// Check if file is image
  bool get isImage {
    return mimeType?.startsWith('image/') ?? false;
  }

  /// Check if file is PDF
  bool get isPdf {
    return mimeType == 'application/pdf';
  }

  /// Check if document is ready for submission
  bool get isReadyForSubmission {
    return isUploaded && tusUrl != null && tusUrl!.isNotEmpty;
  }

  /// Get file size in MB
  double get fileSizeMB {
    final sizeInBytes = fileSizeCompressed ?? fileSizeOriginal ?? 0;
    return sizeInBytes / (1024 * 1024);
  }

  /// Update timestamp
  void touch() {
    updatedAt = DateTime.now();
  }
}
