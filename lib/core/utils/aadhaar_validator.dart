/// Aadhaar Verhoeff Validation
///
/// This utility validates Indian Aadhaar numbers using the Verhoeff algorithm.
/// The Verhoeff algorithm is a checksum formula for error detection.

class AadhaarValidator {
  // Verhoeff algorithm multiplication table
  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
  ];

  // Verhoeff algorithm permutation table
  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
  ];

  // Verhoeff algorithm inverse table
  static const List<int> _inv = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  /// Validates Aadhaar number using Verhoeff algorithm
  ///
  /// Returns true if the Aadhaar number is valid, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// bool isValid = AadhaarValidator.validate('123456789012');
  /// ```
  static bool validate(String aadhaar) {
    // Remove spaces and dashes if any
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    // Check if exactly 12 digits
    if (cleanAadhaar.length != 12) {
      return false;
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleanAadhaar)) {
      return false;
    }

    // Perform Verhoeff validation
    return _verhoeffValidate(cleanAadhaar);
  }

  /// Internal Verhoeff validation
  static bool _verhoeffValidate(String input) {
    if (input.length != 12) return false;

    try {
      final digits = input.split('').map(int.parse).toList();
      final checkDigit = digits.removeLast();

      final calculatedChecksum = _verhoeffGenerate(digits);
      return calculatedChecksum == checkDigit;
    } catch (e) {
      return false;
    }
  }

  /// Generate Verhoeff checksum
  static int _verhoeffGenerate(List<int> digits) {
    int c = 0;
    final invertedArray = digits.reversed.toList();

    for (int i = 0; i < invertedArray.length; i++) {
      c = _d[c][_p[((i + 1) % 8)][invertedArray[i]]];
    }

    return _inv[c];
  }

  /// Format Aadhaar number with spaces (XXXX XXXX XXXX)
  ///
  /// Example:
  /// ```dart
  /// String formatted = AadhaarValidator.format('123456789012');
  /// // Returns: '1234 5678 9012'
  /// ```
  static String format(String aadhaar) {
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanAadhaar.length != 12) {
      return aadhaar;
    }

    return '${cleanAadhaar.substring(0, 4)} ${cleanAadhaar.substring(4, 8)} ${cleanAadhaar.substring(8, 12)}';
  }

  /// Mask Aadhaar number (show only last 4 digits)
  ///
  /// Example:
  /// ```dart
  /// String masked = AadhaarValidator.mask('123456789012');
  /// // Returns: 'XXXX XXXX 9012'
  /// ```
  static String mask(String aadhaar) {
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanAadhaar.length != 12) {
      return aadhaar;
    }

    return 'XXXX XXXX ${cleanAadhaar.substring(8, 12)}';
  }

  /// Get validation state for UI feedback
  ///
  /// Returns:
  /// - null: Not enough input or invalid format
  /// - true: Valid Aadhaar
  /// - false: Invalid Aadhaar checksum
  static bool? getValidationState(String aadhaar) {
    final cleanAadhaar = aadhaar.replaceAll(RegExp(r'[\s-]'), '');

    if (cleanAadhaar.length != 12 || !RegExp(r'^\d+$').hasMatch(cleanAadhaar)) {
      return null;
    }

    return _verhoeffValidate(cleanAadhaar);
  }
}
