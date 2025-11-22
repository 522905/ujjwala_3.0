import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../core/enums/app_enums.dart';
import '../../data/repositories/document_repository.dart';
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
    _documentRepository = DocumentRepository();
  }

  // Required documents
  final List<Map<String, dynamic>> _requiredDocs = [
    {
      'type': DocumentType.applicantPhoto,
      'title': 'Applicant Photo',
      'description': 'Recent passport-size photograph',
      'mandatory': true,
    },
    {
      'type': DocumentType.proofOfIdentity,
      'title': 'Proof of Identity',
      'description': 'Aadhaar Card, Voter ID, or Passport',
      'mandatory': true,
    },
    {
      'type': DocumentType.proofOfAddress,
      'title': 'Proof of Address',
      'description': 'Ration Card, Electricity Bill, or Rent Agreement',
      'mandatory': true,
    },
    {
      'type': DocumentType.incomeCertificate,
      'title': 'Income Certificate',
      'description': 'Issued by competent authority',
      'mandatory': true,
    },
    {
      'type': DocumentType.casteCertificate,
      'title': 'Caste Certificate',
      'description': 'SC/ST/OBC certificate',
      'mandatory': true,
    },
    {
      'type': DocumentType.migrationCertificate,
      'title': 'Migration Certificate',
      'description': 'Proof of migration from another state',
      'mandatory': true,
    },
  ];

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

      await appProvider.addDocument(document);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${docType.name} uploaded successfully'),
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
    return documents.any((doc) => doc.docType == docType && doc.isUploaded);
  }

  void _proceedToNextStep() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final documents = appProvider.documents;

    // Check if all mandatory documents are uploaded
    final missingDocs = _requiredDocs
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
                                'Step 6 of 7 • ${documents.length}/6 uploaded',
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
                                        'All documents are mandatory. Photos will be compressed and uploaded securely.',
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
                              ..._requiredDocs.map((doc) {
                                final isUploaded = _isDocumentUploaded(
                                    documents, doc['type']);

                                return Container(
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isUploaded
                                          ? Colors.green
                                          : Colors.grey[300]!,
                                      width: isUploaded ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(16.w),
                                    leading: Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: isUploaded
                                            ? Colors.green[50]
                                            : Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        isUploaded
                                            ? Icons.check_circle
                                            : Icons.upload_file,
                                        color: isUploaded
                                            ? Colors.green
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    title: Text(
                                      doc['title'],
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
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
