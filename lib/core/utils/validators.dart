/// Form Validators
///
/// This file contains all validation functions used throughout the app.

import 'aadhaar_validator.dart';

class Validators {
  /// Validate mobile number (10 digits, starts with 6-9)
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanValue.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(cleanValue)) {
      return 'Invalid mobile number format';
    }

    return null;
  }

  /// Validate Aadhaar number using Verhoeff algorithm
  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanValue.length != 12) {
      return 'Aadhaar must be exactly 12 digits';
    }

    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Aadhaar must contain only digits';
    }

    if (!AadhaarValidator.validate(cleanValue)) {
      return 'Invalid Aadhaar number (checksum failed)';
    }

    return null;
  }

  /// Validate email (optional field)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email address';
    }

    return null;
  }

  /// Validate IFSC code (11 characters, alphanumeric)
  static String? validateIFSC(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }

    final cleanValue = value.trim().toUpperCase();

    if (cleanValue.length != 11) {
      return 'IFSC code must be exactly 11 characters';
    }

    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleanValue)) {
      return 'Invalid IFSC code format';
    }

    return null;
  }

  /// Validate IFSC code (alias for validateIFSC)
  static String? validateIfsc(String? value) => validateIFSC(value);

  /// Validate bank account number (9-18 digits)
  static String? validateBankAccount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bank account number is required';
    }

    final cleanValue = value.replaceAll(RegExp(r'[\s-]'), '');

    if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
      return 'Account number must contain only digits';
    }

    if (cleanValue.length < 9 || cleanValue.length > 18) {
      return 'Account number must be 9-18 digits';
    }

    return null;
  }

  /// Validate pincode (6 digits)
  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    if (value.length != 6) {
      return 'Pincode must be exactly 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Invalid pincode format';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name (alphabets and spaces only)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$fieldName must contain only alphabets and spaces';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    return null;
  }

  /// Validate age (must be >= 18 years)
  static String? validateAge(DateTime? dob) {
    if (dob == null) {
      return 'Date of birth is required';
    }

    final today = DateTime.now();
    final age = today.year - dob.year;
    final monthDiff = today.month - dob.month;
    final dayDiff = today.day - dob.day;

    int actualAge = age;
    if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) {
      actualAge = age - 1;
    }

    if (actualAge < 18) {
      return 'Applicant must be at least 18 years old';
    }

    if (actualAge > 120) {
      return 'Invalid date of birth';
    }

    return null;
  }

  /// Validate gender (must be Female for PMUY V3)
  static String? validateGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) {
      return 'Gender is required';
    }

    if (gender != 'F') {
      return 'Applicant must be female for PMUY V3';
    }

    return null;
  }

  /// Validate password (minimum 8 characters, alphanumeric)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validate OTP (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }

    if (value.length != 6) {
      return 'OTP must be exactly 6 digits';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Invalid OTP format';
    }

    return null;
  }

  /// Validate that two states are different (for migrant validation)
  static String? validateDifferentStates(String? currentState, String? permanentState) {
    if (currentState == null || permanentState == null) {
      return null; // Will be caught by individual required validations
    }

    if (currentState == permanentState) {
      return 'For migrant applications, current and permanent addresses must be in different states';
    }

    return null;
  }
}
