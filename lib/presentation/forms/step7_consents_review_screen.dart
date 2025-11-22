import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/application_provider.dart';
import '../../providers/submission_provider.dart';
import '../submission/submission_progress_screen.dart';

/// Step 7: Consents & Review
///
/// - Display all 7 consent checkboxes
/// - Show application summary
/// - Validate and submit

class Step7ConsentsReviewScreen extends StatefulWidget {
  const Step7ConsentsReviewScreen({super.key});

  @override
  State<Step7ConsentsReviewScreen> createState() =>
      _Step7ConsentsReviewScreenState();
}

class _Step7ConsentsReviewScreenState extends State<Step7ConsentsReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 7: Review & Submit'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 7 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: Consumer<ApplicationProvider>(
                builder: (context, appProvider, _) {
                  final app = appProvider.currentApplication;

                  if (app == null) {
                    return const Center(child: Text('No application found'));
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review & Submit',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Step 7 of 7 • Final Step',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Application Summary
                        _buildSection(
                          title: 'Application Summary',
                          icon: Icons.description,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryItem(
                                'Applicant Name',
                                app.applicantFullName ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'Aadhaar Number',
                                app.applicantAadhaar ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'Mobile Number',
                                app.applicantMobile ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'Date of Birth',
                                app.applicantDob != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(app.applicantDob!)
                                    : 'N/A',
                              ),
                              _buildSummaryItem(
                                'Gender',
                                app.applicantGender != null
                                    ? Gender.fromValue(app.applicantGender!).display
                                    : 'N/A',
                              ),
                              _buildSummaryItem(
                                'Caste',
                                app.caste != null
                                    ? Caste.fromValue(app.caste!).display
                                    : 'N/A',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Bank Details Summary
                        _buildSection(
                          title: 'Bank Details',
                          icon: Icons.account_balance,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryItem(
                                'Account Name',
                                app.bankAccountName ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'Bank Name',
                                app.bankName ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'IFSC Code',
                                app.bankIfsc ?? 'N/A',
                              ),
                              _buildSummaryItem(
                                'Account Number',
                                app.bankAccountNumber ?? 'N/A',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Addresses Summary
                        _buildSection(
                          title: 'Addresses',
                          icon: Icons.location_on,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryItem(
                                'Current Address',
                                appProvider.currentAddress?.formattedAddress ??
                                    'N/A',
                              ),
                              SizedBox(height: 8.h),
                              _buildSummaryItem(
                                'Permanent Address',
                                appProvider.permanentAddress
                                        ?.formattedAddress ??
                                    'N/A',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Family Members Summary
                        _buildSection(
                          title: 'Family Members',
                          icon: Icons.people,
                          child: Text(
                            '${appProvider.familyMembers.length} member(s) added',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Documents Summary
                        _buildSection(
                          title: 'Documents',
                          icon: Icons.upload_file,
                          child: Text(
                            '${appProvider.documents.length} document(s) uploaded',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Consents Section
                        _buildSection(
                          title: 'Declarations & Consents',
                          icon: Icons.check_box,
                          child: Column(
                            children: [
                              _buildConsentCheckbox(
                                'Aadhaar Consent',
                                'I consent to use my Aadhaar for verification',
                                app.aadhaarConsentSigned ?? false,
                                (value) => appProvider.updateConsent(
                                    'aadhaar_consent', value!),
                              ),
                              _buildConsentCheckbox(
                                'DBTL Consent',
                                'I agree to Direct Benefit Transfer for LPG subsidy',
                                app.agreesToDbtl ?? false,
                                (value) =>
                                    appProvider.updateConsent('dbtl', value!),
                              ),
                              _buildConsentCheckbox(
                                'Pre-Installation Check',
                                'I agree to pre-installation safety check',
                                app.agreesPreInstallationCheck ?? false,
                                (value) => appProvider.updateConsent(
                                    'pre_installation', value!),
                              ),
                              _buildConsentCheckbox(
                                'Mandatory Inspections',
                                'I agree to mandatory safety inspections',
                                app.agreesMandatoryInspections ?? false,
                                (value) => appProvider.updateConsent(
                                    'mandatory_inspections', value!),
                              ),
                              _buildConsentCheckbox(
                                'No Existing Connection',
                                'I declare that I do not have any existing LPG connection',
                                app.declaresNoExistingConnection ?? false,
                                (value) => appProvider.updateConsent(
                                    'no_existing_connection', value!),
                              ),
                              _buildConsentCheckbox(
                                'Domestic Cooking Only',
                                'I declare that the connection will be used for domestic cooking only',
                                app.declaresUseForDomesticCookingOnly ?? false,
                                (value) => appProvider.updateConsent(
                                    'domestic_cooking', value!),
                              ),
                              _buildConsentCheckbox(
                                'Data Sharing Consent',
                                'I consent to data sharing between OMC and Bank',
                                app.consentDataSharingOmcBank ?? false,
                                (value) => appProvider.updateConsent(
                                    'data_sharing', value!),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // Completion Status
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: app.isComplete
                                ? Colors.green[50]
                                : Colors.orange[50],
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: app.isComplete
                                  ? Colors.green[300]!
                                  : Colors.orange[300]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                app.isComplete
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: app.isComplete
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.isComplete
                                          ? 'Application Complete'
                                          : 'Application Incomplete',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: app.isComplete
                                            ? Colors.green[900]
                                            : Colors.orange[900],
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Completion: ${app.completionPercentage}%',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: app.isComplete
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Submit Button
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
              child: Consumer<ApplicationProvider>(
                builder: (context, appProvider, _) {
                  final app = appProvider.currentApplication;
                  final canSubmit = app?.isComplete ?? false;

                  return Row(
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
                          onPressed: canSubmit ? _submitApplication : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: const Text('Submit Application'),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700], size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCheckbox(
    String title,
    String description,
    bool value,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12.sp),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.blue[700],
    );
  }

  Future<void> _submitApplication() async {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app == null || !app.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application is not complete'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to submission progress screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SubmissionProgressScreen(application: app),
      ),
    );
  }
}
