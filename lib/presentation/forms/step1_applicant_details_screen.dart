import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/application_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/enums/app_enums.dart';
import 'step2_bank_details_screen.dart';

/// Step 1: Applicant Details
///
/// Collects:
/// - Full name (auto-split into first/middle/last)
/// - Gender (must be Female for PMUY V3)
/// - Date of Birth (must be ≥18 years)
/// - Aadhaar number
/// - Mobile number
/// - Caste
/// - Marital Status
/// - Marriage Date (if married)

class Step1ApplicantDetailsScreen extends StatefulWidget {
  const Step1ApplicantDetailsScreen({super.key});

  @override
  State<Step1ApplicantDetailsScreen> createState() =>
      _Step1ApplicantDetailsScreenState();
}

class _Step1ApplicantDetailsScreenState
    extends State<Step1ApplicantDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _mobileController = TextEditingController();

  Gender? _selectedGender;
  DateTime? _selectedDob;
  Caste? _selectedCaste;
  MaritalStatus? _selectedMaritalStatus;
  DateTime? _selectedMarriageDate;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app != null) {
      _fullNameController.text = app.applicantFullName ?? '';
      _aadhaarController.text = app.applicantAadhaar ?? '';
      _mobileController.text = app.applicantMobile ?? '';
      _selectedGender = app.applicantGender != null
          ? Gender.fromValue(app.applicantGender!)
          : null;
      _selectedDob = app.applicantDob;
      _selectedCaste = app.caste != null
          ? Caste.fromValue(app.caste!)
          : null;
      _selectedMaritalStatus = app.maritalStatus != null
          ? MaritalStatus.fromValue(app.maritalStatus!)
          : null;
      _selectedMarriageDate = app.marriageDate;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _aadhaarController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _saveField(String field, dynamic value) {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    appProvider.updateApplicantField(field, value);
  }

  Future<void> _selectDate(BuildContext context, bool isMarriageDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMarriageDate
          ? (_selectedMarriageDate ?? DateTime.now())
          : (_selectedDob ?? DateTime(2000)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isMarriageDate) {
          _selectedMarriageDate = picked;
          _saveField('marriage_date', picked);
        } else {
          _selectedDob = picked;
          _saveField('applicant_dob', picked);
        }
      });
    }
  }

  void _splitAndSaveFullName() {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) return;

    final parts = fullName.split(' ');
    String firstName = '';
    String? middleName;
    String? lastName;

    if (parts.length == 1) {
      firstName = parts[0];
    } else if (parts.length == 2) {
      firstName = parts[0];
      lastName = parts[1];
    } else {
      firstName = parts[0];
      middleName = parts.sublist(1, parts.length - 1).join(' ');
      lastName = parts.last;
    }

    _saveField('applicant_full_name', fullName);
    _saveField('applicant_first_name', firstName);
    _saveField('applicant_middle_name', middleName);
    _saveField('applicant_last_name', lastName);
  }

  void _proceedToNextStep() {
    if (!_formKey.currentState!.validate()) return;

    // Additional validations
    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }

    if (_selectedGender != Gender.female) {
      _showError('Only Female applicants are eligible for PMUY V3');
      return;
    }

    if (_selectedDob == null) {
      _showError('Please select date of birth');
      return;
    }

    if (_selectedCaste == null) {
      _showError('Please select caste');
      return;
    }

    if (_selectedMaritalStatus == null) {
      _showError('Please select marital status');
      return;
    }

    if (_selectedMaritalStatus == MaritalStatus.married &&
        _selectedMarriageDate == null) {
      _showError('Please select marriage date');
      return;
    }

    // Save and proceed
    _splitAndSaveFullName();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step2BankDetailsScreen(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1: Applicant Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 1 / 7,
              backgroundColor: Colors.grey[300],
              color: Colors.blue[700],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applicant Information',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Step 1 of 7',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'First Middle Last',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('applicant_full_name', value),
                        validator: (value) => Validators.validateName(value, 'Full name'),
                      ),
                      SizedBox(height: 16.h),

                      // Gender
                      DropdownButtonFormField<Gender>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: const Icon(Icons.wc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: Gender.values.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender.display),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                          _saveField('applicant_gender', value?.value);
                        },
                        validator: (value) {
                          if (value == null) return 'Please select gender';
                          if (value != Gender.female) {
                            return 'Only Female applicants are eligible';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Date of Birth
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth *',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            _selectedDob != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: _selectedDob != null
                                  ? Colors.black
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDob != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Age: ${DateTime.now().year - _selectedDob!.year} years',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),

                      // Aadhaar
                      TextFormField(
                        controller: _aadhaarController,
                        decoration: InputDecoration(
                          labelText: 'Aadhaar Number *',
                          prefixIcon: const Icon(Icons.credit_card),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        onChanged: (value) => _saveField('applicant_aadhaar', value),
                        validator: Validators.validateAadhaar,
                      ),
                      SizedBox(height: 16.h),

                      // Mobile
                      TextFormField(
                        controller: _mobileController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number *',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: (value) => _saveField('applicant_mobile', value),
                        validator: Validators.validateMobile,
                      ),
                      SizedBox(height: 16.h),

                      // Caste
                      DropdownButtonFormField<Caste>(
                        value: _selectedCaste,
                        decoration: InputDecoration(
                          labelText: 'Caste *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: Caste.values.map((caste) {
                          return DropdownMenuItem(
                            value: caste,
                            child: Text(caste.display),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCaste = value);
                          _saveField('caste', value?.value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select caste' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Marital Status
                      DropdownButtonFormField<MaritalStatus>(
                        value: _selectedMaritalStatus,
                        decoration: InputDecoration(
                          labelText: 'Marital Status *',
                          prefixIcon: const Icon(Icons.favorite),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: MaritalStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.display),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMaritalStatus = value);
                          _saveField('marital_status', value?.value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select marital status' : null,
                      ),
                      SizedBox(height: 16.h),

                      // Marriage Date (if married)
                      if (_selectedMaritalStatus == MaritalStatus.married) ...[
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Marriage Date *',
                              prefixIcon: const Icon(Icons.event),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              _selectedMarriageDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedMarriageDate!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: _selectedMarriageDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      SizedBox(height: 24.h),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _proceedToNextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: const Text('Next: Bank Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
