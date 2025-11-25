import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../core/enums/app_enums.dart';
import '../../data/repositories/document_repository.dart';
import '../../data/services/tus_upload_service.dart';
import '../../data/services/compression_service.dart';
import 'step7_consents_review_screen.dart';

/// Step 6: Documents Upload
///
/// Required Documents (6 total):
/// 1. Applicant Photo (MANDATORY)
/// 2. POI - Proof of Identity
/// 3. POA - Proof of Address
/// 4. Income Certificate
/// 5. Caste Certificate
/// 6. Migration Certificate

class Step6DocumentsScreen extends StatefulWidget {
  const Step6DocumentsScreen({super.key});

  @override
  State<Step6DocumentsScreen> createState() => _Step6DocumentsScreenState();
}

class _Step6DocumentsScreenState extends State<Step6DocumentsScreen> {
  late DocumentRepository _documentRepository;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _documentRepository = DocumentRepository(
      TusUploadService(),
      CompressionService(),
    );
  }

  /// Get list of required documents based on applicant's data
  /// Conditional documents:
  /// - Caste certificate: Only if caste != General
  /// - Migration certificate: Only if permanent_state != current_state
  List<Map<String, dynamic>> _getRequiredDocuments(BuildContext context) {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;
    final currentAddress = appProvider.currentAddress;
    final permanentAddress = appProvider.permanentAddress;

    // Base mandatory documents
    final docs = <Map<String, dynamic>>[
      {
        'type': DocumentType.applicantPhoto,
        'title': 'Applicant Photo',
        'description': 'Recent passport-size photograph',
        'mandatory': true,
      },
      {
        'type': DocumentType.currentAddressPoa,
        'title': 'Current Address Proof',
        'description': 'Proof of current address',
        'mandatory': true,
      },
      {
        'type': DocumentType.permanentAddressPoa,
        'title': 'Permanent Address Proof',
        'description': 'Proof of permanent address',
        'mandatory': true,
      },
      {
        'type': DocumentType.familyCompositionDoc,
        'title': 'Family Composition Document',
        'description': 'Ration card or family certificate',
        'mandatory': true,
      },
    ];

    // Conditional: Caste Certificate (only if caste is not General)
    final caste = app?.caste;
    if (caste != null && caste != 'GENERAL' && caste.toLowerCase() != 'general') {
      docs.add({
        'type': DocumentType.casteCertificate,
        'title': 'Caste Certificate',
        'description': 'SC/ST/OBC certificate (Required for $caste category)',
        'mandatory': true,
        'conditional': true,
      });
    }

    // Conditional: Migration Certificate (only if states are different)
    // NOTE: DocumentType.migrationCertificate doesn't exist in the enum yet.
    // Commenting out until the enum is updated.
    // final currentState = currentAddress?.state;
    // final permanentState = permanentAddress?.state;
    // if (currentState != null &&
    //     permanentState != null &&
    //     currentState != permanentState) {
    //   docs.add({
    //     'type': DocumentType.migrationCertificate,
    //     'title': 'Migration Certificate',
    //     'description':
    //         'Required as permanent state differs from current state',
    //     'mandatory': true,
    //     'conditional': true,
    //   });
    // }

    return docs;
  }

  Future<void> _captureDocument(DocumentType docType) async {
    if (_isUploading) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Choose upload method'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'camera'),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    setState(() => _isUploading = true);

    try {
      final appProvider =
          Provider.of<ApplicationProvider>(context, listen: false);
      final app = appProvider.currentApplication;

      if (app == null) {
        throw Exception('No active application');
      }

      final document = choice == 'camera'
          ? await _documentRepository.capturePhoto(
              applicationLocalId: app.localId,
              docType: docType,
            )
          : await _documentRepository.pickPhotoFromGallery(
              applicationLocalId: app.localId,
              docType: docType,
            );

      if (document != null) {
        await appProvider.addDocument(document);
      } else {
        throw Exception('Document capture was cancelled');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${docType.display} uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  bool _isDocumentUploaded(
      List<dynamic> documents, DocumentType docType) {
    return documents.any((doc) => doc.docType == docType.value && doc.isUploaded);
  }

  void _proceedToNextStep() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final documents = appProvider.documents;
    final requiredDocs = _getRequiredDocuments(context);

    // Check if all mandatory documents are uploaded
    final missingDocs = requiredDocs
        .where((doc) =>
            doc['mandatory'] &&
            !_isDocumentUploaded(documents, doc['type']))
        .map((doc) => doc['title'])
        .toList();

    if (missingDocs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Missing: ${missingDocs.join(', ')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step7ConsentsReviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 6: Documents'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 6 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: Consumer<ApplicationProvider>(
                builder: (context, appProvider, _) {
                  final documents = appProvider.documents;
                  final requiredDocs = _getRequiredDocuments(context);
                  final mandatoryCount = requiredDocs.where((d) => d['mandatory']).length;
                  final uploadedMandatoryCount = requiredDocs
                      .where((d) =>
                          d['mandatory'] &&
                          _isDocumentUploaded(documents, d['type']))
                      .length;

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Documents',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Step 6 of 7 • $uploadedMandatoryCount/$mandatoryCount uploaded',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.h),

                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue[700]),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        'Document requirements are based on your application details. Photos will be compressed and uploaded securely.',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Document upload cards
                              ...requiredDocs.map((doc) {
                                final isUploaded = _isDocumentUploaded(
                                    documents, doc['type']);
                                final isConditional = doc['conditional'] == true;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isUploaded
                                          ? Colors.green
                                          : isConditional
                                              ? Colors.orange[300]!
                                              : Colors.grey[300]!,
                                      width: isUploaded ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: isConditional && !isUploaded
                                        ? Colors.orange[50]
                                        : null,
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16.w),
                                    leading: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: isUploaded
                                            ? Colors.green[50]
                                            : isConditional
                                                ? Colors.orange[50]
                                                : Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        isUploaded
                                            ? Icons.check_circle
                                            : isConditional
                                                ? Icons.info
                                                : Icons.upload_file,
                                        color: isUploaded
                                            ? Colors.green
                                            : isConditional
                                                ? Colors.orange[700]
                                                : Colors.grey[600],
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            doc['title'],
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isConditional)
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8.w,
                                              vertical: 4.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[100],
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              'CONDITIONAL',
                                              style: TextStyle(
                                                fontSize: 9.sp,
                                                color: Colors.orange[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4.h),
                                        Text(
                                          doc['description'],
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (doc['mandatory']) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            'MANDATORY',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: _isUploading
                                          ? null
                                          : () => _captureDocument(doc['type']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isUploaded
                                            ? Colors.green
                                            : Colors.blue[700],
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                          isUploaded ? 'Re-upload' : 'Upload'),
                                    ),
                                  ),
                                );
                              }),

                              if (_isUploading) ...[
                                SizedBox(height: 16.h),
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                SizedBox(height: 8.h),
                                Center(
                                  child: Text(
                                    'Compressing and uploading...',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Navigation Buttons
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(color: Colors.blue[700]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isUploading
                                    ? null
                                    : _proceedToNextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                ),
                                child: const Text('Next: Review & Submit'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
