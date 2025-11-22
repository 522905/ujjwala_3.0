import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Location Service
///
/// Handles GPS location fetching with permission management

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current location
  ///
  /// Returns Position with latitude, longitude, and accuracy
  Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException(
        'Location services are disabled. Please enable location services in settings.',
      );
    }

    // Check permission
    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException(
          'Location permission denied. Please grant location access.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
        'Location permission permanently denied. Please enable it in app settings.',
      );
    }

    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      throw LocationException('Failed to get current location: $e');
    }
  }

  /// Get current location with custom accuracy
  Future<Position> getCurrentLocationWithAccuracy({
    required LocationAccuracy accuracy,
    Duration timeLimit = const Duration(seconds: 30),
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException(
        'Location services are disabled.',
      );
    }

    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException(
          'Location permission denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException(
        'Location permission permanently denied.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeLimit,
      );

      return position;
    } catch (e) {
      throw LocationException('Failed to get location: $e');
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permanently denied permissions)
  Future<void> openAppSettings() async {
    await Permission.location.request();
    if (await Permission.location.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  /// Format position as string
  String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Get distance between two positions in meters
  double getDistanceBetween({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Convert position to map for storage
  Map<String, dynamic> positionToMap(Position position) {
    return {
      'latitude': position.latitude.toString(),
      'longitude': position.longitude.toString(),
      'accuracy': position.accuracy.toString(),
      'altitude': position.altitude.toString(),
      'timestamp': position.timestamp?.toIso8601String(),
    };
  }

  /// Check if location accuracy is acceptable
  bool isAccuracyAcceptable(Position position, {double maxAccuracyMeters = 50}) {
    return position.accuracy <= maxAccuracyMeters;
  }
}

/// Location Service Disabled Exception
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);

  @override
  String toString() => message;
}

/// Location Permission Denied Exception
class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);

  @override
  String toString() => message;
}

/// Generic Location Exception
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
