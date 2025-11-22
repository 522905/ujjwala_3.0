# Compilation Errors - Fix Guide

## Summary
Generated Hive adapters successfully, but there are 15+ compilation errors that need to be fixed before the app can compile.

## Environment
- Flutter: 3.35.4
- Dart: 3.9.2
- Gradle: 8.10.2 ✅ (FIXED)
- Android SDK: 36 ✅ (FIXED)
- NDK: 27.0.12077973 ✅ (FIXED)

## Errors to Fix

### 1. AuthRepository Missing Dependency Injection (lib/main.dart:41)

**Error:**
```
Too few positional arguments: 1 required, 0 given.
create: (_) => AuthRepository(),
```

**Fix:**
```dart
// lib/main.dart line 40-43
Provider<ApiService>(
  create: (_) => ApiService(),
),
Provider<AuthRepository>(
  create: (context) => AuthRepository(
    context.read<ApiService>(),
  ),
),
```

### 2. ApplicationRepository Missing Dependencies (lib/main.dart:44)

**Error:**
```
Too few positional arguments: 2 required, 0 given.
create: (_) => ApplicationRepository(),
```

**Fix:**
```dart
// lib/main.dart line 44-48
Provider<TusUploadService>(
  create: (_) => TusUploadService(),
),
Provider<ApplicationRepository>(
  create: (context) => ApplicationRepository(
    context.read<ApiService>(),
    context.read<TusUploadService>(),
  ),
),
```

### 3. CardTheme Type Mismatch (lib/main.dart:128)

**Error:**
```
The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'.
```

**Fix:**
```dart
// lib/main.dart line 128-132
cardTheme: CardThemeData(  // Changed from CardTheme
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
),
```

### 4. TusClient Constructor Issue (lib/data/services/tus_upload_service.dart:28)

**Error:**
```
Too many positional arguments: 0 allowed, but 2 found.
final client = TusClient(Uri.parse(...), file, ...)
```

**Fix - Check tusc package documentation:**
```dart
// The tusc:^2.1.0 package has a different constructor
// Check actual constructor at: https://pub.dev/packages/tusc

// Possible fix:
final client = TusClient();
await client.upload(
  file: file,
  url: Uri.parse(ApiConfig.tusUploadUrl),
  metadata: {
    'filename': filename,
    'filetype': _getMimeType(filename),
  },
  onProgress: onProgress,
);
```

### 5. Gender Enum Value (step1_applicant_details_screen.dart)

**Error:**
```
Member not found: 'F'
if (_selectedGender != Gender.F)
```

**Fix:**
```dart
// Replace all instances of Gender.F with Gender.female
if (_selectedGender != Gender.female) {
  _showError('Only Female applicants are eligible for PMUY V3');
  return;
}

// In validator (line 263):
if (value != Gender.female) {
  return 'Only Female applicants are eligible';
}
```

### 6. MaritalStatus Enum Value (step1_applicant_details_screen.dart)

**Error:**
```
Member not found: 'MARRIED'
if (_selectedMaritalStatus == MaritalStatus.MARRIED)
```

**Fix:**
```dart
// Replace all instances of MaritalStatus.MARRIED with MaritalStatus.married
if (_selectedMaritalStatus == MaritalStatus.married &&
    _selectedMarriageDate == null) {
  _showError('Please select marriage date');
  return;
}

// Line 392:
if (_selectedMaritalStatus == MaritalStatus.married) ...[
```

### 7. Enum Type Mismatch in Loading (step1_applicant_details_screen.dart:57-60)

**Error:**
```
A value of type 'String?' can't be assigned to a variable of type 'Gender?'
_selectedGender = app.applicantGender;
```

**Fix:**
```dart
// Lines 57-61 in _loadExistingData():
if (app != null) {
  _fullNameController.text = app.applicantFullName ?? '';
  _aadhaarController.text = app.applicantAadhaar ?? '';
  _mobileController.text = app.applicantMobile ?? '';

  // Parse string to enum
  if (app.applicantGender != null) {
    _selectedGender = Gender.values.firstWhere(
      (e) => e.value == app.applicantGender,
      orElse: () => Gender.female,
    );
  }

  _selectedDob = app.applicantDob;

  if (app.caste != null) {
    _selectedCaste = Caste.values.firstWhere(
      (e) => e.name == app.caste,
      orElse: () => Caste.general,
    );
  }

  if (app.maritalStatus != null) {
    _selectedMaritalStatus = MaritalStatus.values.firstWhere(
      (e) => e.name == app.maritalStatus,
      orElse: () => MaritalStatus.single,
    );
  }

  _selectedMarriageDate = app.marriageDate;
}
```

### 8. Validator Function Signature (step1_applicant_details_screen.dart:237)

**Error:**
```
The argument type 'String? Function(String?, String)' can't be assigned to the parameter type 'String? Function(String?)?'
validator: Validators.validateName,
```

**Fix:**
```dart
// Line 237:
validator: (value) => Validators.validateName(value, 'Full Name'),

// Line 154 in step2_bank_details_screen.dart:
validator: (value) => Validators.validateName(value, 'Account Holder Name'),
```

### 9. Missing IFSC Validator (step2_bank_details_screen.dart:214)

**Error:**
```
Member not found: 'validateIfsc'
validator: Validators.validateIfsc,
```

**Fix:**
```dart
// Add to lib/core/utils/validators.dart:
static String? validateIfsc(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter IFSC code';
  }

  final cleaned = value.trim();
  if (cleaned.length != 11) {
    return 'IFSC code must be 11 characters';
  }

  // IFSC format: First 4 letters (bank code), 5th is 0, last 6 alphanumeric
  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleaned.toUpperCase())) {
    return 'Invalid IFSC code format';
  }

  return null;
}
```

### 10. LocalAddress Property Names (step3_current_address_screen.dart:48-50)

**Error:**
```
The getter 'houseNumber' isn't defined for the type 'LocalAddress'
The getter 'buildingName' isn't defined
The getter 'street' isn't defined
```

**Check LocalAddress model:** The property names in the model might be different.

**Fix - Update property names based on actual model:**
```dart
// Check lib/data/models/local_address.dart to see actual property names
// Then update all references in:
// - step3_current_address_screen.dart
// - step4_permanent_address_screen.dart

// If properties are named differently, update accordingly
```

### 11. ForgotPassword Missing Method (forgot_password_screen.dart:51)

**Error:**
```
Too few positional arguments: 1 required, 0 given.
await authProvider.forgotPasswordInitiate(
```

**Fix:**
```dart
// Check lib/providers/auth_provider.dart for correct method signature
// Update line 51:
final success = await authProvider.forgotPasswordInitiate(
  aadhaar: _aadhaarController.text.trim(),
);

// Check if confirmPassword parameter exists (line 133):
// If method doesn't have confirmPassword, remove it
await authProvider.forgotPasswordReset(
  aadhaar: _aadhaarController.text.trim(),
  newPassword: _newPasswordController.text,
  // Remove confirmPassword if not in method signature
);
```

## Quick Fix Priority

1. **HIGH**: Fix main.dart dependency injection (errors 1, 2, 3)
2. **HIGH**: Fix TusClient constructor (error 4)
3. **MEDIUM**: Fix enum values (errors 5, 6, 7)
4. **MEDIUM**: Fix validator signatures (errors 8, 9)
5. **LOW**: Fix property names (error 10)
6. **LOW**: Fix forgot password (error 11)

## Testing After Fixes

```bash
# After fixing all errors:
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

## Notes

- All Hive adapters generated successfully ✅
- Gradle and Android SDK updated ✅
- Code fixes required for Flutter 3.35.4 compatibility
- Most errors are simple enum/type mismatches

## Estimated Fix Time

- 15-20 minutes for experienced developer
- Most fixes are search-and-replace
