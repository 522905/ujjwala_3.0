# Build Instructions

## Prerequisites

- Flutter SDK >=3.0.0 <4.0.0
- Android Studio or VS Code with Flutter extensions
- Android SDK for Android development

## Step 1: Install Dependencies

```bash
flutter pub get
```

This will download all packages specified in `pubspec.yaml`.

## Step 2: Generate Hive Adapters

The project uses Hive for local database storage. You must generate the type adapters before the app can compile.

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This command will:
- Generate all Hive TypeAdapters for data models
- Create `.g.dart` files next to model files
- Delete any conflicting outputs from previous builds

**Generated files:**
- `lib/data/models/local_application.g.dart`
- `lib/data/models/local_address.g.dart`
- `lib/data/models/local_family_member.g.dart`
- `lib/data/models/local_document.g.dart`

## Step 3: Verify Build

Run the build to check for any compilation errors:

```bash
flutter build apk --debug
```

Or run directly on a connected device/emulator:

```bash
flutter run
```

## Step 4: Common Build Issues

### Issue: "No part directive found"

**Solution:** Ensure all model files have the `part` directive:
```dart
part 'local_application.g.dart';
```

### Issue: "Duplicate definition"

**Solution:** Delete all `.g.dart` files and regenerate:
```bash
find lib -name "*.g.dart" -delete
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "MissingPluginException"

**Solution:** Rebuild the app after installing dependencies:
```bash
flutter clean
flutter pub get
flutter run
```

## Step 5: Firebase Setup (Optional)

For push notifications to work, you need to:

1. Create a Firebase project at https://console.firebase.google.com
2. Add Android app to your Firebase project
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Rebuild the app

**Note:** The app will work without Firebase, but notifications will not function.

## Step 6: Backend Configuration

Update the backend URL in `lib/core/config/api_config.dart`:

```dart
static const String currentEnv = 'production'; // Change to your environment
```

**Environments:**
- `development`: http://localhost:8000
- `staging`: http://staging.api.arungas.com
- `production`: https://api.arungas.com

## Production Build

To create a production release:

```bash
flutter build apk --release
```

Or for app bundle (recommended for Play Store):

```bash
flutter build appbundle --release
```

The output will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Troubleshooting

### Clean Build

If you encounter persistent issues:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Check Flutter Doctor

Ensure your environment is set up correctly:

```bash
flutter doctor -v
```

### Gradle Issues

If you have Gradle sync problems:

```bash
cd android
./gradlew clean
cd ..
flutter run
```

## File Structure Summary

```
lib/
├── core/
│   ├── config/          # API and app configuration
│   ├── enums/           # All enumerations
│   └── utils/           # Validators and utilities
├── data/
│   ├── local/           # Hive database service
│   ├── models/          # Hive data models (*.g.dart generated here)
│   ├── repositories/    # Data repositories
│   └── services/        # API, TUS, compression services
├── providers/           # State management (Provider)
├── presentation/        # UI screens
│   ├── auth/           # Authentication screens
│   ├── dashboard/      # Home and navigation
│   ├── forms/          # 7-step form wizard
│   └── submission/     # Submission flow screens
└── main.dart           # App entry point
```

## Next Steps After Build

1. Test authentication flow (User login, Agent signup, Agent login)
2. Test 7-step application form
3. Test document upload (requires camera/gallery permissions)
4. Test application submission
5. Configure backend API endpoints
6. Set up Firebase for notifications
7. Test on multiple devices/screen sizes

## Support

For issues or questions:
- Check existing documentation in project root
- Review code comments in source files
- Consult Flutter documentation: https://docs.flutter.dev
