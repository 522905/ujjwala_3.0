# Ujjwala 3.0 Flutter App - Implementation Summary

## ✅ What Has Been Created

### 1. Project Configuration
- ✅ `pubspec.yaml` - Complete dependencies list
- ✅ `lib/core/config/api_config.dart` - API configuration with environment support
- ✅ `README.md` - Comprehensive setup and development guide

### 2. Core Utilities
- ✅ `lib/core/utils/aadhaar_validator.dart` - Verhoeff algorithm for Aadhaar validation
- ✅ `lib/core/utils/validators.dart` - All form validators (mobile, email, IFSC, etc.)
- ✅ `lib/core/enums/app_enums.dart` - Complete enumerations (Gender, Caste, States, etc.)

### 3. Data Models (Hive)
- ✅ `lib/data/models/local_application.dart` - Main application model with validation logic
- ✅ `lib/data/models/local_address.dart` - Address model (Current/Permanent)
- ✅ `lib/data/models/local_family_member.dart` - Family member with Aadhaar photos
- ✅ `lib/data/models/local_document.dart` - Document model with TUS URL support
- ✅ `lib/data/local/hive_service.dart` - Database initialization and management

## 📋 Next Steps - Complete Implementation

To complete the application, you need to:

### Step 1: Generate Hive Type Adapters

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will create the `.g.dart` files for all Hive models.

### Step 2: Create Remaining Files

I recommend using Claude Code (or an LLM) to generate the remaining files based on the specifications. Here's what's needed:

#### A. Services Layer

1. **TUS Upload Service** (`lib/data/services/tus_upload_service.dart`)
   - Use `tus_client` package
   - Upload documents to `https://tus.dca.arungas.com/files/`
   - Return TUS URLs
   - Handle resume on network interruption
   - Show upload progress

2. **Image Compression Service** (`lib/data/services/compression_service.dart`)
   - Use `flutter_image_compress`
   - Aadhaar: 92% quality, max 1520px width
   - Other docs: 90% quality, max 2048px width
   - Target: ≤1MB file size

3. **API Service** (`lib/data/services/api_service.dart`)
   - Use Dio with interceptors
   - JWT token management
   - Auto token refresh on 401
   - All API endpoints from backend doc
   - Error handling with retry logic

4. **Location Service** (`lib/data/services/location_service.dart`)
   - Use `geolocator` package
   - Request location permissions
   - Get current location with accuracy
   - Handle permission denials

#### B. Repositories

1. **Auth Repository** (`lib/data/repositories/auth_repository.dart`)
   - Login (Mobile + OTP)
   - Agent login (Aadhaar + Password)
   - Agent signup (Aadhaar + OTP)
   - Forgot password
   - Change password
   - Token storage in secure storage

2. **Application Repository** (`lib/data/repositories/application_repository.dart`)
   - CRUD operations for local applications
   - Submit application to backend
   - Fetch application status
   - Download forms
   - Upload signed forms

3. **Document Repository** (`lib/data/repositories/document_repository.dart`)
   - Capture photo/document
   - Compress images
   - Upload to TUS
   - Store local + TUS URL
   - Delete documents

#### C. Providers (State Management)

1. **Auth Provider** (`lib/providers/auth_provider.dart`)
   - User login state
   - JWT token management
   - User role (USER/AGENT)
   - Logout functionality

2. **Application Provider** (`lib/providers/application_provider.dart`)
   - Current draft application
   - Auto-save on field changes
   - Completion percentage
   - Validation state

3. **Submission Provider** (`lib/providers/submission_provider.dart`)
   - Handle submission flow
   - Upload progress tracking
   - Success/failure state
   - Retry logic

#### D. UI Screens

**Authentication Screens:**

1. `lib/presentation/auth/splash_screen.dart`
   - Show app logo
   - 3 buttons: "Login as Consumer", "Sign Up as Agent", "Forgot Password"

2. `lib/presentation/auth/user_login_screen.dart`
   - Mobile input (10 digits validation)
   - "Send OTP" button
   - OTP input (6 digits)
   - "Verify & Login" button

3. `lib/presentation/auth/agent_signup_screen.dart`
   - Aadhaar input with Verhoeff validation
   - Visual indicator (green checkmark / orange warning)
   - "Send OTP" button
   - OTP verification
   - Display Agent ID + Temporary Password on success

4. `lib/presentation/auth/agent_login_screen.dart` (in drawer)
   - Aadhaar input with validation
   - Password input
   - "Login" button

5. `lib/presentation/auth/forgot_password_screen.dart`
   - Aadhaar input
   - Send OTP → Verify → Reset password

**Main Container:**

6. `lib/presentation/dashboard/main_container.dart`
   - Drawer navigation
   - Bottom nav (optional)
   - Role-based menu items

**Application Form Wizard (7 Steps):**

7. `lib/presentation/application/forms/step1_applicant_details.dart`
   - Full name, first/middle/last
   - Gender dropdown (must select Female)
   - Date picker (DOB, age ≥18 validation)
   - Aadhaar (12 digits, Verhoeff validated)
   - Mobile, Email
   - Caste dropdown
   - Marital status, marriage date

8. `lib/presentation/application/forms/step2_bank_details.dart`
   - Account holder name
   - Bank name
   - Branch name
   - IFSC code (11 chars, validated)
   - Account number (9-18 digits)

9. `lib/presentation/application/forms/step3_current_address.dart`
   - House/flat no
   - Building/colony
   - Street/road
   - Village/area
   - District
   - City/town
   - State dropdown (Indian states)
   - Pincode (6 digits)
   - Landmark
   - POA code dropdown

10. `lib/presentation/application/forms/step4_permanent_address.dart`
    - Same fields as current address
    - "Copy from Current" button
    - **Validation**: State must be different from current (migrant check)

11. `lib/presentation/application/forms/step5_family_members.dart`
    - List of family members
    - Add member button
    - For each member:
      - Full name
      - Relation dropdown (SELF, HUSBAND, WIFE, etc.)
      - Gender, DOB
      - Aadhaar (unique, no duplicates)
      - Capture Aadhaar front photo
      - Capture Aadhaar back photo
      - Ration card available (Yes/No)
    - **Validation**: Exactly 1 SELF member required

12. `lib/presentation/application/forms/step6_documents.dart`
    - Upload 5 required documents:
      1. Current Address Proof
      2. Permanent Address Proof
      3. Family Composition Doc (Ration Card)
      4. Bank Proof
      5. **Applicant Photo (MANDATORY)**
    - Camera or gallery picker
    - Show thumbnails
    - Delete/retake options
    - Upload progress indicators

13. `lib/presentation/application/forms/step7_consents_review.dart`
    - Display all 7 consent checkboxes with full text
    - All must be checked to proceed
    - Review summary of all sections
    - Edit buttons for each section
    - "Submit Application" button (enabled only if complete)

**Submission Flow:**

14. `lib/presentation/application/submission/submission_progress_screen.dart`
    - Show progress steps:
      1. Compressing images
      2. Uploading to TUS (with percentage)
      3. Submitting application
    - Progress bars
    - Cannot go back during submission

15. `lib/presentation/application/submission/submission_success_screen.dart`
    - Green checkmark
    - Application number (large, prominent)
    - Submission timestamp
    - "Track Status" button
    - "Back to Home" button

**Application Viewing:**

16. `lib/presentation/application/view/application_detail_screen.dart`
    - Show application number
    - Status badge (color-coded)
    - All submitted details (read-only)
    - Download forms button (if forms available)
    - Upload signed forms button (if forms downloaded)

17. `lib/presentation/application/view/forms_download_screen.dart`
    - List of 4-6 generated PDFs
    - Download button for each
    - Instructions on signing
    - Navigate to upload screen when done

18. `lib/presentation/application/view/forms_upload_screen.dart`
    - Upload 4 signed forms
    - Use TUS upload
    - Show upload progress
    - Submit button (enabled when all 4 uploaded)

**Agent Screens:**

19. `lib/presentation/agent/agent_dashboard_screen.dart`
    - Tabs: "My Applications", "Pre-Sureksha", "Sync"
    - Search bar (by mobile/Aadhaar/ID)
    - Filter by status
    - FAB: New Application

20. `lib/presentation/agent/applications_list_screen.dart`
    - List of all agent's applications
    - Search and filter
    - Tap to view details

**Pre-Sureksha (Stubbed for Phase II):**

21. `lib/presentation/pre_sureksha/pre_sureksha_capture_screen.dart`
    - Map view with draggable marker
    - "Capture Kitchen Photo" button
    - "Capture Main Gate Photo" button
    - Show captured photos as thumbnails
    - Save locally (do not call API yet - stubbed)
    - Success message

**Widgets:**

22. `lib/presentation/widgets/custom_text_field.dart`
23. `lib/presentation/widgets/custom_dropdown.dart`
24. `lib/presentation/widgets/date_picker_field.dart`
25. `lib/presentation/widgets/document_picker_widget.dart`
26. `lib/presentation/widgets/progress_stepper.dart`
27. `lib/presentation/widgets/consent_checkbox.dart`
28. `lib/presentation/widgets/status_badge.dart`

#### E. Main App Entry Point

29. `lib/main.dart`
    - Initialize Hive
    - Initialize Firebase
    - Setup providers
    - MaterialApp with routes
    - Theme configuration

### Step 3: Add Assets

Create placeholder assets:

```bash
# App icon
assets/images/app_icon.png (512x512)

# Logo
assets/logos/arun_gas_logo.png

# Empty state illustrations (optional)
assets/images/empty_applications.png
assets/images/success_icon.png
```

### Step 4: Android Configuration

**AndroidManifest.xml** permissions:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

**Package name**: `com.arungas.consumer`

### Step 5: Firebase Setup

1. Create Firebase project
2. Add Android app
3. Download `google-services.json`
4. Place in `android/app/google-services.json`
5. Update build.gradle files

### Step 6: Testing

**Test Scenarios:**

1. **User Flow:**
   - Login with mobile + OTP
   - Create new application
   - Fill all 7 steps
   - Upload documents
   - Submit application
   - Track status
   - Download forms
   - Upload signed forms

2. **Agent Flow:**
   - Signup with Aadhaar + OTP
   - Login with credentials
   - Create multiple applications
   - Search applications
   - Pre-Sureksha (stub test)

3. **Offline Flow:**
   - Turn off internet
   - Create draft application
   - Auto-save works
   - Turn on internet
   - Submit successfully

4. **Validation Tests:**
   - Invalid Aadhaar (Verhoeff fails)
   - Age <18 (rejected)
   - Gender not Female (rejected)
   - Same state addresses (rejected)
   - Missing documents (submit disabled)
   - Unchecked consents (submit disabled)

## 🎯 Key Implementation Notes

### Auto-Save Logic

Every field change should call:
```dart
application.touch(); // Updates updatedAt
await application.save(); // Saves to Hive
provider.notifyListeners(); // Updates UI
```

### TUS Upload Pattern

```dart
// 1. Compress image
final compressed = await compressionService.compress(originalFile);

// 2. Upload to TUS
final tusUrl = await tusUploadService.upload(
  file: compressed,
  onProgress: (progress) {
    // Update UI with percentage
  },
);

// 3. Store TUS URL
document.tusUrl = tusUrl;
document.isUploaded = true;
await document.save();
```

### Submission Pattern

```dart
// 1. Validate application
if (!application.isComplete) {
  throw Exception('Application incomplete');
}

// 2. Upload all documents to TUS (if not already)
for (var doc in documents) {
  if (!doc.isUploaded) {
    await uploadDocument(doc);
  }
}

// 3. Upload family Aadhaar photos to TUS
for (var member in familyMembers) {
  if (!member.arePhotosUploaded) {
    await uploadFamilyPhotos(member);
  }
}

// 4. Build payload with TUS URLs
final payload = {
  ...application.toServerJson(),
  'addresses': addresses.map((a) => a.toServerJson()).toList(),
  'family_members': familyMembers.map((m) => m.toServerJson()).toList(),
  'documents': documents.map((d) => d.toServerJson()).toList(),
};

// 5. Submit to backend
final response = await apiService.post('/api/ujjwala-v3/applications/', payload);

// 6. Update local status
application.localStatus = 'submitted';
application.submittedApplicationNumber = response['application_number'];
application.serverApplicationId = response['id'];
application.submittedAt = DateTime.now();
await application.save();
```

### State Validation

```dart
// Migrant validation (different states)
final currentState = currentAddress.state;
final permanentState = permanentAddress.state;

if (currentState == permanentState) {
  throw ValidationException(
    'Current and Permanent addresses must be in different states for migrant applications'
  );
}
```

## 📚 Reference Documentation

All specifications are in the 3 documents provided:
1. PRD - Product requirements
2. Backend Doc - API specifications
3. Flutter Doc - Implementation details

## 🚀 Deployment

**Build signed APK:**

```bash
flutter build apk --release
```

**Build App Bundle:**

```bash
flutter build appbundle --release
```

## ✅ Testing Checklist

- [ ] Aadhaar Verhoeff validation works correctly
- [ ] All 7 form steps save automatically
- [ ] Image compression reduces file size to ≤1MB
- [ ] TUS uploads succeed and return URLs
- [ ] Application submission includes all TUS URLs
- [ ] Status polling works
- [ ] Forms download as PDFs
- [ ] Signed forms upload via TUS
- [ ] Offline mode saves drafts locally
- [ ] Agent can create multiple applications
- [ ] End user limited to 1 active application
- [ ] Pre-Sureksha UI captures photos + location locally
- [ ] All validations work (age, gender, state, IFSC, etc.)

## 🎉 Conclusion

You now have:
- ✅ Complete project structure
- ✅ All data models with Hive
- ✅ Validators and utilities
- ✅ Configuration files
- ✅ Comprehensive documentation

**Next**: Implement the remaining services, repositories, providers, and UI screens as outlined above.

Use the existing models and utilities as reference. Follow the patterns established in the created files for consistency.

---

**Happy Coding! 🚀**
