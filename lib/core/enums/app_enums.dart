/// Application Enumerations
///
/// This file contains all enum types used throughout the application.

/// Gender enum
enum Gender {
  male('M', 'Male'),
  female('F', 'Female'),
  other('O', 'Other');

  final String value;
  final String display;

  const Gender(this.value, this.display);

  static Gender fromValue(String value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.other,
    );
  }
}

/// Caste/Category enum
enum Caste {
  sc('SC', 'Scheduled Caste'),
  st('ST', 'Scheduled Tribe'),
  obc('OBC', 'Other Backward Class'),
  general('GENERAL', 'General');

  final String value;
  final String display;

  const Caste(this.value, this.display);

  static Caste fromValue(String value) {
    return Caste.values.firstWhere(
      (c) => c.value == value,
      orElse: () => Caste.general,
    );
  }
}

/// Marital Status enum
enum MaritalStatus {
  single('SINGLE', 'Single'),
  married('MARRIED', 'Married'),
  divorced('DIVORCED', 'Divorced'),
  widowed('WIDOWED', 'Widowed');

  final String value;
  final String display;

  const MaritalStatus(this.value, this.display);

  static MaritalStatus fromValue(String value) {
    return MaritalStatus.values.firstWhere(
      (m) => m.value == value,
      orElse: () => MaritalStatus.single,
    );
  }
}

/// LPG Connection Type enum
enum LPGConnectionType {
  single14_2kg('SINGLE_14_2KG', 'Single 14.2 KG'),
  single5kg('SINGLE_5KG', 'Single 5 KG'),
  double14_2kg('DOUBLE_14_2KG', 'Double 14.2 KG');

  final String value;
  final String display;

  const LPGConnectionType(this.value, this.display);

  static LPGConnectionType fromValue(String value) {
    return LPGConnectionType.values.firstWhere(
      (l) => l.value == value,
      orElse: () => LPGConnectionType.single14_2kg,
    );
  }
}

/// Address Type enum
enum AddressType {
  current('CURRENT', 'Current Address'),
  permanent('PERMANENT', 'Permanent Address');

  final String value;
  final String display;

  const AddressType(this.value, this.display);

  static AddressType fromValue(String value) {
    return AddressType.values.firstWhere(
      (a) => a.value == value,
      orElse: () => AddressType.current,
    );
  }
}

/// Relation to Applicant enum
enum RelationToApplicant {
  self('SELF', 'Self'),
  husband('HUSBAND', 'Husband'),
  wife('WIFE', 'Wife'),
  son('SON', 'Son'),
  daughter('DAUGHTER', 'Daughter'),
  father('FATHER', 'Father'),
  mother('MOTHER', 'Mother'),
  brother('BROTHER', 'Brother'),
  sister('SISTER', 'Sister'),
  other('OTHER', 'Other');

  final String value;
  final String display;

  const RelationToApplicant(this.value, this.display);

  static RelationToApplicant fromValue(String value) {
    return RelationToApplicant.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RelationToApplicant.other,
    );
  }
}

/// Document Type enum
enum DocumentType {
  // Aadhaar
  aadhaarFront('AADHAAR_FRONT', 'Aadhaar Card Front'),
  aadhaarBack('AADHAAR_BACK', 'Aadhaar Card Back'),

  // Required Documents (uploaded during application creation)
  currentAddressPoa('CURRENT_ADDRESS_POA', 'Current Address Proof'),
  permanentAddressPoa('PERMANENT_ADDRESS_POA', 'Permanent Address Proof'),
  familyCompositionDoc('FAMILY_COMPOSITION_DOC', 'Family Composition Document'),
  bankProof('BANK_PROOF', 'Bank Proof'),
  applicantPhoto('APPLICANT_PHOTO', 'Applicant Photo'),

  // Optional Documents
  familyPhoto('FAMILY_PHOTO', 'Family Photo'),
  applicantSignature('APPLICANT_SIGNATURE', 'Applicant Signature'),
  casteCertificate('CASTE_CERTIFICATE', 'Caste Certificate'),

  // Pre-Sureksha Documents (captured during Pre-Sureksha)
  kitchenPhoto('KITCHEN_PHOTO', 'Kitchen Photo'),
  mainGatePhoto('MAIN_GATE_PHOTO', 'Main Gate Photo'),

  // Post-Submission Forms (signed and uploaded)
  signedForm1('SIGNED_FORM_1', 'Signed Annexure-I'),
  signedForm2('SIGNED_FORM_2', 'Signed Supporting Authentication'),
  signedForm3('SIGNED_FORM_3', 'Signed Deprivation Declaration'),
  signedForm4('SIGNED_FORM_4', 'Signed KYC Form');

  final String value;
  final String display;

  const DocumentType(this.value, this.display);

  static DocumentType fromValue(String value) {
    return DocumentType.values.firstWhere(
      (d) => d.value == value,
      orElse: () => DocumentType.applicantPhoto,
    );
  }

  /// Check if document is required during application creation
  bool get isRequired {
    return [
      DocumentType.currentAddressPoa,
      DocumentType.permanentAddressPoa,
      DocumentType.familyCompositionDoc,
      DocumentType.bankProof,
      DocumentType.applicantPhoto,
    ].contains(this);
  }
}

/// Application Status enum
enum ApplicationStatus {
  // Local statuses
  draft('DRAFT', 'Draft'),
  submitting('SUBMITTING', 'Submitting'),

  // Server statuses
  submitted('SUBMITTED', 'Submitted'),
  underVerification('UNDER_VERIFICATION', 'Under Verification'),
  verificationFailed('VERIFICATION_FAILED', 'Verification Failed'),
  rejected('REJECTED', 'Rejected'),
  approved('APPROVED', 'Approved'),
  connectionIssued('CONNECTION_ISSUED', 'Connection Issued'),
  cancelled('CANCELLED', 'Cancelled'),
  onHold('ON_HOLD', 'On Hold');

  final String value;
  final String display;

  const ApplicationStatus(this.value, this.display);

  static ApplicationStatus fromValue(String value) {
    return ApplicationStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ApplicationStatus.draft,
    );
  }

  /// Check if status is terminal (no further changes expected)
  bool get isTerminal {
    return [
      ApplicationStatus.approved,
      ApplicationStatus.rejected,
      ApplicationStatus.connectionIssued,
      ApplicationStatus.cancelled,
    ].contains(this);
  }

  /// Check if status allows editing
  bool get isEditable {
    return [
      ApplicationStatus.draft,
    ].contains(this);
  }
}

/// User Role enum
enum UserRole {
  user('USER', 'End User'),
  agent('AGENT', 'Agent'),
  teamLeader('TEAM_LEADER', 'Team Leader');

  final String value;
  final String display;

  const UserRole(this.value, this.display);

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.user,
    );
  }
}

/// Indian States enum
enum IndianState {
  an('AN', 'Andaman and Nicobar Islands'),
  ap('AP', 'Andhra Pradesh'),
  ar('AR', 'Arunachal Pradesh'),
  as('AS', 'Assam'),
  br('BR', 'Bihar'),
  ch('CH', 'Chandigarh'),
  ct('CT', 'Chhattisgarh'),
  dn('DN', 'Dadra and Nagar Haveli'),
  dd('DD', 'Daman and Diu'),
  dl('DL', 'Delhi'),
  ga('GA', 'Goa'),
  gj('GJ', 'Gujarat'),
  hr('HR', 'Haryana'),
  hp('HP', 'Himachal Pradesh'),
  jk('JK', 'Jammu and Kashmir'),
  jh('JH', 'Jharkhand'),
  ka('KA', 'Karnataka'),
  kl('KL', 'Kerala'),
  ld('LD', 'Lakshadweep'),
  mp('MP', 'Madhya Pradesh'),
  mh('MH', 'Maharashtra'),
  mn('MN', 'Manipur'),
  ml('ML', 'Meghalaya'),
  mz('MZ', 'Mizoram'),
  nl('NL', 'Nagaland'),
  or('OR', 'Odisha'),
  py('PY', 'Puducherry'),
  pb('PB', 'Punjab'),
  rj('RJ', 'Rajasthan'),
  sk('SK', 'Sikkim'),
  tn('TN', 'Tamil Nadu'),
  tg('TG', 'Telangana'),
  tr('TR', 'Tripura'),
  up('UP', 'Uttar Pradesh'),
  ut('UT', 'Uttarakhand'),
  wb('WB', 'West Bengal');

  final String value;
  final String display;

  const IndianState(this.value, this.display);

  static IndianState fromValue(String value) {
    return IndianState.values.firstWhere(
      (s) => s.value == value,
      orElse: () => IndianState.dl,
    );
  }
}

/// Family Document Type enum (for ration card, etc.)
enum FamilyDocType {
  rationCard('RATION_CARD', 'Ration Card'),
  voterList('VOTER_LIST', 'Voter List'),
  other('OTHER', 'Other');

  final String value;
  final String display;

  const FamilyDocType(this.value, this.display);

  static FamilyDocType fromValue(String value) {
    return FamilyDocType.values.firstWhere(
      (f) => f.value == value,
      orElse: () => FamilyDocType.other,
    );
  }
}

/// POA Code (Proof of Address) enum
enum POACode {
  poa01('POA01', 'Aadhaar Card'),
  poa02('POA02', 'Passport'),
  poa03('POA03', 'Voter ID'),
  poa04('POA04', 'Driving License'),
  poa05('POA05', 'Electricity Bill'),
  poa06('POA06', 'Water Bill'),
  poa07('POA07', 'Gas Bill'),
  poa08('POA08', 'Rent Agreement'),
  poa09('POA09', 'Bank Statement'),
  poa10('POA10', 'Property Tax Receipt');

  final String value;
  final String display;

  const POACode(this.value, this.display);

  static POACode fromValue(String value) {
    return POACode.values.firstWhere(
      (p) => p.value == value,
      orElse: () => POACode.poa01,
    );
  }
}
