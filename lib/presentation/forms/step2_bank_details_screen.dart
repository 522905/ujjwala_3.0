import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../core/utils/validators.dart';
import 'step3_current_address_screen.dart';

/// Step 2: Bank Details
///
/// Collects:
/// - Bank Account Name
/// - Bank Name
/// - Branch
/// - IFSC Code
/// - Account Number

class Step2BankDetailsScreen extends StatefulWidget {
  const Step2BankDetailsScreen({super.key});

  @override
  State<Step2BankDetailsScreen> createState() => _Step2BankDetailsScreenState();
}

class _Step2BankDetailsScreenState extends State<Step2BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app != null) {
      _accountNameController.text = app.bankAccountName ?? '';
      _bankNameController.text = app.bankName ?? '';
      _branchController.text = app.bankBranch ?? '';
      _ifscController.text = app.bankIfsc ?? '';
      _accountNumberController.text = app.bankAccountNumber ?? '';
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ifscController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _saveField(String field, String value) {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    appProvider.updateBankField(field, value);
  }

  void _proceedToNextStep() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Step3CurrentAddressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2: Bank Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 2 / 7,
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
                        'Bank Account Details',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Step 2 of 7',
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
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'For DBTL (Direct Benefit Transfer) of LPG subsidy',
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

                      // Account Holder Name
                      TextFormField(
                        controller: _accountNameController,
                        decoration: InputDecoration(
                          labelText: 'Account Holder Name *',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_account_name', value),
                        validator: (value) => Validators.validateName(value, 'Account holder name'),
                      ),
                      SizedBox(height: 16.h),

                      // Bank Name
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Bank Name *',
                          prefixIcon: const Icon(Icons.account_balance),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_name', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter bank name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Branch Name
                      TextFormField(
                        controller: _branchController,
                        decoration: InputDecoration(
                          labelText: 'Branch Name *',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) => _saveField('bank_branch', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter branch name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // IFSC Code
                      TextFormField(
                        controller: _ifscController,
                        decoration: InputDecoration(
                          labelText: 'IFSC Code *',
                          hintText: 'e.g., SBIN0001234',
                          prefixIcon: const Icon(Icons.pin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 11,
                        onChanged: (value) => _saveField('bank_ifsc', value),
                        validator: Validators.validateIfsc,
                      ),
                      SizedBox(height: 16.h),

                      // Account Number
                      TextFormField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          labelText: 'Account Number *',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _saveField('bank_account_number', value),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account number';
                          }
                          if (value.trim().length < 9 || value.trim().length > 18) {
                            return 'Account number must be 9-18 digits';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32.h),

                      // Navigation Buttons
                      Row(
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
                              onPressed: _proceedToNextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: const Text('Next: Current Address'),
                            ),
                          ),
                        ],
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
