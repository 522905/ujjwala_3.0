import 'package:hive/hive.dart';

part 'local_application.g.dart';

/// Local Application Model
///
/// Stores draft application data in Hive database.
/// This model represents the complete application that will be submitted to the backend.

@HiveType(typeId: 0)
class LocalApplication extends HiveObject {
  @HiveField(0)
  String localId;

  @HiveField(1)
  String localStatus; // draft, submitting, submitted, failed

  // Applicant Details
  @HiveField(2)
  String? applicantFullName;

  @HiveField(3)
  String? applicantFirstName;

  @HiveField(4)
  String? applicantMiddleName;

  @HiveField(5)
  String? applicantLastName;

  @HiveField(6)
  String? applicantGender; // M, F, O

  @HiveField(7)
  DateTime? applicantDob;

  @HiveField(8)
  String? applicantAadhaar;

  @HiveField(9)
  String? applicantMobile;

  @HiveField(10)
  String? applicantEmail;

  @HiveField(11)
  String? caste;

  @HiveField(12)
  String? maritalStatus;

  @HiveField(13)
  DateTime? marriageDate;

  // Bank Details
  @HiveField(20)
  String? bankAccountName;

  @HiveField(21)
  String? bankName;

  @HiveField(22)
  String? bankBranch;

  @HiveField(23)
  String? bankIfsc;

  @HiveField(24)
  String? bankAccountNumber;

  // LPG Details
  @HiveField(30)
  String? lpgConnectionType;

  // Location
  @HiveField(50)
  String? latitude;

  @HiveField(51)
  String? longitude;

  @HiveField(52)
  String? accuracy;

  // Nested Data IDs (references to other Hive objects)
  @HiveField(60)
  List<String> addressIds; // References to LocalAddress

  @HiveField(61)
  List<String> familyMemberIds; // References to LocalFamilyMember

  @HiveField(62)
  List<String> documentIds; // References to LocalDocument

  // Consents (all must be true to submit)
  @HiveField(70)
  bool aadhaarConsentSigned;

  @HiveField(71)
  bool agreesToDbtl;

  @HiveField(72)
  bool agreesPreInstallationCheck;

  @HiveField(73)
  bool agreesMandatoryInspections;

  @HiveField(74)
  bool declaresNoExistingConnection;

  @HiveField(75)
  bool declaresUseForDomesticCookingOnly;

  @HiveField(76)
  bool consentDataSharingOmcBank;

  // Metadata
  @HiveField(80)
  DateTime createdAt;

  @HiveField(81)
  DateTime updatedAt;

  @HiveField(82)
  String? submittedApplicationNumber;

  @HiveField(83)
  DateTime? submittedAt;

  @HiveField(84)
  String? submissionErrorMessage;

  @HiveField(85)
  int submissionRetryCount;

  @HiveField(86)
  int? serverApplicationId; // ID from backend after submission

  LocalApplication({
    required this.localId,
    this.localStatus = 'draft',
    this.applicantFullName,
    this.applicantFirstName,
    this.applicantMiddleName,
    this.applicantLastName,
    this.applicantGender,
    this.applicantDob,
    this.applicantAadhaar,
    this.applicantMobile,
    this.applicantEmail,
    this.caste,
    this.maritalStatus,
    this.marriageDate,
    this.bankAccountName,
    this.bankName,
    this.bankBranch,
    this.bankIfsc,
    this.bankAccountNumber,
    this.lpgConnectionType,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.addressIds = const [],
    this.familyMemberIds = const [],
    this.documentIds = const [],
    this.aadhaarConsentSigned = false,
    this.agreesToDbtl = false,
    this.agreesPreInstallationCheck = false,
    this.agreesMandatoryInspections = false,
    this.declaresNoExistingConnection = false,
    this.declaresUseForDomesticCookingOnly = false,
    this.consentDataSharingOmcBank = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.submittedApplicationNumber,
    this.submittedAt,
    this.submissionErrorMessage,
    this.submissionRetryCount = 0,
    this.serverApplicationId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON for server submission
  Map<String, dynamic> toServerJson() {
    return {
      'applicant_full_name': applicantFullName,
      'applicant_first_name': applicantFirstName,
      'applicant_middle_name': applicantMiddleName,
      'applicant_last_name': applicantLastName,
      'applicant_gender': applicantGender,
      'applicant_dob': applicantDob?.toIso8601String().split('T')[0],
      'applicant_aadhaar_number': applicantAadhaar,
      'applicant_mobile': applicantMobile,
      'applicant_email': applicantEmail,
      'caste': caste,
      'is_migrant': true, // Always true for Ujjwala V3
      'marital_status': maritalStatus,
      'marriage_date': marriageDate?.toIso8601String().split('T')[0],
      'bank_account_name': bankAccountName,
      'bank_name': bankName,
      'bank_branch': bankBranch,
      'bank_ifsc': bankIfsc,
      'bank_account_number': bankAccountNumber,
      'lpg_connection_type': lpgConnectionType,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      // Consents
      'aadhaar_consent_signed': aadhaarConsentSigned,
      'agrees_to_dbtl': agreesToDbtl,
      'agrees_pre_installation_check': agreesPreInstallationCheck,
      'agrees_mandatory_inspections': agreesMandatoryInspections,
      'declares_no_existing_lpg_or_png_connection': declaresNoExistingConnection,
      'declares_use_for_domestic_cooking_only': declaresUseForDomesticCookingOnly,
      'consent_data_sharing_omc_bank': consentDataSharingOmcBank,
    };
  }

  /// Check if application is complete and ready for submission
  bool get isComplete {
    // Applicant details
    if (applicantFullName == null || applicantFullName!.isEmpty) return false;
    if (applicantGender != 'F') return false; // Must be female
    if (applicantDob == null) return false;
    if (applicantAadhaar == null || applicantAadhaar!.length != 12) return false;
    if (applicantMobile == null || applicantMobile!.length != 10) return false;
    if (caste == null) return false;

    // Bank details
    if (bankAccountName == null || bankAccountName!.isEmpty) return false;
    if (bankName == null || bankName!.isEmpty) return false;
    if (bankIfsc == null || bankIfsc!.length != 11) return false;
    if (bankAccountNumber == null || bankAccountNumber!.isEmpty) return false;

    // LPG type
    if (lpgConnectionType == null) return false;

    // Addresses (need 2: CURRENT and PERMANENT in different states)
    if (addressIds.length < 2) return false;

    // Family members (at least 1: SELF)
    if (familyMemberIds.isEmpty) return false;

    // Documents (at least 5 required + applicant photo)
    if (documentIds.length < 6) return false;

    // All consents must be true
    if (!aadhaarConsentSigned ||
        !agreesToDbtl ||
        !agreesPreInstallationCheck ||
        !agreesMandatoryInspections ||
        !declaresNoExistingConnection ||
        !declaresUseForDomesticCookingOnly ||
        !consentDataSharingOmcBank) {
      return false;
    }

    return true;
  }

  /// Get completion percentage (0-100)
  int get completionPercentage {
    int completed = 0;
    const int total = 50; // Approximate total required items

    // Applicant details (weight: 15)
    if (applicantFullName != null && applicantFullName!.isNotEmpty) completed += 2;
    if (applicantGender == 'F') completed += 2;
    if (applicantDob != null) completed += 2;
    if (applicantAadhaar != null && applicantAadhaar!.length == 12) completed += 2;
    if (applicantMobile != null && applicantMobile!.length == 10) completed += 2;
    if (caste != null) completed += 2;
    if (maritalStatus != null) completed += 1;
    if (applicantEmail != null && applicantEmail!.isNotEmpty) completed += 1;
    if (applicantFirstName != null) completed += 1;

    // Bank details (weight: 8)
    if (bankAccountName != null && bankAccountName!.isNotEmpty) completed += 2;
    if (bankName != null && bankName!.isNotEmpty) completed += 2;
    if (bankIfsc != null && bankIfsc!.length == 11) completed += 2;
    if (bankAccountNumber != null && bankAccountNumber!.isNotEmpty) completed += 2;

    // LPG type (weight: 2)
    if (lpgConnectionType != null) completed += 2;

    // Addresses (weight: 10)
    completed += (addressIds.length >= 2) ? 10 : (addressIds.length * 5);

    // Family members (weight: 5)
    completed += familyMemberIds.isNotEmpty ? 5 : 0;

    // Documents (weight: 10)
    completed += (documentIds.length >= 6) ? 10 : (documentIds.length * 1.5).round();

    // Consents (weight: 7)
    int consentCount = 0;
    if (aadhaarConsentSigned) consentCount++;
    if (agreesToDbtl) consentCount++;
    if (agreesPreInstallationCheck) consentCount++;
    if (agreesMandatoryInspections) consentCount++;
    if (declaresNoExistingConnection) consentCount++;
    if (declaresUseForDomesticCookingOnly) consentCount++;
    if (consentDataSharingOmcBank) consentCount++;
    completed += consentCount;

    return ((completed / total) * 100).clamp(0, 100).toInt();
  }

  /// Update timestamp
  void touch() {
    updatedAt = DateTime.now();
  }
}
