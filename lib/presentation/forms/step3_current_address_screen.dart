import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/application_provider.dart';
import '../../core/enums/app_enums.dart';
import '../../data/models/local_address.dart';
import 'step4_permanent_address_screen.dart';

/// Step 3: Current Address
///
/// Collects complete current address including state and pincode

class Step3CurrentAddressScreen extends StatefulWidget {
  const Step3CurrentAddressScreen({super.key});

  @override
  State<Step3CurrentAddressScreen> createState() =>
      _Step3CurrentAddressScreenState();
}

class _Step3CurrentAddressScreenState extends State<Step3CurrentAddressScreen> {
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
  String? _existingAddressId;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final appProvider = Provider.of<ApplicationProvider>(context, listen: false);
    final address = appProvider.currentAddress;

    if (address != null) {
      _existingAddressId = address.localId;
      _houseNumberController.text = address.houseFlatNo ?? '';
      _buildingController.text = address.buildingColony ?? '';
      _streetController.text = address.streetRoad ?? '';
      _areaController.text = address.villagePanchayatArea ?? '';
      _landmarkController.text = address.landmark ?? '';
      _cityController.text = address.cityTown ?? '';
      _districtController.text = address.district ?? 'Ludhiana'; // Default to Ludhiana
      _pincodeController.text = address.pincode ?? '';
      _selectedState = address.state != null
          ? IndianState.fromValue(address.state!)
          : IndianState.pb; // Default to Punjab
    } else {
      // Set defaults for new address
      _districtController.text = 'Ludhiana';
      _selectedState = IndianState.pb;
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

  Future<void> _saveAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null) {
      _showError('Please select state');
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
      addressType: 'CURRENT',
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
          builder: (_) => const Step4PermanentAddressScreen(),
        ),
      );
    }
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
        title: const Text('Step 3: Current Address'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: 3 / 7,
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
                        'Current Address',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Step 3 of 7',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
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

                      // State
                      DropdownButtonFormField<IndianState>(
                        value: _selectedState,
                        decoration: InputDecoration(
                          labelText: 'State *',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        items: IndianState.values.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state.name.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedState = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Please select state';
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
                              child: const Text('Next: Permanent Address'),
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
