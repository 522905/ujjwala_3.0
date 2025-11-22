# Dependency Updates for Flutter 3.24+

## Updated Dependencies

All plugins have been updated to their latest versions compatible with Flutter 3.19.0+ and Dart 3.x.

### Major Updates

#### State Management
- `provider`: ^6.1.0 → ^6.1.2

#### Local Storage
- `flutter_secure_storage`: ^9.0.0 → ^9.2.2
- `path_provider`: ^2.1.0 → ^2.1.4
- `shared_preferences`: ^2.2.0 → ^2.3.2

#### Networking
- `dio`: ^5.3.0 → ^5.7.0 (Major improvements in error handling)
- `connectivity_plus`: ^5.0.0 → ^6.0.5 (Breaking changes - check migration guide)
- `http`: ^1.1.0 → ^1.2.2

#### Image/File Handling
- `image_picker`: ^1.0.4 → ^1.1.2
- `file_picker`: ^6.0.0 → ^8.1.2 (Major version update - check breaking changes)
- `flutter_image_compress`: ^2.1.0 → ^2.3.0
- `cached_network_image`: ^3.3.0 → ^3.4.1
- `image`: ^4.1.3 → ^4.2.0

#### Location Services
- `geolocator`: ^10.1.0 → ^13.0.1 (Major version update - API changes)
- `permission_handler`: ^11.0.0 → ^11.3.1

#### UI Components
- `flutter_spinkit`: ^5.2.0 → ^5.2.1
- `flutter_svg`: ^2.0.9 → ^2.0.10+1
- `google_fonts`: ^6.1.0 → ^6.2.1
- `flutter_screenutil`: ^5.9.0 → ^5.9.3

#### Utilities
- `intl`: ^0.18.1 → ^0.19.0
- `uuid`: ^4.2.0 → ^4.5.1
- `logger`: ^2.0.2 → ^2.4.0
- `url_launcher`: ^6.2.1 → ^6.3.1

#### Firebase
- `firebase_core`: ^2.24.0 → ^3.6.0 (Major version - breaking changes)
- `firebase_messaging`: ^14.7.0 → ^15.1.3 (Major version - breaking changes)

#### PDF
- `pdf`: ^3.10.7 → ^3.11.1
- `printing`: ^5.11.1 → ^5.13.3
- `open_file`: ^3.3.2 → ^3.5.7

#### Dev Dependencies
- `flutter_lints`: ^3.0.0 → ^4.0.0
- `build_runner`: ^2.4.6 → ^2.4.13

## Breaking Changes to Watch

### 1. connectivity_plus (5.0.0 → 6.0.5)
**Breaking Changes:**
- Removed deprecated `checkConnectivity()` method
- Now uses `onConnectivityChanged` stream exclusively
- Platform-specific behavior changes

**Migration:**
```dart
// Old
final result = await Connectivity().checkConnectivity();

// New
final connectivityResult = await (Connectivity().checkConnectivity());
```

### 2. geolocator (10.1.0 → 13.0.1)
**Breaking Changes:**
- Updated permission handling
- New accuracy modes
- Stream API improvements

**Migration:**
Check the geolocator migration guide for detailed changes.

### 3. Firebase (Major version bumps)
**firebase_core (2.x → 3.x):**
- Initialization changes
- Platform-specific configuration updates

**firebase_messaging (14.x → 15.x):**
- Notification handling changes
- Background message handling updates

**Action Required:**
- Update `google-services.json` and `GoogleService-Info.plist`
- Review Firebase console settings
- Test notification flows thoroughly

### 4. file_picker (6.0.0 → 8.1.2)
**Breaking Changes:**
- API signature changes
- New platform-specific options
- Improved file filtering

## Installation Steps

### 1. Clean Previous Build
```bash
flutter clean
```

### 2. Get Dependencies
```bash
flutter pub get
```

### 3. Generate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Update Platform-Specific Files

#### Android (android/app/build.gradle)
Ensure minimum SDK version:
```gradle
minSdkVersion 21
targetSdkVersion 34
compileSdkVersion 34
```

#### Android Permissions (android/app/src/main/AndroidManifest.xml)
Verify all permissions are declared:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `INTERNET`

### 5. Test Core Functionality
- [ ] Authentication flow
- [ ] Image picker (camera + gallery)
- [ ] File picker
- [ ] Location services
- [ ] Connectivity detection
- [ ] Firebase notifications
- [ ] PDF generation/viewing

## Potential Issues and Fixes

### Issue 1: Connectivity Plus Breaking Changes
**Symptom:** `checkConnectivity()` method not found

**Fix:**
Update connectivity usage in:
- `lib/data/services/api_service.dart`
- Any network status checks

```dart
// Update to use stream
final subscription = Connectivity().onConnectivityChanged.listen((result) {
  // Handle connectivity change
});
```

### Issue 2: Geolocator Permission Handling
**Symptom:** Location permission errors

**Fix:**
Update `lib/data/services/location_service.dart`:
```dart
LocationPermission permission = await Geolocator.requestPermission();
```

### Issue 3: Firebase Initialization
**Symptom:** Firebase initialization errors

**Fix:**
Update `lib/main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Issue 4: File Picker API Changes
**Symptom:** `FilePickerResult` null safety issues

**Fix:**
Update file picker usage:
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
);
```

## Testing Checklist

After updating dependencies:

- [ ] Run `flutter doctor` to verify setup
- [ ] Run `flutter pub get` successfully
- [ ] Run `build_runner` to generate code
- [ ] Build Android APK without errors
- [ ] Test on physical device (not just emulator)
- [ ] Verify camera access works
- [ ] Verify file picker works
- [ ] Verify location services work
- [ ] Test network connectivity detection
- [ ] Test Firebase messaging (if configured)
- [ ] Check PDF generation/viewing
- [ ] Verify TUS uploads work

## Rollback Plan

If issues arise, revert to previous versions:

```bash
git checkout HEAD -- pubspec.yaml
flutter clean
flutter pub get
```

## Additional Resources

- [Flutter Breaking Changes](https://docs.flutter.dev/release/breaking-changes)
- [Pub.dev Changelog](https://pub.dev)
- [Firebase Flutter Migration Guide](https://firebase.flutter.dev/docs/migration)
- [Connectivity Plus Migration](https://pub.dev/packages/connectivity_plus/changelog)
- [Geolocator Migration](https://pub.dev/packages/geolocator/changelog)

## Support

If you encounter issues:
1. Check package changelogs on pub.dev
2. Review GitHub issues for the specific package
3. Consult Flutter documentation
4. Test on latest Flutter stable version
