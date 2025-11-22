# Arun Gas Consumer App - Ujjwala 3.0

Flutter mobile application for LPG Ujjwala 3.0 (PMUY for Migrant Households) with offline-first architecture.

## Features

- ✅ **Offline-First Architecture**: Complete application form filling without internet
- ✅ **TUS Resumable Uploads**: Reliable document uploads with resume capability
- ✅ **Dual Authentication**: End Users (Mobile + OTP) and Agents (Aadhaar + Password)
- ✅ **7-Step Application Wizard**: Intuitive form with auto-save
- ✅ **Role-Based Access**: Different features for End Users vs Agents
- ✅ **Document Management**: Camera/gallery support with compression
- ✅ **Status Tracking**: Real-time application status monitoring
- ✅ **Forms Download/Upload**: Post-submission forms workflow
- ✅ **Pre-Sureksha**: Kitchen/gate photo capture with location (Phase II ready)

## Project Structure

```
lib/
├── core/
│   ├── config/          # API configuration
│   ├── enums/           # Application enumerations
│   └── utils/           # Validators, Aadhaar verification
├── data/
│   ├── local/           # Hive database service
│   ├── models/          # Local data models (Hive)
│   ├── repositories/    # Data repositories
│   └── services/        # API, TUS upload, compression services
├── presentation/
│   ├── auth/            # Authentication screens
│   ├── dashboard/       # Main dashboard
│   ├── application/     # Application forms & submission
│   ├── pre_sureksha/    # Pre-sureksha (stubbed)
│   └── widgets/         # Reusable UI components
└── providers/           # State management (Provider)
```

## Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK (API 21+)

## Setup Instructions

### 1. Clone the Repository

```bash
cd ujjwala_3.0
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Generate Hive Type Adapters

The project uses Hive for local database storage. You need to generate type adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/data/models/local_application.g.dart`
- `lib/data/models/local_address.g.dart`
- `lib/data/models/local_family_member.g.dart`
- `lib/data/models/local_document.g.dart`

**Note**: If you make changes to any Hive models (annotated with `@HiveType`), you need to re-run this command.

### 4. Configure API Base URL

Edit `lib/core/config/api_config.dart` and update the base URLs:

```dart
static const String developmentBaseUrl = 'https://dev.arungas.com';
static const String stagingBaseUrl = 'https://staging.arungas.com';
static const String productionBaseUrl = 'https://api.arungas.com';
```

Change `currentEnvironment` to select the active environment:

```dart
static const Environment currentEnvironment = Environment.development;
```

### 5. Add Assets

Create the following directories and add placeholder images:

```bash
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/logos
mkdir -p fonts
```

Add a placeholder app icon:
- `assets/images/app_icon.png` (512x512 px)

Add Roboto fonts (if using custom fonts):
- `fonts/Roboto-Regular.ttf`
- `fonts/Roboto-Bold.ttf`

Or remove the fonts section from `pubspec.yaml` to use default fonts.

### 6. Firebase Setup (for Push Notifications)

1. Create a Firebase project at https://console.firebase.google.com/
2. Add Android app with package name: `com.arungas.consumer`
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`
5. Update `android/build.gradle` (if not already done):

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

6. Update `android/app/build.gradle` (add at bottom):

```gradle
apply plugin: 'com.google.gms.google-services'
```

### 7. Run the App

```bash
flutter run
```

For release build:

```bash
flutter build apk --release
```

## Key Technologies

- **State Management**: Provider
- **Local Database**: Hive (NoSQL)
- **Secure Storage**: flutter_secure_storage (JWT tokens)
- **Networking**: Dio with interceptors
- **File Upload**: TUS Client (resumable uploads)
- **Image Handling**: image_picker, flutter_image_compress
- **Location**: geolocator
- **Push Notifications**: Firebase Messaging

## Architecture

### Offline-First Strategy

1. **Local Draft Storage**: All form data saved in Hive database
2. **Auto-Save**: Every field change automatically saved
3. **TUS Uploads**: Documents uploaded to TUS server, URLs stored
4. **Single Submission**: Complete application with TUS URLs submitted once
5. **Status Sync**: Poll backend for status updates

### Data Flow

```
User Input → Hive Database (Local) → Compress Images → Upload to TUS
  → Get TUS URLs → Build JSON Payload → Submit to Backend → Track Status
```

## User Roles

### End User
- Login: Mobile + OTP
- Max 1 active application (draft + submitted)
- Simple, guided workflow

### Agent
- Login: Aadhaar + Password
- Signup: Aadhaar + OTP → Admin approval → SMS with credentials
- Multiple draft applications
- Search & manage applications
- Pre-Sureksha tasks

## Application Workflow

1. **Applicant Details**: Name, DOB, Aadhaar, Gender (must be Female), Mobile
2. **Bank Details**: Account name, Bank, Branch, IFSC, Account number
3. **Current Address**: Full address with state and pincode
4. **Permanent Address**: Different state required (migrant validation)
5. **Family Members**: Add SELF + family with Aadhaar photos
6. **Documents**: Upload 5 required documents + applicant photo
7. **Consents**: All 7 consents must be signed
8. **Review & Submit**: Validate and submit with TUS URLs

### Required Documents
1. Current Address Proof
2. Permanent Address Proof
3. Family Composition Document (Ration Card)
4. Bank Proof
5. **Applicant Photo** (MANDATORY)
6. Family Aadhaar Photos (front + back for each member)

### Post-Submission
- 72-hour pre-validation period
- Download 4-6 generated forms (Annexure-I, Deprivation, etc.)
- Print, sign, scan forms
- Upload signed forms via TUS
- Admin review: Approved or Correction Required

## Validation Rules

- **Gender**: Must be Female (F)
- **Age**: Minimum 18 years
- **Aadhaar**: 12 digits with Verhoeff checksum validation
- **Mobile**: 10 digits, starting with 6-9
- **IFSC**: 11 characters, alphanumeric
- **Pincode**: 6 digits
- **States**: Current ≠ Permanent (migrant validation)
- **Family**: Minimum 1 SELF member, no duplicate Aadhaar
- **Consents**: All 7 must be true

## API Endpoints (Backend)

See `lib/core/config/api_config.dart` for all endpoint URLs.

**Authentication:**
- POST `/auth/send-otp/`
- POST `/auth/login/`
- POST `/auth/token/refresh/`
- POST `/auth/agent/signup/`
- POST `/auth/agent/change-password/`

**Applications:**
- POST `/api/ujjwala-v3/applications/` (submit with TUS URLs)
- GET `/api/ujjwala-v3/applications/`
- GET `/api/ujjwala-v3/applications/{id}/`
- GET `/api/ujjwala-v3/applications/{id}/forms/` (download generated PDFs)
- POST `/api/ujjwala-v3/applications/{id}/submit-forms/` (upload signed forms)

**TUS Upload Server:**
- `https://tus.dca.arungas.com/files/`

## Development Guidelines

### Running Build Runner Watch Mode

For continuous code generation during development:

```bash
flutter pub run build_runner watch
```

### Code Generation

After modifying Hive models, repositories, or any file with code generation annotations:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Debugging

Enable verbose logging in `lib/core/config/api_config.dart`:

```dart
// Add to Dio configuration
dio.interceptors.add(LogInterceptor(
  request: true,
  requestBody: true,
  responseBody: true,
  error: true,
));
```

## Troubleshooting

### Hive Type Adapter Not Found

**Error**: `Cannot read, unknown type...`

**Solution**: Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### TUS Upload Fails

**Error**: `Connection refused` or `Network error`

**Solution**: Check TUS server URL in `api_config.dart` and ensure internet connectivity.

### JWT Token Expired

The app automatically refreshes tokens using refresh token. If refresh fails, user is logged out.

### Build Errors

1. Clean build:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

2. Clear Hive boxes (if data corruption):
```dart
// In app, call:
await HiveService.clearAll();
```

## Testing

### Test Credentials

**End User:**
- Mobile: 9999999999
- OTP: 123456

**Agent:**
- Aadhaar: 999999999999
- Password: Test@1234

## Production Checklist

- [ ] Update API base URL to production
- [ ] Enable ProGuard/R8 obfuscation
- [ ] Generate signed APK with release key
- [ ] Test on multiple Android versions (API 21+)
- [ ] Test offline functionality
- [ ] Test TUS upload resume capability
- [ ] Verify Firebase push notifications
- [ ] Test image compression quality
- [ ] Verify Aadhaar Verhoeff validation
- [ ] Test state mismatch validation (migrant)
- [ ] Load test with large documents (up to 5MB)

## License

Proprietary - Arun Gas Services

## Support

For issues and questions, contact the development team.

---

**Version**: 1.0.0
**Last Updated**: November 2025
**Platform**: Android Only
