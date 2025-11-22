# Screens Implementation Guide

## What's Been Created

✅ **Services** (5 files): TUS Upload, API, Compression, Location, Notification
✅ **Repositories** (3 files): Auth, Application, Document
✅ **Providers** (3 files): Auth, Application, Submission
✅ **Splash Screen**: Entry point with 3 buttons

## Screens to Implement

This document provides the structure and key code snippets for all remaining screens.

---

## 1. Authentication Screens

### 1.1 UserLoginScreen
**File**: `lib/presentation/auth/user_login_screen.dart`

**Features**:
- Mobile input (10 digits)
- "Send OTP" button
- OTP input (6 digits)
- "Verify & Login" button

**Key Code**:
```dart
final _mobileController = TextEditingController();
final _otpController = TextEditingController();
bool _otpSent = false;

// Send OTP
await Provider.of<AuthProvider>(context, listen: false).sendOtp(mobile);
setState(() { _otpSent = true; });

// Login
final success = await Provider.of<AuthProvider>(context, listen: false)
    .loginWithOtp(mobile: mobile, otp: otp);
if (success) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => MainContainer()),
  );
}
```

### 1.2 AgentSignupScreen
**File**: `lib/presentation/auth/agent_signup_screen.dart`

**Features**:
- Aadhaar input with Verhoeff validation
- Visual validation indicator (green checkmark / orange warning)
- Name, Mobile, Address inputs
- "Submit KYC" button
- Success screen showing Agent ID + Temp Password

**Key Code**:
```dart
import '../../core/utils/aadhaar_validator.dart';

// Validate Aadhaar on change
_aadhaarController.addListener(() {
  final validation = AadhaarValidator.getValidationState(_aadhaarController.text);
  setState(() { _validationState = validation; });
});

// Visual indicator
Widget _buildValidationIcon() {
  if (_validationState == null) return SizedBox();
  return Icon(
    _validationState! ? Icons.check_circle : Icons.warning,
    color: _validationState! ? Colors.green : Colors.orange,
  );
}

// Submit
final response = await authProvider.agentSignup(...);
if (response != null) {
  // Show success dialog with Agent ID and Temp Password
  showDialog(...);
}
```

### 1.3 AgentLoginScreen
**File**: `lib/presentation/auth/agent_login_screen.dart`

**Features**:
- Accessed from drawer (not splash)
- Aadhaar input with validation
- Password input
- "Login" button

**Key Code**:
```dart
final success = await Provider.of<AuthProvider>(context, listen: false)
    .loginWithPassword(aadhaar: aadhaar, password: password);
```

### 1.4 ForgotPasswordScreen
**File**: `lib/presentation/auth/forgot_password_screen.dart`

**Features**:
- Aadhaar input → Send OTP
- OTP verification
- New password + Confirm password
- "Reset Password" button

**Key Code**:
```dart
// Step 1: Send OTP
await authProvider.forgotPasswordInitiate(aadhaar);

// Step 2: Verify OTP
await authProvider.forgotPasswordVerifyOtp(aadhaar: aadhaar, otp: otp);

// Step 3: Reset
await authProvider.forgotPasswordReset(
  aadhaar: aadhaar,
  otp: otp,
  newPassword: newPassword,
);
```

### 1.5 ChangePasswordScreen
**File**: `lib/presentation/auth/change_password_screen.dart`

**Features**:
- Accessed from drawer (when agent is logged in)
- New password input
- Confirm password input
- "Change Password" button

**Key Code**:
```dart
await authProvider.changePassword(
  newPassword: newPassword,
  confirmPassword: confirmPassword,
);
```

---

## 2. Main Container & Navigation

### 2.1 MainContainer
**File**: `lib/presentation/dashboard/main_container.dart`

**Features**:
- Drawer with navigation
- Role-based menu items
- Main content area

**Drawer Menu**:
- **For All**: My Profile, Logout
- **For Agents Only**: Agent Login (if not logged in), Change Password, View All Applications, Pre-Sureksha
- **For Users**: My Application

**Key Code**:
```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        child: Column(
          children: [
            Icon(Icons.person, size: 60),
            Text('Role: ${authProvider.userRole?.display}'),
          ],
        ),
      ),
      ListTile(
        title: Text('My Application'),
        onTap: () => Navigator.push(...),
      ),
      if (authProvider.isAgent) ...[
        ListTile(
          title: Text('All Applications'),
          onTap: () => Navigator.push(...),
        ),
        ListTile(
          title: Text('Pre-Sureksha'),
          onTap: () => Navigator.push(...),
        ),
        ListTile(
          title: Text('Change Password'),
          onTap: () => Navigator.push(...),
        ),
      ],
      ListTile(
        title: Text('Logout'),
        onTap: () async {
          await authProvider.logout();
          Navigator.pushReplacement(...SplashScreen...);
        },
      ),
    ],
  ),
)
```

---

## 3. Application Form Wizard (7 Steps)

All forms use `ApplicationProvider` for auto-save.

**Pattern**:
```dart
final appProvider = Provider.of<ApplicationProvider>(context, listen: false);

// Auto-save on field change
appProvider.updateApplicantField('applicant_full_name', value);
```

### 3.1 Step 1: Applicant Details
**File**: `lib/presentation/application/forms/step1_applicant_details.dart`

**Fields**:
- Full Name (required)
- First/Middle/Last Name
- Gender (dropdown - must select Female)
- Date of Birth (date picker - age ≥18 validation)
- Aadhaar (12 digits with Verhoeff validation)
- Mobile (10 digits)
- Email (optional)
- Caste (dropdown)
- Marital Status (dropdown)
- Marriage Date (if married)

**Next Button**: Enabled when all required fields valid

### 3.2 Step 2: Bank Details
**File**: `lib/presentation/application/forms/step2_bank_details.dart`

**Fields**:
- Account Holder Name
- Bank Name
- Branch Name
- IFSC Code (11 chars validation)
- Account Number (9-18 digits)

### 3.3 Step 3: Current Address
**File**: `lib/presentation/application/forms/step3_current_address.dart`

**Fields** (all from PRD):
- House/Flat No, Floor, Building/Colony, Street/Road
- Village/Area, Block, District, City, State (dropdown), Pincode (6 digits)
- Landmark (optional)
- POA Code (dropdown)

**Save**:
```dart
final currentAddress = LocalAddress(
  localId: Uuid().v4(),
  applicationLocalId: app.localId,
  addressType: 'CURRENT',
  state: selectedState,
  ...
);
await appProvider.saveAddress(currentAddress);
```

### 3.4 Step 4: Permanent Address
**File**: `lib/presentation/application/forms/step4_permanent_address.dart`

**Features**:
- Same fields as Step 3
- "Copy from Current" button
- **Validation**: State must be different from Current (migrant check)

**Validation**:
```dart
if (currentAddress.state == permanentAddress.state) {
  throw 'For migrant applications, states must be different';
}
```

### 3.5 Step 5: Family Members
**File**: `lib/presentation/application/forms/step5_family_members.dart`

**Features**:
- List of added family members
- FAB: Add Member button
- For each member:
  - Full Name, Relation (dropdown), Gender, DOB, Aadhaar
  - Capture Aadhaar Front Photo (camera/gallery)
  - Capture Aadhaar Back Photo (camera/gallery)
  - Ration Card Available (Yes/No)
- **Validation**: Exactly 1 SELF member required

**Add Member Dialog**:
```dart
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Add Family Member'),
    content: SingleChildScrollView(
      child: Column(
        children: [
          TextField(...), // Name
          DropdownButtonFormField(...), // Relation
          // ...
          ElevatedButton(
            onPressed: () async {
              // Capture photo
              final doc = await documentRepo.capturePhoto(...);
              // Store in member
              member.uidFrontLocalPath = doc.localFilePath;
            },
            child: Text('Capture Aadhaar Front'),
          ),
        ],
      ),
    ),
  ),
);
```

**Save Member**:
```dart
final member = LocalFamilyMember(
  localId: Uuid().v4(),
  applicationLocalId: app.localId,
  fullName: name,
  relationToApplicant: relation,
  ...
);
await appProvider.saveFamilyMember(member);
```

### 3.6 Step 6: Documents
**File**: `lib/presentation/application/forms/step6_documents.dart`

**Required Documents** (6):
1. Current Address Proof
2. Permanent Address Proof
3. Family Composition Document
4. Bank Proof
5. **Applicant Photo** (MANDATORY)
6. (Family Aadhaar photos already captured in Step 5)

**Upload Flow**:
```dart
// 1. Capture/Pick
final XFile? photo = await ImagePicker().pickImage(...);

// 2. Compress
final compressed = await compressionService.compressDocumentPhoto(File(photo.path));

// 3. Upload to TUS
final tusUrl = await tusService.uploadWithRetry(
  file: compressed,
  filename: '${docType}.jpg',
  onProgress: (progress) {
    setState(() { _uploadProgress = progress; });
  },
);

// 4. Create LocalDocument with TUS URL
final doc = LocalDocument(
  localId: Uuid().v4(),
  applicationLocalId: app.localId,
  docType: docType.value,
  tusUrl: tusUrl,
  isUploaded: true,
  ...
);

// 5. Save
await appProvider.addDocument(doc);
```

**UI**:
- Grid of document cards
- Each card shows: Document type, upload button, thumbnail (if uploaded), delete button
- Progress bar during upload

### 3.7 Step 7: Consents & Review
**File**: `lib/presentation/application/forms/step7_consents_review.dart`

**Features**:
- Show all 7 consent checkboxes with full text
- Summary of all sections (applicant, bank, addresses, family, documents)
- Edit buttons for each section
- **Submit Button**: Enabled only if all consents checked and `app.isComplete`

**Consents**:
```dart
CheckboxListTile(
  value: app.aadhaarConsentSigned,
  onChanged: (val) {
    appProvider.updateConsent('aadhaar_consent', val!);
  },
  title: Text('I consent to use my Aadhaar for verification...'),
),
// ... 6 more consents
```

**Submit Button**:
```dart
ElevatedButton(
  onPressed: app.isComplete ? () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionProgressScreen(application: app),
      ),
    );
  } : null,
  child: Text('Submit Application'),
)
```

---

## 4. Submission Flow

### 4.1 SubmissionProgressScreen
**File**: `lib/presentation/application/submission/submission_progress_screen.dart`

**Features**:
- Progress bar (0-100%)
- Current step text
- Cannot go back during submission

**Key Code**:
```dart
final submissionProvider = Provider.of<SubmissionProvider>(context);

@override
void initState() {
  super.initState();
  _submitApplication();
}

Future<void> _submitApplication() async {
  final success = await submissionProvider.submitApplication(widget.application);

  if (success) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SubmissionSuccessScreen(
          applicationNumber: submissionProvider.submittedApplicationNumber!,
        ),
      ),
    );
  }
}

// UI
LinearProgressIndicator(value: submissionProvider.uploadProgress),
Text(submissionProvider.currentStep),
```

### 4.2 SubmissionSuccessScreen
**File**: `lib/presentation/application/submission/submission_success_screen.dart`

**Features**:
- Green checkmark icon
- Application number (large, prominent)
- Submission timestamp
- "Track Status" button → navigate to ApplicationDetailScreen
- "Back to Home" button

---

## 5. Application Viewing

### 5.1 ApplicationDetailScreen
**File**: `lib/presentation/application/view/application_detail_screen.dart`

**Features**:
- Fetch application from backend by ID
- Show status badge (color-coded)
- Display all details (read-only)
- "Download Forms" button (if forms_available)
- "Upload Signed Forms" button (if forms downloaded)

**Fetch Data**:
```dart
final appRepo = Provider.of<ApplicationRepository>(context, listen: false);
final appData = await appRepo.getApplicationById(widget.applicationId);
```

### 5.2 FormsDownloadScreen
**File**: `lib/presentation/application/view/forms_download_screen.dart`

**Features**:
- List of 4-6 generated PDFs
- Download button for each
- Instructions on signing
- Navigate to FormsUploadScreen when done

**Download**:
```dart
final forms = await appRepo.getApplicationForms(applicationId);

for (var form in forms) {
  final savePath = '/storage/emulated/0/Download/${form['form_name']}.pdf';
  await appRepo.downloadFormPdf(form['pdf_url'], savePath);
}
```

### 5.3 FormsUploadScreen
**File**: `lib/presentation/application/view/forms_upload_screen.dart`

**Features**:
- Pick 4 signed form PDFs/images
- Upload each to TUS
- Get TUS URLs
- Submit URLs to backend

**Submit**:
```dart
final signedForms = [
  {'form_type': 'FORM_1', 'tus_url': tusUrl1, ...},
  {'form_type': 'FORM_3', 'tus_url': tusUrl3, ...},
  // ...
];

await appRepo.submitSignedForms(
  applicationId: applicationId,
  signedForms: signedForms,
);
```

---

## 6. Agent Screens

### 6.1 AgentDashboardScreen
**File**: `lib/presentation/agent/agent_dashboard_screen.dart`

**Features**:
- Tabs: "My Applications", "Pre-Sureksha", "Sync"
- Search bar (by mobile/Aadhaar/ID)
- Filter by status
- FAB: New Application

### 6.2 ApplicationsListScreen
**File**: `lib/presentation/agent/applications_list_screen.dart`

**Features**:
- List of all agent's applications
- Search and filter
- Tap to view details

**Fetch**:
```dart
final applications = await appRepo.getApplications(
  page: 1,
  search: searchQuery,
  status: selectedStatus,
);
```

---

## 7. Pre-Sureksha (Stubbed)

### 7.1 PreSurekshaCaptureScreen
**File**: `lib/presentation/pre_sureksha/pre_sureksha_capture_screen.dart`

**Features**:
- Map view with draggable marker (use google_maps_flutter or flutter_map)
- "Capture Kitchen Photo" button
- "Capture Main Gate Photo" button
- Show thumbnails
- **Save locally, API calls stubbed**

**Capture**:
```dart
// Get location
final location = await LocationService().getCurrentLocation();

// Capture photos
final kitchenPhoto = await ImagePicker().pickImage(...);
final gatePhoto = await ImagePicker().pickImage(...);

// Save locally (no API call)
final preSureksha = LocalPreSureksha(
  latitude: location.latitude,
  longitude: location.longitude,
  kitchenPhotoPath: kitchenPhoto.path,
  gatePhotoPath: gatePhoto.path,
);
// Save to Hive
await HiveService.preSurekshaBox.put(id, preSureksha);

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Pre-Sureksha data saved locally (API stubbed)')),
);
```

---

## 8. Reusable Widgets

### 8.1 CustomTextField
**File**: `lib/presentation/widgets/custom_text_field.dart`

Simple wrapper with consistent styling.

### 8.2 CustomDropdown
**File**: `lib/presentation/widgets/custom_dropdown.dart`

DropdownButtonFormField with consistent styling.

### 8.3 DatePickerField
**File**: `lib/presentation/widgets/date_picker_field.dart`

TextField that opens date picker on tap.

### 8.4 StatusBadge
**File**: `lib/presentation/widgets/status_badge.dart`

Color-coded badge for application status.

### 8.5 LoadingIndicator
**File**: `lib/presentation/widgets/loading_indicator.dart`

Center-aligned CircularProgressIndicator.

---

## 9. Updated main.dart

**File**: `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/local/hive_service.dart';
import 'data/services/api_service.dart';
import 'data/services/tus_upload_service.dart';
import 'data/services/compression_service.dart';
import 'data/services/location_service.dart';
import 'data/services/notification_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/application_repository.dart';
import 'data/repositories/document_repository.dart';
import 'providers/auth_provider.dart';
import 'providers/application_provider.dart';
import 'providers/submission_provider.dart';
import 'presentation/auth/splash_screen.dart';
import 'presentation/dashboard/main_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await HiveService.init();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final apiService = ApiService();
    final tusService = TusUploadService();
    final compressionService = CompressionService();

    // Initialize repositories
    final authRepo = AuthRepository(apiService);
    final appRepo = ApplicationRepository(apiService, tusService);
    final docRepo = DocumentRepository(tusService, compressionService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
        ChangeNotifierProvider(create: (_) => SubmissionProvider(appRepo)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Arun Gas Consumer App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              useMaterial3: true,
            ),
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainContainer()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## Summary

✅ **Complete backend layer** (services + repositories)
✅ **Complete state management** (providers)
✅ **Splash screen** implemented
✅ **Detailed structure** for all remaining screens

**To Complete**:
1. Implement the authentication screens (5 screens)
2. Implement MainContainer with drawer
3. Implement 7-step form wizard
4. Implement submission + post-submission screens (3 screens)
5. Implement agent screens (2 screens)
6. Implement Pre-Sureksha (stubbed)
7. Create reusable widgets (5 widgets)
8. Update main.dart with providers

**Total Remaining**: ~25 screen files + 5 widget files

All follow the same patterns shown in this guide. Use the existing providers and repositories.

**Once complete, you'll have a fully functional Flutter app ready to run!**
