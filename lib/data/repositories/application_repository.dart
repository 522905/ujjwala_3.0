import '../services/api_service.dart';
import '../services/tus_upload_service.dart';
import '../local/hive_service.dart';
import '../models/local_application.dart';
import '../models/local_address.dart';
import '../models/local_family_member.dart';
import '../models/local_document.dart';
import '../../core/config/api_config.dart';

/// Application Repository
///
/// Handles all application-related operations (local + remote)

class ApplicationRepository {
  final ApiService _apiService;
  final TusUploadService _tusService;

  ApplicationRepository(this._apiService, this._tusService);

  /// Submit application to backend
  Future<Map<String, dynamic>> submitApplication(
    LocalApplication application,
  ) async {
    try {
      // Get related data
      final addresses = HiveService.getAddresses(application.localId);
      final familyMembers = HiveService.getFamilyMembers(application.localId);
      final documents = HiveService.getDocuments(application.localId);

      // Validate
      _validateApplication(application, addresses, familyMembers, documents);

      // Ensure all family member photos are uploaded to TUS
      for (var member in familyMembers) {
        if (!member.arePhotosUploaded) {
          throw Exception('Family member ${member.fullName} Aadhaar photos not uploaded');
        }
      }

      // Ensure all documents are uploaded to TUS
      for (var doc in documents) {
        if (!doc.isReadyForSubmission) {
          throw Exception('Document ${doc.docType} not uploaded');
        }
      }

      // Build payload
      final payload = {
        ...application.toServerJson(),
        'addresses': addresses.map((a) => a.toServerJson()).toList(),
        'family_members': familyMembers.map((m) => m.toServerJson()).toList(),
        'documents': documents.map((d) => d.toServerJson()).toList(),
      };

      // Submit to backend
      final response = await _apiService.post(
        ApiConfig.applicationsEndpoint,
        data: payload,
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all applications
  Future<List<Map<String, dynamic>>> getApplications({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        ApiConfig.applicationsEndpoint,
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['results']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get application by ID
  Future<Map<String, dynamic>> getApplicationById(int id) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.applicationsEndpoint}$id/',
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Get generated forms for an application
  Future<List<Map<String, dynamic>>> getApplicationForms(int id) async {
    try {
      final endpoint = ApiConfig.applicationsFormsEndpoint.replaceAll('{id}', id.toString());
      final response = await _apiService.get(endpoint);

      return List<Map<String, dynamic>>.from(response.data['forms']);
    } catch (e) {
      rethrow;
    }
  }

  /// Download form PDF
  Future<void> downloadFormPdf(String pdfUrl, String savePath) async {
    try {
      await _apiService.downloadFile(pdfUrl, savePath);
    } catch (e) {
      rethrow;
    }
  }

  /// Submit signed forms
  Future<Map<String, dynamic>> submitSignedForms({
    required int applicationId,
    required List<Map<String, String>> signedForms,
    String? remarks,
  }) async {
    try {
      final endpoint = ApiConfig.applicationsSubmitFormsEndpoint
          .replaceAll('{id}', applicationId.toString());

      final response = await _apiService.post(
        endpoint,
        data: {
          'signed_forms': signedForms,
          if (remarks != null) 'remarks': remarks,
        },
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate application before submission
  void _validateApplication(
    LocalApplication application,
    List<LocalAddress> addresses,
    List<LocalFamilyMember> familyMembers,
    List<LocalDocument> documents,
  ) {
    // Check addresses
    if (addresses.length < 2) {
      throw Exception('Both Current and Permanent addresses are required');
    }

    final currentAddr = addresses.firstWhere((a) => a.addressType == 'CURRENT');
    final permanentAddr = addresses.firstWhere((a) => a.addressType == 'PERMANENT');

    // Migrant validation
    if (currentAddr.state == permanentAddr.state) {
      throw Exception(
        'For migrant applications, Current and Permanent addresses must be in different states',
      );
    }

    // Check family members
    final selfMembers = familyMembers.where((m) => m.relationToApplicant == 'SELF').toList();
    if (selfMembers.isEmpty) {
      throw Exception('Applicant must be added as SELF family member');
    }

    if (selfMembers.length > 1) {
      throw Exception('Only one SELF member is allowed');
    }

    // Check documents (at least 5 required + applicant photo)
    if (documents.length < 6) {
      throw Exception('All required documents must be uploaded');
    }

    // Check for applicant photo
    final hasApplicantPhoto = documents.any((d) => d.docType == 'APPLICANT_PHOTO');
    if (!hasApplicantPhoto) {
      throw Exception('Applicant photo is mandatory');
    }

    // Check consents
    if (!application.aadhaarConsentSigned ||
        !application.agreesToDbtl ||
        !application.agreesPreInstallationCheck ||
        !application.agreesMandatoryInspections ||
        !application.declaresNoExistingConnection ||
        !application.declaresUseForDomesticCookingOnly ||
        !application.consentDataSharingOmcBank) {
      throw Exception('All consents must be signed');
    }
  }
}
