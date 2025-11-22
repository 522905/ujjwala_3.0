import 'package:flutter/material.dart';
import '../data/repositories/application_repository.dart';
import '../data/local/hive_service.dart';
import '../data/models/local_application.dart';

/// Submission Provider
///
/// Manages application submission flow with progress tracking

class SubmissionProvider extends ChangeNotifier {
  final ApplicationRepository _applicationRepository;

  SubmissionProvider(this._applicationRepository);

  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String _currentStep = '';
  String? _errorMessage;
  String? _submittedApplicationNumber;
  int? _submittedApplicationId;

  bool get isSubmitting => _isSubmitting;
  double get uploadProgress => _uploadProgress;
  String get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  String? get submittedApplicationNumber => _submittedApplicationNumber;
  int? get submittedApplicationId => _submittedApplicationId;

  /// Submit application
  Future<bool> submitApplication(LocalApplication application) async {
    try {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _submittedApplicationNumber = null;
      _submittedApplicationId = null;
      notifyListeners();

      // Step 1: Validate
      _currentStep = 'Validating application...';
      _uploadProgress = 0.1;
      notifyListeners();

      if (!application.isComplete) {
        throw Exception('Application is not complete');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Check uploads
      _currentStep = 'Checking document uploads...';
      _uploadProgress = 0.2;
      notifyListeners();

      final familyMembers = HiveService.getFamilyMembers(application.localId);
      final documents = HiveService.getDocuments(application.localId);

      // Verify family member photos
      for (var member in familyMembers) {
        if (!member.arePhotosUploaded) {
          throw Exception(
            'Family member ${member.fullName} Aadhaar photos not uploaded',
          );
        }
      }

      // Verify documents
      for (var doc in documents) {
        if (!doc.isReadyForSubmission) {
          throw Exception('Document ${doc.docType} not uploaded');
        }
      }

      _uploadProgress = 0.4;
      notifyListeners();

      // Step 3: Submit to backend
      _currentStep = 'Submitting application...';
      _uploadProgress = 0.6;
      notifyListeners();

      final response = await _applicationRepository.submitApplication(application);

      _uploadProgress = 0.9;
      notifyListeners();

      // Step 4: Update local status
      _currentStep = 'Finalizing...';
      application.localStatus = 'submitted';
      application.submittedApplicationNumber = response['application_number'];
      application.serverApplicationId = response['id'];
      application.submittedAt = DateTime.now();
      application.touch();
      await application.save();

      _submittedApplicationNumber = response['application_number'];
      _submittedApplicationId = response['id'];

      _uploadProgress = 1.0;
      _currentStep = 'Success!';
      _isSubmitting = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString();
      _currentStep = 'Failed';
      notifyListeners();
      return false;
    }
  }

  /// Reset submission state
  void reset() {
    _isSubmitting = false;
    _uploadProgress = 0.0;
    _currentStep = '';
    _errorMessage = null;
    _submittedApplicationNumber = null;
    _submittedApplicationId = null;
    notifyListeners();
  }

  /// Update progress (called by upload service)
  void updateProgress(double progress, String step) {
    _uploadProgress = progress;
    _currentStep = step;
    notifyListeners();
  }
}
