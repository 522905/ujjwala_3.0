import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../providers/application_provider.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/local_family_member.dart';
import '../../data/repositories/document_repository.dart';
import 'step6_documents_screen.dart';

/// Step 5: Family Members
///
/// Manage family members with Aadhaar photo uploads
/// Validation: Exactly 1 member with relation SELF required

class Step5FamilyMembersScreen extends StatefulWidget {
  const Step5FamilyMembersScreen({super.key});

  @override
  State<Step5FamilyMembersScreen> createState() =>
      _Step5FamilyMembersScreenState();
}

class _Step5FamilyMembersScreenState extends State<Step5FamilyMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 5: Family Members'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 5 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: Consumer<ApplicationProvider>(
                builder: (context, appProvider, _) {
                  final members = appProvider.familyMembers;
                  final hasSelf = members.any((m) => m.isSelf);

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Family Members',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Step 5 of 7 • ${members.length} member(s)',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8.h),

                              // SELF member requirement
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: hasSelf
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: hasSelf
                                        ? Colors.green[300]!
                                        : Colors.orange[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      hasSelf
                                          ? Icons.check_circle
                                          : Icons.warning,
                                      color: hasSelf
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        hasSelf
                                            ? 'SELF member added ✓'
                                            : 'Required: Add exactly 1 SELF member',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: hasSelf
                                              ? Colors.green[900]
                                              : Colors.orange[900],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Add Family Member Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addFamilyMember(context),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Family Member'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),

                              // Family Members List
                              if (members.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.w),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64.sp,
                                          color: Colors.grey[400],
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'No family members added yet',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...members.map((member) =>
                                    _buildFamilyMemberCard(context, member)),
                            ],
                          ),
                        ),
                      ),

                      // Next Button
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
                                onPressed: hasSelf
                                    ? () => _proceedToNextStep(context)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                ),
                                child: const Text('Next: Documents'),
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

  Widget _buildFamilyMemberCard(
      BuildContext context, LocalFamilyMember member) {
    final hasPhotos = member.arePhotosUploaded;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: member.isSelf ? Colors.blue[300]! : Colors.grey[300]!,
          width: member.isSelf ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.person, color: Colors.blue[700]),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        member.relationToApplicant != null
                            ? RelationToApplicant.fromValue(member.relationToApplicant!).display
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (member.isSelf)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'SELF',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Member details
            Row(
              children: [
                Icon(Icons.credit_card, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 8.w),
                Text(
                  'Aadhaar: ${member.aadhaarNumber}',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Photo upload status
            Row(
              children: [
                Icon(
                  hasPhotos ? Icons.check_circle : Icons.warning,
                  size: 16.sp,
                  color: hasPhotos ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 8.w),
                Text(
                  hasPhotos
                      ? 'Aadhaar photos uploaded'
                      : 'Aadhaar photos not uploaded',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: hasPhotos ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _uploadAadhaarPhotos(context, member),
                    icon: Icon(
                      hasPhotos ? Icons.check : Icons.camera_alt,
                      size: 16.sp,
                    ),
                    label: Text(hasPhotos ? 'Re-upload' : 'Upload Photos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          hasPhotos ? Colors.green : Colors.blue[700],
                      side: BorderSide(
                        color: hasPhotos ? Colors.green : Colors.blue[700]!,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: () => _deleteFamilyMember(context, member),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFamilyMember(BuildContext context) async {
    final result = await showDialog<LocalFamilyMember>(
      context: context,
      builder: (_) => const FamilyMemberDialog(),
    );

    if (result != null && context.mounted) {
      final appProvider =
          Provider.of<ApplicationProvider>(context, listen: false);
      await appProvider.saveFamilyMember(result);
    }
  }

  Future<void> _uploadAadhaarPhotos(
      BuildContext context, LocalFamilyMember member) async {
    // TODO: Implement Aadhaar photo capture
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aadhaar photo capture - Implementation pending'),
      ),
    );
  }

  Future<void> _deleteFamilyMember(
      BuildContext context, LocalFamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text('Remove ${member.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final appProvider =
          Provider.of<ApplicationProvider>(context, listen: false);
      await appProvider.deleteFamilyMember(member.localId);
    }
  }

  void _proceedToNextStep(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step6DocumentsScreen(),
      ),
    );
  }
}

/// Dialog for adding/editing family member
class FamilyMemberDialog extends StatefulWidget {
  final LocalFamilyMember? member;

  const FamilyMemberDialog({super.key, this.member});

  @override
  State<FamilyMemberDialog> createState() => _FamilyMemberDialogState();
}

class _FamilyMemberDialogState extends State<FamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _aadhaarController = TextEditingController();

  RelationToApplicant? _selectedRelation;
  Gender? _selectedGender;
  DateTime? _selectedDob;
  bool _isSelfMember = false;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _fullNameController.text = widget.member!.fullName ?? '';
      _aadhaarController.text = widget.member!.aadhaarNumber ?? '';
      _selectedRelation = widget.member!.relationToApplicant != null
          ? RelationToApplicant.fromValue(widget.member!.relationToApplicant!)
          : null;
      _selectedGender = widget.member!.gender != null
          ? Gender.fromValue(widget.member!.gender!)
          : null;
      _selectedDob = widget.member!.dob;
      _isSelfMember = widget.member!.isSelf;
    }
  }

  /// Auto-fill from Step 1 applicant data when SELF is selected
  void _onRelationChanged(RelationToApplicant? relation) {
    setState(() {
      _selectedRelation = relation;
      _isSelfMember = relation == RelationToApplicant.self;
    });

    if (_isSelfMember) {
      // Get applicant data from Step 1
      final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
      final app = appProvider.currentApplication;

      if (app != null) {
        // Auto-fill from applicant details
        _fullNameController.text = app.applicantFullName ?? '';
        _aadhaarController.text = app.applicantAadhaar ?? '';

        // Parse gender
        if (app.applicantGender != null) {
          _selectedGender = Gender.fromValue(app.applicantGender!);
        }

        // Parse DOB
        if (app.applicantDob != null) {
          _selectedDob = app.applicantDob;
        }

        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Applicant details auto-filled from Step 1. Aadhaar photos will be reused.'),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRelation == null) {
      _showError('Please select relation');
      return;
    }

    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }

    if (_selectedDob == null) {
      _showError('Please select date of birth');
      return;
    }

    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app == null) {
      _showError('No active application');
      return;
    }

    // If SELF member, reuse Step 1 Aadhaar photo URLs
    String? aadhaarFrontUrl;
    String? aadhaarBackUrl;

    if (_isSelfMember) {
      // Get Aadhaar URLs from Step 1 documents
      final documents = appProvider.documents;
      try {
        final frontDoc = documents.firstWhere(
          (d) => d.docType == DocumentType.aadhaarFront,
        );
        aadhaarFrontUrl = frontDoc.tusUrl;
      } catch (e) {
        // Document not found
      }

      try {
        final backDoc = documents.firstWhere(
          (d) => d.docType == DocumentType.aadhaarBack,
        );
        aadhaarBackUrl = backDoc.tusUrl;
      } catch (e) {
        // Document not found
      }
    }

    final member = LocalFamilyMember(
      localId: widget.member?.localId ?? const Uuid().v4(),
      applicationLocalId: app.localId,
      fullName: _fullNameController.text.trim(),
      aadhaarNumber: _aadhaarController.text.trim(),
      relationToApplicant: _selectedRelation!.value,
      gender: _selectedGender!.value,
      dob: _selectedDob!,
      uidFrontTusUrl: aadhaarFrontUrl,
      uidBackTusUrl: aadhaarBackUrl,
    );

    Navigator.pop(context, member);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<ApplicationProvider>(context);
    final hasSelfMember = appProvider.familyMembers.any((m) => m.isSelf);

    return AlertDialog(
      title: Text(widget.member == null ? 'Add Family Member' : 'Edit Family Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info banner for SELF member
              if (_isSelfMember)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Details auto-filled from Step 1. No Aadhaar re-upload needed.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Relation dropdown (must be first to trigger auto-fill)
              DropdownButtonFormField<RelationToApplicant>(
                value: _selectedRelation,
                decoration: const InputDecoration(labelText: 'Relation *'),
                items: RelationToApplicant.values.map((relation) {
                  final isSelf = relation == RelationToApplicant.self;
                  final isDisabled = isSelf && hasSelfMember && !_isSelfMember;

                  return DropdownMenuItem(
                    value: relation,
                    enabled: !isDisabled,
                    child: Text(
                      relation.name + (isDisabled ? ' (Already added)' : ''),
                      style: TextStyle(
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onRelationChanged,
              ),
              SizedBox(height: 16.h),

              // Full Name (readonly for SELF)
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  filled: _isSelfMember,
                  fillColor: _isSelfMember ? Colors.green[50] : null,
                  suffixIcon: _isSelfMember
                      ? Icon(Icons.lock, size: 16.sp, color: Colors.green[700])
                      : null,
                ),
                readOnly: _isSelfMember,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Aadhaar (readonly for SELF)
              TextFormField(
                controller: _aadhaarController,
                decoration: InputDecoration(
                  labelText: 'Aadhaar Number *',
                  filled: _isSelfMember,
                  fillColor: _isSelfMember ? Colors.green[50] : null,
                  suffixIcon: _isSelfMember
                      ? Icon(Icons.lock, size: 16.sp, color: Colors.green[700])
                      : null,
                ),
                readOnly: _isSelfMember,
                keyboardType: TextInputType.number,
                maxLength: 12,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter Aadhaar';
                  }
                  if (value.trim().length != 12) {
                    return 'Aadhaar must be 12 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Gender (readonly for SELF)
              DropdownButtonFormField<Gender>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender *',
                  filled: _isSelfMember,
                  fillColor: _isSelfMember ? Colors.green[50] : null,
                ),
                items: Gender.values.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender.name),
                  );
                }).toList(),
                onChanged: _isSelfMember ? null : (value) => setState(() => _selectedGender = value),
              ),
              SizedBox(height: 16.h),

              // DOB (readonly for SELF)
              InkWell(
                onTap: _isSelfMember ? null : () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth *',
                    filled: _isSelfMember,
                    fillColor: _isSelfMember ? Colors.green[50] : null,
                    suffixIcon: _isSelfMember
                        ? Icon(Icons.lock, size: 16.sp, color: Colors.green[700])
                        : null,
                  ),
                  child: Text(
                    _selectedDob != null
                        ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                        : 'Select date',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
