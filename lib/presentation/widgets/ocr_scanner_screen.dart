import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../data/services/tus_upload_service.dart';

/// OCR Scanner Screen
///
/// Reusable screen for scanning documents with OCR
/// Supports: Aadhaar Card, Bank Passbook, etc.

enum OcrType {
  aadhaar,
  bankPassbook,
}

class OcrScannerScreen extends StatefulWidget {
  final OcrType ocrType;
  final String title;
  final String subtitle;

  const OcrScannerScreen({
    super.key,
    required this.ocrType,
    required this.title,
    this.subtitle = 'Capture or select images to extract details',
  });

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  // Image files
  File? _frontImage;
  File? _backImage;
  File? _singleImage; // For documents that need only one image

  // Processing state
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  bool get _requiresTwoImages => widget.ocrType == OcrType.aadhaar;
  bool get _canProcess {
    if (_requiresTwoImages) {
      return _frontImage != null && _backImage != null;
    } else {
      return _singleImage != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.h),

            // Image capture area
            if (_requiresTwoImages) ...[
              _buildImageCaptureCard(
                title: 'Front Side',
                image: _frontImage,
                onCamera: () => _captureImage(true),
                onGallery: () => _pickImage(true),
              ),
              SizedBox(height: 16.h),
              _buildImageCaptureCard(
                title: 'Back Side',
                image: _backImage,
                onCamera: () => _captureImage(false),
                onGallery: () => _pickImage(false),
              ),
            ] else ...[
              _buildImageCaptureCard(
                title: 'Document Image',
                image: _singleImage,
                onCamera: () => _captureImage(null),
                onGallery: () => _pickImage(null),
              ),
            ],

            SizedBox(height: 24.h),

            // Processing status
            if (_isProcessing) ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.blue[100],
                        color: Colors.blue[700],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Process button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton.icon(
                onPressed: _canProcess && !_isProcessing ? _processOCR : null,
                icon: const Icon(Icons.auto_fix_high),
                label: Text(
                  'Process & Extract Data',
                  style: TextStyle(fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Info text
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Ensure the document is clearly visible with all details readable',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureCard({
    required String title,
    required File? image,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            // Image preview
            if (image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.file(
                  image,
                  height: 150.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Camera and Gallery buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : onGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(bool? isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1520,
      );

      if (image != null) {
        setState(() {
          if (_requiresTwoImages) {
            if (isFront == true) {
              _frontImage = File(image.path);
            } else {
              _backImage = File(image.path);
            }
          } else {
            _singleImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error capturing image: ${e.toString()}');
    }
  }

  Future<void> _pickImage(bool? isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1520,
      );

      if (image != null) {
        setState(() {
          if (_requiresTwoImages) {
            if (isFront == true) {
              _frontImage = File(image.path);
            } else {
              _backImage = File(image.path);
            }
          } else {
            _singleImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showError('Error selecting image: ${e.toString()}');
    }
  }

  Future<void> _processOCR() async {
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Uploading images...';
    });

    try {
      // Step 1: Upload images to TUS
      Map<String, String> uploadedUrls = {};

      if (_requiresTwoImages) {
        // Upload front
        setState(() => _statusMessage = 'Uploading front image...');
        final frontUrl = await _uploadToTUS(_frontImage!, 'front');
        if (frontUrl == null) throw Exception('Failed to upload front image');
        uploadedUrls['front'] = frontUrl;

        setState(() {
          _uploadProgress = 0.5;
          _statusMessage = 'Uploading back image...';
        });

        // Upload back
        final backUrl = await _uploadToTUS(_backImage!, 'back');
        if (backUrl == null) throw Exception('Failed to upload back image');
        uploadedUrls['back'] = backUrl;
      } else {
        // Upload single image
        final url = await _uploadToTUS(_singleImage!, 'document');
        if (url == null) throw Exception('Failed to upload image');
        uploadedUrls['single'] = url;
      }

      setState(() {
        _uploadProgress = 0.8;
        _statusMessage = 'Processing OCR...';
      });

      // Step 2: Call OCR API
      final ocrData = await _callOcrApi(uploadedUrls);

      // Step 3: Return data to caller
      if (mounted) {
        Navigator.pop(context, ocrData);
      }
    } catch (e) {
      _showError('OCR failed: ${e.toString()}');
      setState(() {
        _isProcessing = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<String?> _uploadToTUS(File file, String prefix) async {
    try {
      final tusService = TusUploadService();
      final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await tusService.uploadWithRetry(
        file: file,
        filename: filename,
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _callOcrApi(Map<String, String> urls) async {
    try {
      String endpoint;
      Map<String, String> body;

      switch (widget.ocrType) {
        case OcrType.aadhaar:
          endpoint = ApiConfig.aadhaarOcrEndpoint;
          body = {
            'uid_front_url': urls['front']!,
            'uid_back_url': urls['back']!,
          };
          break;
        case OcrType.bankPassbook:
          // TODO: Add bank passbook endpoint when available
          endpoint = '${ApiConfig.baseUrl}/app_utilities/extract_bank_details/';
          body = {
            'passbook_url': urls['single']!,
          };
          break;
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final ocrData = json.decode(data['data']['text']);

          // Add uploaded URLs to the response
          if (widget.ocrType == OcrType.aadhaar) {
            ocrData['front_url'] = urls['front'];
            ocrData['back_url'] = urls['back'];
          } else {
            ocrData['document_url'] = urls['single'];
          }

          return ocrData;
        } else {
          throw Exception(data['message'] ?? 'OCR processing failed');
        }
      } else {
        throw Exception('OCR API error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
