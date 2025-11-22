import 'package:hive/hive.dart';

part 'local_family_member.g.dart';

/// Local Family Member Model
///
/// Stores family member data with Aadhaar photo references (TUS URLs).

@HiveType(typeId: 2)
class LocalFamilyMember extends HiveObject {
  @HiveField(0)
  String localId;

  @HiveField(1)
  String applicationLocalId; // Reference to parent application

  @HiveField(2)
  String? fullName;

  @HiveField(3)
  String? relationToApplicant; // SELF, HUSBAND, WIFE, etc.

  @HiveField(4)
  String? gender; // M, F, O

  @HiveField(5)
  DateTime? dob;

  @HiveField(6)
  String? aadhaarNumber;

  @HiveField(7)
  String? uidFrontLocalPath; // Local file path for front Aadhaar photo

  @HiveField(8)
  String? uidBackLocalPath; // Local file path for back Aadhaar photo

  @HiveField(9)
  String? uidFrontTusUrl; // TUS URL after upload (front)

  @HiveField(10)
  String? uidBackTusUrl; // TUS URL after upload (back)

  @HiveField(11)
  bool rationCardAvailable;

  @HiveField(12)
  DateTime createdAt;

  @HiveField(13)
  DateTime updatedAt;

  LocalFamilyMember({
    required this.localId,
    required this.applicationLocalId,
    this.fullName,
    this.relationToApplicant,
    this.gender,
    this.dob,
    this.aadhaarNumber,
    this.uidFrontLocalPath,
    this.uidBackLocalPath,
    this.uidFrontTusUrl,
    this.uidBackTusUrl,
    this.rationCardAvailable = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for server submission
  Map<String, dynamic> toServerJson() {
    return {
      'full_name': fullName,
      'relation_to_applicant': relationToApplicant,
      'gender': gender,
      'dob': dob?.toIso8601String().split('T')[0],
      'aadhaar_number': aadhaarNumber,
      'uid_front_link': uidFrontTusUrl, // TUS URL
      'uid_back_link': uidBackTusUrl, // TUS URL
      'ration_card_available': rationCardAvailable,
    };
  }

  /// Check if family member data is complete
  bool get isComplete {
    if (fullName == null || fullName!.isEmpty) return false;
    if (relationToApplicant == null) return false;
    if (gender == null) return false;
    if (dob == null) return false;
    if (aadhaarNumber == null || aadhaarNumber!.length != 12) return false;

    // Both Aadhaar photos must be present (either local paths or TUS URLs)
    final hasFrontPhoto = (uidFrontLocalPath != null && uidFrontLocalPath!.isNotEmpty) ||
        (uidFrontTusUrl != null && uidFrontTusUrl!.isNotEmpty);

    final hasBackPhoto = (uidBackLocalPath != null && uidBackLocalPath!.isNotEmpty) ||
        (uidBackTusUrl != null && uidBackTusUrl!.isNotEmpty);

    if (!hasFrontPhoto || !hasBackPhoto) return false;

    return true;
  }

  /// Check if photos are uploaded to TUS
  bool get arePhotosUploaded {
    return uidFrontTusUrl != null &&
        uidFrontTusUrl!.isNotEmpty &&
        uidBackTusUrl != null &&
        uidBackTusUrl!.isNotEmpty;
  }

  /// Check if this is the SELF member (applicant)
  bool get isSelf {
    return relationToApplicant == 'SELF';
  }

  /// Get age from date of birth
  int? get age {
    if (dob == null) return null;

    final today = DateTime.now();
    int age = today.year - dob!.year;

    if (today.month < dob!.month || (today.month == dob!.month && today.day < dob!.day)) {
      age--;
    }

    return age;
  }

  /// Update timestamp
  void touch() {
    updatedAt = DateTime.now();
  }
}
