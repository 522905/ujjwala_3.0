import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/application_provider.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/local_address.dart';
import 'step5_family_members_screen.dart';

/// Step 4: Permanent Address
///
/// Collects permanent address with migrant validation:
/// - State must be DIFFERENT from current address state

class Step4PermanentAddressScreen extends StatefulWidget {
  const Step4PermanentAddressScreen({super.key});

  @override
  State<Step4PermanentAddressScreen> createState() =>
      _Step4PermanentAddressScreenState();
}

class _Step4PermanentAddressScreenState
    extends State<Step4PermanentAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseNumberController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _pincodeController = TextEditingController();

  IndianState? _selectedState;
  IndianState? _currentAddressState;
  String? _existingAddressId;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);

    // Get current address state for validation
    final currentAddress = appProvider.currentAddress;
    _currentAddressState = currentAddress?.state != null
        ? IndianState.fromValue(currentAddress!.state!)
        : null;

    // Load existing permanent address if any
    final permanentAddress = appProvider.permanentAddress;
    if (permanentAddress != null) {
      _existingAddressId = permanentAddress.localId;
      _houseNumberController.text = permanentAddress.houseFlatNo ?? '';
      _buildingController.text = permanentAddress.buildingColony ?? '';
      _streetController.text = permanentAddress.streetRoad ?? '';
      _areaController.text = permanentAddress.villagePanchayatArea ?? '';
      _landmarkController.text = permanentAddress.landmark ?? '';
      _cityController.text = permanentAddress.cityTown ?? '';
      _districtController.text = permanentAddress.district ?? '';
      _pincodeController.text = permanentAddress.pincode ?? '';
      _selectedState = permanentAddress.state != null
          ? IndianState.fromValue(permanentAddress.state!)
          : null;
    }
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _copyFromCurrentAddress() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final currentAddress = appProvider.currentAddress;

    if (currentAddress == null) {
      _showError('Please fill current address first');
      return;
    }

    setState(() {
      _houseNumberController.text = currentAddress.houseFlatNo ?? '';
      _buildingController.text = currentAddress.buildingColony ?? '';
      _streetController.text = currentAddress.streetRoad ?? '';
      _areaController.text = currentAddress.villagePanchayatArea ?? '';
      _landmarkController.text = currentAddress.landmark ?? '';
      _cityController.text = currentAddress.cityTown ?? '';
      _districtController.text = currentAddress.district ?? '';
      _pincodeController.text = currentAddress.pincode ?? '';
      // Note: Don't copy state - it must be different!
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Address copied. Please select a DIFFERENT state.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showError('Please select state');
      return;
    }

    // CRITICAL: Migrant validation - states must be different
    if (_currentAddressState != null &&
        _selectedState == _currentAddressState) {
      _showError(
        'Permanent address state must be DIFFERENT from current address state.\n'
        'Current: ${_currentAddressState!.display}\n'
        'This is required for Migrant Household validation.',
      );
      return;
    }

    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final app = appProvider.currentApplication;

    if (app == null) {
      _showError('No active application found');
      return;
    }

    // Create or update address
    final address = LocalAddress(
      localId: _existingAddressId ?? const Uuid().v4(),
      applicationLocalId: app.localId,
      addressType: 'PERMANENT',
      houseFlatNo: _houseNumberController.text.trim(),
      buildingColony: _buildingController.text.trim(),
      streetRoad: _streetController.text.trim(),
      villagePanchayatArea: _areaController.text.trim(),
      landmark: _landmarkController.text.trim(),
      cityTown: _cityController.text.trim(),
      district: _districtController.text.trim(),
      state: _selectedState?.value,
      pincode: _pincodeController.text.trim(),
    );

    await appProvider.saveAddress(address);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Step5FamilyMembersScreen(),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 4: Permanent Address'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 4 / 7,
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
                        'Permanent Address',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Step 4 of 7',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Migrant validation info
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'IMPORTANT: Permanent address state must be DIFFERENT from current address state for Migrant Household validation.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Copy from Current Address Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copyFromCurrentAddress,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy from Current Address'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // House Number
                      TextFormField(
                        controller: _houseNumberController,
                        decoration: InputDecoration(
                          labelText: 'House/Flat Number *',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter house/flat number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Building Name
                      TextFormField(
                        controller: _buildingController,
                        decoration: InputDecoration(
                          labelText: 'Building/Apartment Name',
                          prefixIcon: const Icon(Icons.apartment),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Street
                      TextFormField(
                        controller: _streetController,
                        decoration: InputDecoration(
                          labelText: 'Street/Road *',
                          prefixIcon: const Icon(Icons.add_road),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter street/road';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Area/Locality
                      TextFormField(
                        controller: _areaController,
                        decoration: InputDecoration(
                          labelText: 'Area/Locality *',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter area/locality';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Landmark
                      TextFormField(
                        controller: _landmarkController,
                        decoration: InputDecoration(
                          labelText: 'Landmark',
                          prefixIcon: const Icon(Icons.place),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // City
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City/Town/Village *',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter city/town/village';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // District
                      TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: 'District *',
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter district';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // State (with validation highlight)
                      DropdownButtonFormField<IndianState>(
                        value: _selectedState,
                        decoration: InputDecoration(
                          labelText: 'State * (Must be different from Current)',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: _selectedState != null &&
                                      _selectedState == _currentAddressState
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          helperText: _currentAddressState != null
                              ? 'Current address: ${_currentAddressState!.name.replaceAll('_', ' ')}'
                              : null,
                          helperStyle: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue[700],
                          ),
                        ),
                        items: IndianState.values.map((state) {
                          final isCurrent = state == _currentAddressState;
                          return DropdownMenuItem(
                            value: state,
                            child: Row(
                              children: [
                                Text(state.name.replaceAll('_', ' ')),
                                if (isCurrent) ...[
                                  SizedBox(width: 8.w),
                                  Text(
                                    '(Current)',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedState = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Please select state';
                          if (value == _currentAddressState) {
                            return 'Must be different from current address state';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Pincode
                      TextFormField(
                        controller: _pincodeController,
                        decoration: InputDecoration(
                          labelText: 'Pincode *',
                          prefixIcon: const Icon(Icons.pin_drop),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter pincode';
                          }
                          if (value.trim().length != 6) {
                            return 'Pincode must be 6 digits';
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
                              onPressed: _saveAndProceed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                              ),
                              child: const Text('Next: Family Members'),
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
