import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/local/hive_service.dart';
import '../data/models/local_application.dart';
import '../data/models/local_address.dart';
import '../data/models/local_family_member.dart';
import '../data/models/local_document.dart';

/// Application Provider
///
/// Manages current draft application state

class ApplicationProvider extends ChangeNotifier {
  LocalApplication? _currentApplication;
  List<LocalAddress> _addresses = [];
  List<LocalFamilyMember> _familyMembers = [];
  List<LocalDocument> _documents = [];

  LocalApplication? get currentApplication => _currentApplication;
  List<LocalAddress> get addresses => _addresses;
  List<LocalFamilyMember> get familyMembers => _familyMembers;
  List<LocalDocument> get documents => _documents;

  int get completionPercentage => _currentApplication?.completionPercentage ?? 0;
  bool get isComplete => _currentApplication?.isComplete ?? false;

  /// Load application by ID
  Future<void> loadApplication(String localId) async {
    _currentApplication = HiveService.getApplication(localId);

    if (_currentApplication != null) {
      _addresses = HiveService.getAddresses(localId);
      _familyMembers = HiveService.getFamilyMembers(localId);
      _documents = HiveService.getDocuments(localId);
    }

    notifyListeners();
  }

  /// Create new application
  Future<void> createNewApplication() async {
    final newApp = LocalApplication(
      localId: const Uuid().v4(),
      localStatus: 'draft',
    );

    await HiveService.applicationsBox.put(newApp.localId, newApp);

    _currentApplication = newApp;
    _addresses = [];
    _familyMembers = [];
    _documents = [];

    notifyListeners();
  }

  /// Update applicant field
  Future<void> updateApplicantField(String field, dynamic value) async {
    if (_currentApplication == null) return;

    switch (field) {
      case 'applicant_full_name':
        _currentApplication!.applicantFullName = value;
        break;
      case 'applicant_first_name':
        _currentApplication!.applicantFirstName = value;
        break;
      case 'applicant_middle_name':
        _currentApplication!.applicantMiddleName = value;
        break;
      case 'applicant_last_name':
        _currentApplication!.applicantLastName = value;
        break;
      case 'applicant_gender':
        _currentApplication!.applicantGender = value;
        break;
      case 'applicant_dob':
        _currentApplication!.applicantDob = value;
        break;
      case 'applicant_aadhaar':
        _currentApplication!.applicantAadhaar = value;
        break;
      case 'applicant_mobile':
        _currentApplication!.applicantMobile = value;
        break;
      case 'applicant_email':
        _currentApplication!.applicantEmail = value;
        break;
      case 'caste':
        _currentApplication!.caste = value;
        break;
      case 'marital_status':
        _currentApplication!.maritalStatus = value;
        break;
      case 'marriage_date':
        _currentApplication!.marriageDate = value;
        break;
    }

    _currentApplication!.touch();
    await _currentApplication!.save();
    notifyListeners();
  }

  /// Update bank details
  Future<void> updateBankField(String field, dynamic value) async {
    if (_currentApplication == null) return;

    switch (field) {
      case 'bank_account_name':
        _currentApplication!.bankAccountName = value;
        break;
      case 'bank_name':
        _currentApplication!.bankName = value;
        break;
      case 'bank_branch':
        _currentApplication!.bankBranch = value;
        break;
      case 'bank_ifsc':
        _currentApplication!.bankIfsc = value;
        break;
      case 'bank_account_number':
        _currentApplication!.bankAccountNumber = value;
        break;
    }

    _currentApplication!.touch();
    await _currentApplication!.save();
    notifyListeners();
  }

  /// Update LPG connection type
  Future<void> updateLpgType(String lpgType) async {
    if (_currentApplication == null) return;

    _currentApplication!.lpgConnectionType = lpgType;
    _currentApplication!.touch();
    await _currentApplication!.save();
    notifyListeners();
  }

  /// Update location
  Future<void> updateLocation({
    required String latitude,
    required String longitude,
    required String accuracy,
  }) async {
    if (_currentApplication == null) return;

    _currentApplication!.latitude = latitude;
    _currentApplication!.longitude = longitude;
    _currentApplication!.accuracy = accuracy;
    _currentApplication!.touch();
    await _currentApplication!.save();
    notifyListeners();
  }

  /// Add or update address
  Future<void> saveAddress(LocalAddress address) async {
    address.touch();
    await HiveService.addressesBox.put(address.localId, address);

    // Add to application's address list if not already present
    if (_currentApplication != null &&
        !_currentApplication!.addressIds.contains(address.localId)) {
      _currentApplication!.addressIds.add(address.localId);
      _currentApplication!.touch();
      await _currentApplication!.save();
    }

    // Reload addresses
    if (_currentApplication != null) {
      _addresses = HiveService.getAddresses(_currentApplication!.localId);
    }

    notifyListeners();
  }

  /// Get current address
  LocalAddress? get currentAddress {
    try {
      return _addresses.firstWhere((a) => a.addressType == 'CURRENT');
    } catch (e) {
      return null;
    }
  }

  /// Get permanent address
  LocalAddress? get permanentAddress {
    try {
      return _addresses.firstWhere((a) => a.addressType == 'PERMANENT');
    } catch (e) {
      return null;
    }
  }

  /// Add or update family member
  Future<void> saveFamilyMember(LocalFamilyMember member) async {
    member.touch();
    await HiveService.familyMembersBox.put(member.localId, member);

    // Add to application's family member list if not already present
    if (_currentApplication != null &&
        !_currentApplication!.familyMemberIds.contains(member.localId)) {
      _currentApplication!.familyMemberIds.add(member.localId);
      _currentApplication!.touch();
      await _currentApplication!.save();
    }

    // Reload family members
    if (_currentApplication != null) {
      _familyMembers = HiveService.getFamilyMembers(_currentApplication!.localId);
    }

    notifyListeners();
  }

  /// Delete family member
  Future<void> deleteFamilyMember(String memberId) async {
    await HiveService.familyMembersBox.delete(memberId);

    if (_currentApplication != null) {
      _currentApplication!.familyMemberIds.remove(memberId);
      _currentApplication!.touch();
      await _currentApplication!.save();
      _familyMembers = HiveService.getFamilyMembers(_currentApplication!.localId);
    }

    notifyListeners();
  }

  /// Add document
  Future<void> addDocument(LocalDocument document) async {
    await HiveService.documentsBox.put(document.localId, document);

    // Add to application's document list if not already present
    if (_currentApplication != null &&
        !_currentApplication!.documentIds.contains(document.localId)) {
      _currentApplication!.documentIds.add(document.localId);
      _currentApplication!.touch();
      await _currentApplication!.save();
    }

    // Reload documents
    if (_currentApplication != null) {
      _documents = HiveService.getDocuments(_currentApplication!.localId);
    }

    notifyListeners();
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    await HiveService.documentsBox.delete(documentId);

    if (_currentApplication != null) {
      _currentApplication!.documentIds.remove(documentId);
      _currentApplication!.touch();
      await _currentApplication!.save();
      _documents = HiveService.getDocuments(_currentApplication!.localId);
    }

    notifyListeners();
  }

  /// Update consent
  Future<void> updateConsent(String consentField, bool value) async {
    if (_currentApplication == null) return;

    switch (consentField) {
      case 'aadhaar_consent':
        _currentApplication!.aadhaarConsentSigned = value;
        break;
      case 'dbtl':
        _currentApplication!.agreesToDbtl = value;
        break;
      case 'pre_installation':
        _currentApplication!.agreesPreInstallationCheck = value;
        break;
      case 'mandatory_inspections':
        _currentApplication!.agreesMandatoryInspections = value;
        break;
      case 'no_existing_connection':
        _currentApplication!.declaresNoExistingConnection = value;
        break;
      case 'domestic_cooking':
        _currentApplication!.declaresUseForDomesticCookingOnly = value;
        break;
      case 'data_sharing':
        _currentApplication!.consentDataSharingOmcBank = value;
        break;
    }

    _currentApplication!.touch();
    await _currentApplication!.save();
    notifyListeners();
  }

  /// Clear current application
  void clearCurrentApplication() {
    _currentApplication = null;
    _addresses = [];
    _familyMembers = [];
    _documents = [];
    notifyListeners();
  }
}
