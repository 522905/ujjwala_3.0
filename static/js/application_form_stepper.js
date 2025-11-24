/**
 * PMUY V3 Application Form - Stepper System
 * Handles 7-step form navigation, validation, and submission
 */

// ==================== GLOBAL STATE ====================
const APP_STATE = {
    currentStep: 1,
    totalSteps: 7,
    completedSteps: [],
    stepData: {},
    userRole: null, // 'agent' or 'customer'
    mobileVerified: false,
    verifiedMobile: '',
    ocrData: null,
    aadhaarFrontUrl: null,
    aadhaarBackUrl: null,
    documentUploadedList: []
};

const STEP_DEFINITIONS = [
    { number: 1, label: 'Aadhaar & Applicant', icon: 'id-card' },
    { number: 2, label: 'Bank Details', icon: 'university' },
    { number: 3, label: 'Current Address', icon: 'map-marker-alt' },
    { number: 4, label: 'Permanent Address', icon: 'home' },
    { number: 5, label: 'Family Members', icon: 'users' },
    { number: 6, label: 'Documents', icon: 'file-upload' },
    { number: 7, label: 'Review & Submit', icon: 'check-circle' }
];

const FORM_STORAGE_KEY = 'ujjwala_v3_form_data';
let autoSaveTimer = null;

// ==================== INITIALIZATION ====================
$(document).ready(function() {
    console.log('🚀 Initializing PMUY V3 Application Form Stepper');

    // Detect user role
    detectUserRole();

    // Initialize stepper UI
    renderStepper();

    // Initialize first step
    goToStep(1);

    // Initialize upload managers
    initializeUppyUploaders();

    // Initialize photo upload manager
    if (window.photoUploadManager) {
        window.photoUploadManager.initBankPassbookUploader();
        window.photoUploadManager.initProfilePhotoUploader();
    }

    // Set up event listeners
    setupEventListeners();

    // Try to load saved data
    const savedData = localStorage.getItem(FORM_STORAGE_KEY);
    if (savedData) {
        console.log('📦 Found saved form data');
        // Don't auto-load, let user decide
    }

    // Set up auto-save
    setupAutoSave();

    console.log('✅ Stepper initialized successfully');
});

// ==================== USER ROLE DETECTION ====================
function detectUserRole() {
    // Check if user role is stored in localStorage or session
    const storedRole = localStorage.getItem('user_role') || sessionStorage.getItem('user_role');

    // Check if Django template has set user role (if backend available)
    const djangoUserRole = $('meta[name="user-role"]').attr('content');

    // Determine role
    if (storedRole) {
        APP_STATE.userRole = storedRole;
    } else if (djangoUserRole) {
        APP_STATE.userRole = djangoUserRole;
    } else {
        // Default to customer (no OTP required)
        APP_STATE.userRole = 'customer';
    }

    console.log('👤 User Role:', APP_STATE.userRole);

    // Configure mobile verification based on role
    if (APP_STATE.userRole === 'customer') {
        $('#mobileVerificationMessage').html('Enter your mobile number (OTP verification not required for customers).');
        $('#sendOtpBtn').hide();
        $('#mobile_for_verification').on('blur', function() {
            const mobile = $(this).val();
            if (mobile && mobile.length === 10) {
                APP_STATE.verifiedMobile = mobile;
                APP_STATE.mobileVerified = true;
                $('#mobileVerificationCard').hide();
                $('#aadhaarUploadCard').slideDown();
                $('#applicant_mobile').val(mobile).prop('readonly', true);
            }
        });
    } else {
        // Agent requires OTP
        $('#sendOtpBtn').show();
    }
}

// ==================== STEPPER UI RENDERING ====================
function renderStepper() {
    const stepperWrapper = $('#stepperWrapper');
    stepperWrapper.empty();

    // Determine which steps to show (sliding window of 3)
    let visibleSteps = [];
    const current = APP_STATE.currentStep;

    if (current <= 2) {
        visibleSteps = [1, 2, 3];
    } else if (current >= APP_STATE.totalSteps - 1) {
        visibleSteps = [APP_STATE.totalSteps - 2, APP_STATE.totalSteps - 1, APP_STATE.totalSteps];
    } else {
        visibleSteps = [current - 1, current, current + 1];
    }

    // Render visible steps
    visibleSteps.forEach(stepNum => {
        const step = STEP_DEFINITIONS[stepNum - 1];
        const isActive = stepNum === APP_STATE.currentStep;
        const isCompleted = APP_STATE.completedSteps.includes(stepNum);
        const isDisabled = stepNum > APP_STATE.currentStep && !isCompleted;

        let classes = ['stepper-item'];
        if (isActive) classes.push('active');
        if (isCompleted) classes.push('completed');
        if (isDisabled) classes.push('disabled');

        const html = `
            <div class="${classes.join(' ')}" onclick="handleStepClick(${stepNum})">
                <div class="stepper-circle">
                    ${isCompleted ? '<i class="fas fa-check"></i>' : stepNum}
                </div>
                <span class="stepper-label">${step.label}</span>
            </div>
        `;

        stepperWrapper.append(html);
    });
}

function handleStepClick(stepNum) {
    // Can only go back to previous steps or current step
    if (stepNum < APP_STATE.currentStep || APP_STATE.completedSteps.includes(stepNum)) {
        goToStep(stepNum);
    } else if (stepNum === APP_STATE.currentStep) {
        // Already on this step, do nothing
    } else {
        alert('Please complete the current step before proceeding.');
    }
}

// ==================== STEP NAVIGATION ====================
function goToStep(stepNumber) {
    if (stepNumber < 1 || stepNumber > APP_STATE.totalSteps) {
        console.error('Invalid step number:', stepNumber);
        return;
    }

    console.log(`📍 Navigating to Step ${stepNumber}`);

    // Hide all steps
    $('.step-content').removeClass('active');

    // Show target step
    $(`#step${stepNumber}`).addClass('active');

    // Update state
    APP_STATE.currentStep = stepNumber;
    $('#current_step').val(stepNumber);

    // Re-render stepper
    renderStepper();

    // Scroll to top
    $('html, body').animate({ scrollTop: $('.form-container').offset().top - 20 }, 400);

    // Save progress
    saveFormData();
}

function nextStep() {
    const currentStep = APP_STATE.currentStep;

    // Validate current step
    if (!validateStep(currentStep)) {
        return;
    }

    // Mark step as completed
    if (!APP_STATE.completedSteps.includes(currentStep)) {
        APP_STATE.completedSteps.push(currentStep);
    }

    // Go to next step
    if (currentStep < APP_STATE.totalSteps) {
        goToStep(currentStep + 1);
    }
}

function previousStep() {
    const currentStep = APP_STATE.currentStep;
    if (currentStep > 1) {
        goToStep(currentStep - 1);
    }
}

// ==================== STEP VALIDATION ====================
function validateStep(stepNumber) {
    console.log(`✓ Validating Step ${stepNumber}`);

    switch(stepNumber) {
        case 1:
            return validateStep1();
        case 2:
            return validateStep2();
        case 3:
            return validateStep3();
        case 4:
            return validateStep4();
        case 5:
            return validateStep5();
        case 6:
            return validateStep6();
        case 7:
            return validateStep7();
        default:
            return true;
    }
}

// Step 1: Aadhaar & Applicant
function validateStep1() {
    // Check if mobile verified (for agents) or entered (for customers)
    if (!APP_STATE.mobileVerified && !APP_STATE.verifiedMobile) {
        if (APP_STATE.userRole === 'agent') {
            alert('Please verify your mobile number with OTP first.');
            return false;
        } else {
            const mobile = $('#mobile_for_verification').val();
            if (!mobile || mobile.length !== 10) {
                alert('Please enter a valid mobile number.');
                return false;
            }
        }
    }

    // Check if Aadhaar uploaded and OCR processed, or manual entry done
    if ($('#ocr_processed').val() !== 'yes' && !$('#applicant_first_name').val()) {
        alert('Please upload Aadhaar and process OCR, or enter applicant details manually.');
        return false;
    }

    // Validate applicant details
    if (!$('#applicant_first_name').val()) {
        alert('Please enter first name.');
        return false;
    }

    // Gender validation - MUST be FEMALE
    const gender = $('#applicant_gender').val();
    if (!gender) {
        alert('Please select gender.');
        return false;
    }
    if (gender !== 'F') {
        $('#genderErrorAlert').show();
        alert('This scheme is exclusively for female applicants. केवल महिलाएं ही इस योजना के लिए आवेदन कर सकती हैं।');
        return false;
    }
    $('#genderErrorAlert').hide();

    // Age validation - MUST be >= 18
    const dob = $('#applicant_dob_input').val();
    if (!dob) {
        alert('Please enter date of birth.');
        return false;
    }

    const age = calculateAge(dob);
    if (age < 18) {
        $('#ageErrorAlert').show();
        alert('Applicant must be at least 18 years old to apply. आवेदक की आयु कम से कम 18 वर्ष होनी चाहिए।');
        return false;
    }
    $('#ageErrorAlert').hide();

    // Aadhaar number
    const aadhaar = $('#applicant_aadhaar_number').val();
    if (!aadhaar || aadhaar.length !== 12) {
        alert('Please enter a valid 12-digit Aadhaar number.');
        return false;
    }

    // Mobile number
    const mobile = $('#applicant_mobile').val();
    if (!mobile || mobile.length !== 10) {
        alert('Please enter a valid mobile number.');
        return false;
    }

    // Caste
    if (!$('#caste').val()) {
        alert('Please select caste/category.');
        return false;
    }

    // Copy DOB to hidden field
    $('#applicant_dob').val(dob);

    return true;
}

// Step 2: Bank Details
function validateStep2() {
    // IFSC
    const ifsc = $('#bank_ifsc').val();
    if (!ifsc || ifsc.length !== 11) {
        alert('Please enter a valid IFSC code.');
        return false;
    }

    // Account holder name
    if (!$('#bank_account_name').val()) {
        alert('Please enter account holder name.');
        return false;
    }

    // Bank name (auto-filled)
    if (!$('#bank_name').val()) {
        alert('Please wait for bank details to be fetched from IFSC code.');
        return false;
    }

    // Account number
    const accountNumber = $('#bank_account_number').val();
    if (!accountNumber || accountNumber.length < 9) {
        alert('Please enter a valid account number.');
        return false;
    }

    // Bank passbook photo
    if (!$('#bankPassbookUrl').val()) {
        alert('Please upload bank passbook photo.');
        return false;
    }

    return true;
}

// Step 3: Current Address
function validateStep3() {
    if (!$('#current_house_flat_no').val()) {
        alert('Please enter house/flat number.');
        return false;
    }
    if (!$('#current_district').val()) {
        alert('Please enter district.');
        return false;
    }
    if (!$('#current_city_town').val()) {
        alert('Please enter city/town.');
        return false;
    }
    const pincode = $('#current_pincode').val();
    if (!pincode || pincode.length !== 6) {
        alert('Please enter a valid 6-digit pincode.');
        return false;
    }
    if (!$('select[name="current_poa_code"]').val()) {
        alert('Please select proof of address type.');
        return false;
    }
    return true;
}

// Step 4: Permanent Address
function validateStep4() {
    if (!$('#permanent_house_flat_no').val()) {
        alert('Please enter house/flat number for permanent address.');
        return false;
    }
    if (!$('#permanent_village_panchayat_area').val()) {
        alert('Please enter village/area.');
        return false;
    }
    if (!$('#permanent_district').val()) {
        alert('Please enter district.');
        return false;
    }
    if (!$('#permanent_city_town').val()) {
        alert('Please enter city/town.');
        return false;
    }

    const permanentState = $('#permanent_state').val();
    if (!permanentState) {
        alert('Please enter state for permanent address.');
        return false;
    }

    // Validate state mismatch (migrant requirement)
    const currentState = $('#current_state').val();
    if (permanentState.toLowerCase() === currentState.toLowerCase()) {
        $('#stateMatchErrorAlert').show();
        alert('For migrant category, permanent address state must be different from current address state (Punjab).');
        return false;
    }
    $('#stateMatchErrorAlert').hide();

    const pincode = $('#permanent_pincode').val();
    if (!pincode || pincode.length !== 6) {
        alert('Please enter a valid 6-digit pincode.');
        return false;
    }

    if (!$('select[name="permanent_poa_code"]').val()) {
        alert('Please select proof of address type.');
        return false;
    }

    return true;
}

// Step 5: Family Members
function validateStep5() {
    // Check if at least one family member added
    if ($('.family-member-item').length === 0) {
        alert('Please add at least one family member (including yourself as SELF).');
        return false;
    }

    // Check if SELF member exists
    let hasSelf = false;
    $('select[name^="family_member_"][name$="_relation"]').each(function() {
        if ($(this).val() === 'SELF') {
            hasSelf = true;
            return false; // break
        }
    });

    if (!hasSelf) {
        alert('Please add yourself as a SELF family member. आपको अपने आप को SELF के रूप में जोड़ना होगा।');
        return false;
    }

    // Validate each family member has required fields
    let isValid = true;
    $('.family-member-item').each(function() {
        const memberId = $(this).attr('id').replace('familyMember_', '');

        const name = $(`[name="family_member_${memberId}_name"]`).val();
        const relation = $(`[name="family_member_${memberId}_relation"]`).val();
        const gender = $(`[name="family_member_${memberId}_gender"]`).val();
        const dob = $(`[name="family_member_${memberId}_dob"]`).val();
        const aadhaar = $(`[name="family_member_${memberId}_aadhaar"]`).val();

        if (!name || !relation || !gender || !dob || !aadhaar) {
            alert(`Please fill all required fields for family member: ${name || 'Unnamed member'}`);
            isValid = false;
            return false; // break
        }

        // Check UID photos (skip for SELF as they use Step 1 Aadhaar)
        if (relation !== 'SELF') {
            const frontUrl = $(`#uidFrontUrl_${memberId}`).val();
            const backUrl = $(`#uidBackUrl_${memberId}`).val();
            if (!frontUrl || !backUrl) {
                alert(`Please upload Aadhaar photos for family member: ${name}`);
                isValid = false;
                return false; // break
            }
        }
    });

    return isValid;
}

// Step 6: Documents
function validateStep6() {
    // Applicant photo (mandatory)
    if (!$('#profilePhotoUrl').val()) {
        alert('Please upload applicant photo. यह अनिवार्य है।');
        return false;
    }

    // Caste certificate (if not General)
    const caste = $('#caste').val();
    if (caste && caste !== 'GENERAL' && caste !== 'OTHERS') {
        const casteCert = $('#casteCertificateUrl').val();
        if (!casteCert) {
            alert('Caste certificate is required for SC/ST/OBC categories.');
            return false;
        }
    }

    // Migration certificate (if states different)
    const currentState = $('#current_state').val();
    const permanentState = $('#permanent_state').val();
    if (currentState && permanentState && currentState.toLowerCase() !== permanentState.toLowerCase()) {
        const migrationCert = $('#migrationCertificateUrl').val();
        if (!migrationCert) {
            alert('Migration certificate is required for migrant applicants (different states).');
            return false;
        }
    }

    return true;
}

// Step 7: Review & Submit
function validateStep7() {
    // Check final confirmation checkbox
    if (!$('#final-confirm-checkbox').is(':checked')) {
        alert('Please confirm that all information provided is true and correct.\n\nकृपया पुष्टि करें कि सभी जानकारी सत्य और सही है।');
        return false;
    }
    return true;
}

// ==================== HELPER FUNCTIONS ====================
function calculateAge(dateString) {
    const today = new Date();
    const birthDate = new Date(dateString);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    return age;
}

function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

// ==================== EVENT LISTENERS ====================
function setupEventListeners() {
    // Mobile OTP
    $('#sendOtpBtn').click(sendOTP);
    $('#verifyOtpBtn').click(verifyOTP);
    $('#resendOtpBtn').click(sendOTP);

    // Gender change - validate immediately
    $('#applicant_gender').change(function() {
        const gender = $(this).val();
        if (gender && gender !== 'F') {
            $('#genderErrorAlert').show();
        } else {
            $('#genderErrorAlert').hide();
        }
    });

    // DOB change - validate age
    $('#applicant_dob_input').change(function() {
        const dob = $(this).val();
        if (dob) {
            const age = calculateAge(dob);
            if (age < 18) {
                $('#ageErrorAlert').show();
            } else {
                $('#ageErrorAlert').hide();
            }
        }
    });

    // IFSC validation
    $('#bank_ifsc').on('input', function() {
        this.value = this.value.toUpperCase();
        if (this.value.length < 11) {
            $('#bank_account_number').prop('disabled', true).val('');
            $('#bank_name').val('');
            $('#bank_branch').val('');
            $('#bank_address').val('');
            $('#ifsc_info').html('');
        }
    });

    $('#bank_ifsc').on('blur', function() {
        const ifsc = $(this).val();
        if (ifsc.length === 11) {
            $('#ifsc_info').html('<span class="text-info"><i class="fas fa-spinner fa-spin"></i> Validating IFSC...</span>');

            $.ajax({
                url: 'https://ifsc.razorpay.com/' + ifsc,
                method: 'GET',
                dataType: 'json',
                success: function(data) {
                    $('#bank_name').val(data.BANK || '');
                    $('#bank_branch').val(data.BRANCH || '');
                    $('#bank_address').val(data.ADDRESS || '');
                    $('#ifsc_info').html(`<span class="text-success"><i class="fas fa-check-circle"></i> Valid IFSC - ${data.BANK}, ${data.BRANCH}</span>`);
                    $('#bank_account_number').prop('disabled', false).attr('placeholder', 'Enter account number');
                },
                error: function() {
                    $('#ifsc_info').html('<span class="text-danger"><i class="fas fa-times-circle"></i> Invalid IFSC Code</span>');
                    $('#bank_name').val('');
                    $('#bank_branch').val('');
                    $('#bank_address').val('');
                    $('#bank_account_number').prop('disabled', true).val('');
                }
            });
        }
    });

    // Permanent state validation
    $('#permanent_state').on('blur', function() {
        const permanentState = $(this).val();
        const currentState = $('#current_state').val();
        if (permanentState && permanentState.toLowerCase() === currentState.toLowerCase()) {
            $('#stateMatchErrorAlert').show();
        } else {
            $('#stateMatchErrorAlert').hide();
        }
    });

    // Caste change - show/hide caste certificate section
    $('#caste').change(function() {
        const caste = $(this).val();
        if (caste && caste !== 'GENERAL' && caste !== 'OTHERS') {
            $('#casteCertificateSection').slideDown();
            if (!window.casteCertificateUppy) {
                initCasteCertificateUploader();
            }
        } else {
            $('#casteCertificateSection').slideUp();
        }
    });

    // Family member button
    $('#addFamilyMember').click(function() {
        addFamilyMemberWithUID();
    });

    // Form field changes trigger auto-save
    $('#applicationForm').on('input change', 'input, select, textarea', function() {
        scheduleAutoSave();
    });
}

// ==================== MOBILE OTP ====================
function sendOTP() {
    const mobile = $('#mobile_for_verification').val();
    if (!mobile || mobile.length !== 10) {
        alert('Please enter a valid 10-digit mobile number.');
        return;
    }

    $('#sendOtpBtn').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Sending...');

    $.ajax({
        url: '/communication_log/send-otp-generic/',
        type: 'POST',
        data: {
            mobile: mobile,
            purpose: 'ujjwala_v3_verification'
        },
        headers: { 'X-CSRFToken': getCookie('csrftoken') },
        success: function(response) {
            $('#sendOtpBtn').prop('disabled', false).html('<i class="fas fa-paper-plane"></i> Send OTP');
            if (response.status === 'success') {
                $('#otpInputSection').slideDown();
                alert('OTP sent successfully to ' + mobile);
            } else {
                alert(response.message || 'Failed to send OTP');
            }
        },
        error: function() {
            $('#sendOtpBtn').prop('disabled', false).html('<i class="fas fa-paper-plane"></i> Send OTP');
            alert('Error sending OTP. Please try again.');
        }
    });
}

function verifyOTP() {
    const mobile = $('#mobile_for_verification').val();
    const otp = $('#otp_input').val();

    if (!otp || otp.length !== 6) {
        alert('Please enter a valid 6-digit OTP.');
        return;
    }

    $('#verifyOtpBtn').prop('disabled', true).html('<i class="fas fa-spinner fa-spin"></i> Verifying...');

    $.ajax({
        url: '/communication_log/verify-otp-generic/',
        type: 'POST',
        data: {
            mobile: mobile,
            otp: otp,
            purpose: 'ujjwala_v3_verification'
        },
        headers: { 'X-CSRFToken': getCookie('csrftoken') },
        success: function(response) {
            $('#verifyOtpBtn').prop('disabled', false).html('<i class="fas fa-check-circle"></i> Verify OTP');
            if (response.status === 'success') {
                APP_STATE.mobileVerified = true;
                APP_STATE.verifiedMobile = mobile;

                $('#applicant_mobile').val(mobile).prop('readonly', true);
                $('#mobileVerificationCard').slideUp();
                $('#aadhaarUploadCard').slideDown();

                localStorage.setItem('ujjwala_v3_verified_mobile', mobile);
                alert('Mobile verified successfully! ✓');
            } else {
                alert(response.message || 'Invalid OTP');
            }
        },
        error: function() {
            $('#verifyOtpBtn').prop('disabled', false).html('<i class="fas fa-check-circle"></i> Verify OTP');
            alert('Error verifying OTP. Please try again.');
        }
    });
}

// ==================== UPPY UPLOADERS ====================
let aadhaarFrontUppy, aadhaarBackUppy, currentDocUppy;

function initializeUppyUploaders() {
    // Aadhaar Front
    aadhaarFrontUppy = new Uppy.Core({
        restrictions: {
            maxFileSize: 5000000,
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*']
        },
        autoProceed: true
    })
    .use(Uppy.Dashboard, {
        inline: true,
        target: '#aadhaar_front_uppy',
        height: 200,
        note: 'Upload Aadhaar Front (Max 5MB)'
    })
    .use(Uppy.Webcam, { target: Uppy.Dashboard })
    .use(Uppy.ImageEditor, { quality: 0.92 })
    .use(Uppy.Compressor, {
        quality: 0.92,
        maxWidth: 1520
    })
    .use(Uppy.Tus, {
        endpoint: 'https://tus.dca.arungas.com/files/'
    });

    // Aadhaar Back
    aadhaarBackUppy = new Uppy.Core({
        restrictions: {
            maxFileSize: 5000000,
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*']
        },
        autoProceed: true
    })
    .use(Uppy.Dashboard, {
        inline: true,
        target: '#aadhaar_back_uppy',
        height: 200,
        note: 'Upload Aadhaar Back (Max 5MB)'
    })
    .use(Uppy.Webcam, { target: Uppy.Dashboard })
    .use(Uppy.ImageEditor, { quality: 0.92 })
    .use(Uppy.Compressor, {
        quality: 0.92,
        maxWidth: 1520
    })
    .use(Uppy.Tus, {
        endpoint: 'https://tus.dca.arungas.com/files/'
    });

    // Process OCR button
    $('#processOcrBtn').click(processAadhaarOCR);
}

// ==================== AADHAAR OCR ====================
function processAadhaarOCR() {
    const frontFile = aadhaarFrontUppy.getFiles()[0];
    const backFile = aadhaarBackUppy.getFiles()[0];

    if (!frontFile || !backFile) {
        alert('Please upload both Aadhaar front and back images.');
        return;
    }

    if (!frontFile.uploadURL || !backFile.uploadURL) {
        alert('Please wait for uploads to complete.');
        return;
    }

    APP_STATE.aadhaarFrontUrl = frontFile.uploadURL;
    APP_STATE.aadhaarBackUrl = backFile.uploadURL;

    $('#loader').show();
    $('#ocr_loader').text('Processing Aadhaar OCR, please wait 30 seconds...');

    $.ajax({
        url: '/app_utilities/application-utilities/get_details_for_aadhar/',
        type: 'POST',
        data: {
            uid_front_url: APP_STATE.aadhaarFrontUrl,
            uid_back_url: APP_STATE.aadhaarBackUrl
        },
        headers: { 'X-CSRFToken': getCookie('csrftoken') },
        success: function(response) {
            console.log('✅ OCR Response:', response);

            try {
                if (response.status === 'success') {
                    const data = JSON.parse(response.data.text);
                    APP_STATE.ocrData = data;

                    // Pre-fill applicant details
                    prefillFromOCR(data);

                    // Set hidden fields
                    $('#uid_front_url').val(APP_STATE.aadhaarFrontUrl);
                    $('#uid_back_url').val(APP_STATE.aadhaarBackUrl);
                    $('#ocr_processed').val('yes');

                    // Show preview
                    $('#aadhaarFrontPreview').attr('src', APP_STATE.aadhaarFrontUrl);
                    $('#aadhaarBackPreview').attr('src', APP_STATE.aadhaarBackUrl);
                    $('#aadhaarPreview').show();

                    // Hide uploaders
                    $('#aadhaar_front_uppy').hide();
                    $('#aadhaar_back_uppy').hide();
                    $('#processOcrBtn').hide();

                    // Show applicant details form
                    $('#applicantDetailsCard').slideDown();
                    $('#ocrSuccessAlert').show();

                    $('#loader').hide();
                    saveFormData();
                } else {
                    throw new Error(response.message || 'OCR processing failed');
                }
            } catch (error) {
                $('#loader').hide();
                showErrorModal(
                    'Error processing OCR: ' + error.message,
                    JSON.stringify(response, null, 2)
                );
            }
        },
        error: function(xhr, status, error) {
            $('#loader').hide();
            let errorMessage = 'OCR processing failed. ';
            let errorDetails = '';

            if (xhr.responseJSON) {
                errorMessage += xhr.responseJSON.message || error;
                errorDetails = xhr.responseJSON.error || JSON.stringify(xhr.responseJSON, null, 2);
            } else {
                errorMessage += error;
                errorDetails = xhr.responseText || 'Unknown error';
            }

            showErrorModal(errorMessage, errorDetails);
        },
        timeout: 45000
    });
}

function prefillFromOCR(data) {
    // Name parsing
    if (data.name && data.name.value) {
        const nameParts = data.name.value.trim().split(' ');
        $('#applicant_first_name').val(nameParts[0] || '');
        $('#applicant_middle_name').val(nameParts[1] || '');
        $('#applicant_last_name').val(nameParts.slice(2).join(' ') || '');
    }

    // DOB
    if (data.dob && data.dob.value) {
        let dobValue = data.dob.value;
        const dobParts = dobValue.split('/');
        if (dobParts.length === 3) {
            dobValue = `${dobParts[2]}-${dobParts[1].padStart(2, '0')}-${dobParts[0].padStart(2, '0')}`;
        }
        $('#applicant_dob_input').val(dobValue);
        $('#applicant_dob_input').trigger('change');
    }

    // Gender
    if (data.gender && data.gender.value) {
        const genderMap = { 'MALE': 'M', 'FEMALE': 'F', 'male': 'M', 'female': 'F' };
        const gender = genderMap[data.gender.value] || 'F';
        $('#applicant_gender').val(gender);
        $('#applicant_gender').trigger('change');
    }

    // Aadhaar
    if (data.aadhaar && data.aadhaar.value) {
        $('#applicant_aadhaar_number').val(data.aadhaar.value.replace(/\s/g, ''));
    }

    // Address (Permanent)
    if (data.address && data.address.value) {
        const addr = data.address.value;
        $('#permanent_house_flat_no').val(addr.substring(0, 50));
        $('#permanent_street_road').val(addr);

        // Try to extract location info
        const addrParts = addr.split(',').map(p => p.trim());
        if (addrParts.length >= 3) {
            const city = addrParts[addrParts.length - 3] || '';
            const district = addrParts[addrParts.length - 2] || '';
            const state = addrParts[addrParts.length - 1] || '';

            if (city && city.length < 100 && !/^\d+$/.test(city)) {
                $('#permanent_city_town').val(city);
            }
            if (district && district.length < 100 && !/^\d+$/.test(district)) {
                $('#permanent_district').val(district);
            }
            if (state && state.length < 100 && !/^\d+$/.test(state)) {
                $('#permanent_state').val(state);
            }
        }
    }

    // Pincode
    if (data.pincode) {
        const pincodeValue = typeof data.pincode === 'object' && data.pincode.value
            ? data.pincode.value
            : data.pincode;

        if (pincodeValue && pincodeValue.toString().length === 6) {
            $('#permanent_pincode').val(pincodeValue);
        }
    }
}

// Manual entry option
function enterManually() {
    $('#errorModal').modal('hide');
    $('#aadhaarUploadCard').hide();
    $('#applicantDetailsCard').slideDown();
    $('#ocrSuccessAlert').hide();
}

function retryCurrentStep() {
    $('#errorModal').modal('hide');
    if (APP_STATE.currentStep === 1) {
        $('#processOcrBtn').click();
    }
}

// ==================== DOCUMENT UPLOADERS ====================
function initCasteCertificateUploader() {
    window.casteCertificateUppy = new Uppy.Core({
        autoProceed: true,
        maxFileSize: 10000000,
        maxNumberOfFiles: 1,
        allowedFileTypes: ['image/*', '.pdf']
    })
    .use(Uppy.Dashboard, {
        inline: true,
        target: '#casteCertificateUploader',
        height: 200,
        note: 'Upload caste certificate (Max 10MB)'
    })
    .use(Uppy.Tus, {
        endpoint: 'https://tus.dca.arungas.com/files/'
    });

    window.casteCertificateUppy.on('upload-success', (file, response) => {
        $('#casteCertificateUrl').val(response.uploadURL);
        $('#casteCertificatePreview').html(`
            <div class="alert alert-success mt-2">
                <i class="fas fa-check-circle"></i> Caste certificate uploaded successfully!
            </div>
        `);
    });
}

function initMigrationCertificateUploader() {
    window.migrationCertificateUppy = new Uppy.Core({
        autoProceed: true,
        maxFileSize: 10000000,
        maxNumberOfFiles: 1,
        allowedFileTypes: ['image/*', '.pdf']
    })
    .use(Uppy.Dashboard, {
        inline: true,
        target: '#migrationCertificateUploader',
        height: 200,
        note: 'Upload migration certificate (Max 10MB)'
    })
    .use(Uppy.Tus, {
        endpoint: 'https://tus.dca.arungas.com/files/'
    });

    window.migrationCertificateUppy.on('upload-success', (file, response) => {
        $('#migrationCertificateUrl').val(response.uploadURL);
        $('#migrationCertificatePreview').html(`
            <div class="alert alert-success mt-2">
                <i class="fas fa-check-circle"></i> Migration certificate uploaded successfully!
            </div>
        `);
    });
}

// Check if migration certificate needed
function checkMigrationCertificate() {
    const currentState = $('#current_state').val();
    const permanentState = $('#permanent_state').val();

    if (currentState && permanentState && currentState.toLowerCase() !== permanentState.toLowerCase()) {
        $('#migrationCertificateSection').slideDown();
        if (!window.migrationCertificateUppy) {
            initMigrationCertificateUploader();
        }
    } else {
        $('#migrationCertificateSection').slideUp();
    }
}

// ==================== REVIEW SECTION ====================
function toggleReviewSection(sectionName) {
    const content = $(`#review-${sectionName}`);
    content.toggleClass('collapsed');
}

function populateReviewSection() {
    // Applicant details
    const firstName = $('#applicant_first_name').val();
    const middleName = $('#applicant_middle_name').val();
    const lastName = $('#applicant_last_name').val();
    const fullName = [firstName, middleName, lastName].filter(n => n).join(' ');

    $('#preview-name').text(fullName);
    $('#preview-dob').text($('#applicant_dob_input').val() || 'Not specified');
    $('#preview-gender').text($('#applicant_gender option:selected').text());
    $('#preview-aadhaar').text($('#applicant_aadhaar_number').val());
    $('#preview-mobile').text($('#applicant_mobile').val());
    $('#preview-email').text($('#applicant_email').val() || 'N/A');
    $('#preview-caste').text($('#caste option:selected').text());

    // Bank details
    $('#preview-bank-name').text($('#bank_account_name').val());
    $('#preview-bank').text($('#bank_name').val() + ' - ' + $('#bank_branch').val());
    $('#preview-acc-num').text($('#bank_account_number').val());
    $('#preview-ifsc').text($('#bank_ifsc').val());

    // Addresses
    const currentAddr = `${$('[name="current_house_flat_no"]').val()}, ` +
                       `${$('[name="current_street_road"]').val() || ''}, ` +
                       `${$('[name="current_landmark"]').val() || ''}, ` +
                       `${$('[name="current_city_town"]').val()}, ` +
                       `${$('[name="current_district"]').val()}, ` +
                       `${$('[name="current_state"]').val()} - ${$('[name="current_pincode"]').val()}`;
    $('#preview-current-address').text(currentAddr);

    const permAddr = `${$('[name="permanent_house_flat_no"]').val()}, ` +
                    `${$('[name="permanent_street_road"]').val() || ''}, ` +
                    `${$('[name="permanent_village_panchayat_area"]').val() || ''}, ` +
                    `${$('[name="permanent_city_town"]').val()}, ` +
                    `${$('[name="permanent_district"]').val()}, ` +
                    `${$('[name="permanent_state"]').val()} - ${$('[name="permanent_pincode"]').val()}`;
    $('#preview-permanent-address').text(permAddr);

    // Family members
    let familyHTML = '';
    $('.family-member-item').each(function(index) {
        const memberId = $(this).attr('id').replace('familyMember_', '');
        const name = $(`[name="family_member_${memberId}_name"]`).val();
        const relation = $(`[name="family_member_${memberId}_relation"] option:selected`).text();
        const gender = $(`[name="family_member_${memberId}_gender"] option:selected`).text();
        const dob = $(`[name="family_member_${memberId}_dob"]`).val();
        const aadhaar = $(`[name="family_member_${memberId}_aadhaar"]`).val();

        familyHTML += `
            <div class="border-bottom pb-2 mb-2">
                <h6><strong>Member ${index + 1}</strong></h6>
                <div class="row">
                    <div class="col-md-6"><strong>Name:</strong> ${name}</div>
                    <div class="col-md-6"><strong>Relation:</strong> ${relation}</div>
                </div>
                <div class="row mt-1">
                    <div class="col-md-6"><strong>Gender:</strong> ${gender}</div>
                    <div class="col-md-6"><strong>DOB:</strong> ${dob}</div>
                </div>
                <div class="row mt-1">
                    <div class="col-md-6"><strong>Aadhaar:</strong> ${aadhaar}</div>
                </div>
            </div>
        `;
    });
    $('#review-family').html(familyHTML || '<p class="text-muted">No family members added</p>');

    // Documents
    let docsHTML = '<ul>';
    if ($('#profilePhotoUrl').val()) {
        docsHTML += '<li><i class="fas fa-check text-success"></i> Applicant Photo</li>';
    }
    if ($('#bankPassbookUrl').val()) {
        docsHTML += '<li><i class="fas fa-check text-success"></i> Bank Passbook</li>';
    }
    if ($('#casteCertificateUrl').val()) {
        docsHTML += '<li><i class="fas fa-check text-success"></i> Caste Certificate</li>';
    }
    if ($('#migrationCertificateUrl').val()) {
        docsHTML += '<li><i class="fas fa-check text-success"></i> Migration Certificate</li>';
    }
    if ($('#uid_front_url').val() && $('#uid_back_url').val()) {
        docsHTML += '<li><i class="fas fa-check text-success"></i> Aadhaar Card (Front & Back)</li>';
    }
    docsHTML += '</ul>';
    $('#review-documents').html(docsHTML);
}

// ==================== FINAL SUBMISSION ====================
function submitApplication() {
    // Final validation
    if (!validateStep7()) {
        return;
    }

    // Populate review one last time
    populateReviewSection();

    // Show loader
    $('#loader').show();
    $('#ocr_loader').text('Submitting your application, please wait...');

    // Serialize form data
    const formData = $('#applicationForm').serialize();

    // Submit via AJAX
    $.ajax({
        url: window.location.pathname,
        type: 'POST',
        data: formData,
        headers: {
            'X-Requested-With': 'XMLHttpRequest'
        },
        success: function(response) {
            $('#loader').hide();

            // Clear localStorage on successful submission
            localStorage.removeItem(FORM_STORAGE_KEY);

            // Redirect to success page
            if (response.redirect_url) {
                window.location.href = response.redirect_url;
            } else if (response.status === 'success' && response.application_number) {
                window.location.href = '/ujjwala_v3/success/' + response.application_number + '/';
            } else {
                window.location.reload();
            }
        },
        error: function(xhr, status, error) {
            $('#loader').hide();

            let errorMessage = 'An error occurred while submitting your application.\n\n';
            let errorDetails = '';

            try {
                const errorData = JSON.parse(xhr.responseText);
                errorMessage += '❌ Error Details:\n';
                errorMessage += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';

                if (errorData.message) {
                    errorMessage += '📋 Message: ' + errorData.message + '\n\n';
                }
                if (errorData.error) {
                    errorMessage += '⚠️ Error: ' + errorData.error + '\n\n';
                }

                errorMessage += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
                errorMessage += '✅ Your data has been saved locally and will be restored.\n';

                errorDetails = JSON.stringify(errorData, null, 2);
            } catch (e) {
                errorMessage += '❌ Status Code: ' + xhr.status + '\n';
                errorMessage += '❌ Error: ' + error + '\n\n';
                errorMessage += '✅ Your data has been saved locally.\n';

                errorDetails = xhr.responseText;
            }

            alert(errorMessage);
            console.error('Submission error:', errorDetails);
        }
    });
}

// ==================== AUTO-SAVE & PERSISTENCE ====================
function setupAutoSave() {
    // Auto-save every 30 seconds
    setInterval(function() {
        if (APP_STATE.currentStep > 1) {
            saveFormData();
        }
    }, 30000);

    // Save on page unload
    $(window).on('beforeunload', function() {
        saveFormData();
    });
}

function scheduleAutoSave() {
    if (autoSaveTimer) {
        clearTimeout(autoSaveTimer);
    }
    autoSaveTimer = setTimeout(saveFormData, 3000);
}

function saveFormData() {
    try {
        const formData = {
            timestamp: new Date().toISOString(),
            currentStep: APP_STATE.currentStep,
            completedSteps: APP_STATE.completedSteps,
            mobileVerified: APP_STATE.mobileVerified,
            verifiedMobile: APP_STATE.verifiedMobile,
            applicant: {
                firstName: $('#applicant_first_name').val(),
                middleName: $('#applicant_middle_name').val(),
                lastName: $('#applicant_last_name').val(),
                gender: $('#applicant_gender').val(),
                dob: $('#applicant_dob_input').val(),
                aadhaar: $('#applicant_aadhaar_number').val(),
                mobile: $('#applicant_mobile').val(),
                email: $('#applicant_email').val(),
                caste: $('#caste').val()
            },
            uidPhotos: {
                front: $('#uid_front_url').val(),
                back: $('#uid_back_url').val(),
                ocrProcessed: $('#ocr_processed').val()
            },
            bankDetails: {
                ifsc: $('#bank_ifsc').val(),
                accountName: $('#bank_account_name').val(),
                bankName: $('#bank_name').val(),
                branch: $('#bank_branch').val(),
                accountNumber: $('#bank_account_number').val(),
                passbookUrl: $('#bankPassbookUrl').val()
            },
            currentAddress: {
                houseFlatNo: $('[name="current_house_flat_no"]').val(),
                floorNumber: $('[name="current_floor_number"]').val(),
                streetRoad: $('[name="current_street_road"]').val(),
                landmark: $('[name="current_landmark"]').val(),
                state: $('[name="current_state"]').val(),
                district: $('[name="current_district"]').val(),
                cityTown: $('[name="current_city_town"]').val(),
                pincode: $('[name="current_pincode"]').val(),
                poaCode: $('[name="current_poa_code"]').val()
            },
            permanentAddress: {
                houseFlatNo: $('[name="permanent_house_flat_no"]').val(),
                streetRoad: $('[name="permanent_street_road"]').val(),
                villagePanchayatArea: $('[name="permanent_village_panchayat_area"]').val(),
                district: $('[name="permanent_district"]').val(),
                cityTown: $('[name="permanent_city_town"]').val(),
                state: $('[name="permanent_state"]').val(),
                pincode: $('[name="permanent_pincode"]').val(),
                poaCode: $('[name="permanent_poa_code"]').val()
            },
            familyMembers: collectFamilyMembersForStorage(),
            documents: {
                profilePhoto: $('#profilePhotoUrl').val(),
                casteCertificate: $('#casteCertificateUrl').val(),
                migrationCertificate: $('#migrationCertificateUrl').val()
            }
        };

        localStorage.setItem(FORM_STORAGE_KEY, JSON.stringify(formData));
        console.log('💾 Form data saved');

        return true;
    } catch (error) {
        console.error('Error saving form data:', error);
        return false;
    }
}

function collectFamilyMembersForStorage() {
    const members = [];
    $('.family-member-item').each(function() {
        const memberId = $(this).attr('id').replace('familyMember_', '');
        members.push({
            id: memberId,
            name: $(`[name="family_member_${memberId}_name"]`).val(),
            relation: $(`[name="family_member_${memberId}_relation"]`).val(),
            gender: $(`[name="family_member_${memberId}_gender"]`).val(),
            dob: $(`[name="family_member_${memberId}_dob"]`).val(),
            aadhaar: $(`[name="family_member_${memberId}_aadhaar"]`).val(),
            uidFrontUrl: $(`#uidFrontUrl_${memberId}`).val(),
            uidBackUrl: $(`#uidBackUrl_${memberId}`).val()
        });
    });
    return members;
}

function loadFormData() {
    try {
        const savedData = localStorage.getItem(FORM_STORAGE_KEY);
        if (!savedData) {
            alert('No saved form data found.');
            return false;
        }

        const formData = JSON.parse(savedData);

        if (!confirm(`Found saved form data from ${new Date(formData.timestamp).toLocaleString()}.\n\nDo you want to restore this data?`)) {
            return false;
        }

        // Restore state
        APP_STATE.currentStep = formData.currentStep || 1;
        APP_STATE.completedSteps = formData.completedSteps || [];
        APP_STATE.mobileVerified = formData.mobileVerified || false;
        APP_STATE.verifiedMobile = formData.verifiedMobile || '';

        // Restore applicant data
        if (formData.applicant) {
            $('#applicant_first_name').val(formData.applicant.firstName || '');
            $('#applicant_middle_name').val(formData.applicant.middleName || '');
            $('#applicant_last_name').val(formData.applicant.lastName || '');
            $('#applicant_gender').val(formData.applicant.gender || '');
            $('#applicant_dob_input').val(formData.applicant.dob || '');
            $('#applicant_aadhaar_number').val(formData.applicant.aadhaar || '');
            $('#applicant_mobile').val(formData.applicant.mobile || '');
            $('#applicant_email').val(formData.applicant.email || '');
            $('#caste').val(formData.applicant.caste || '');
        }

        // Restore other sections...
        // (Similar restoration code for other sections)

        // Go to saved step
        goToStep(APP_STATE.currentStep);

        alert('Form data restored successfully!');
        return true;
    } catch (error) {
        console.error('Error loading form data:', error);
        alert('Error restoring saved data: ' + error.message);
        return false;
    }
}

function discardAndStartOver() {
    if (confirm('Are you sure you want to discard this form and start over? All entered data will be lost.')) {
        localStorage.removeItem(FORM_STORAGE_KEY);
        localStorage.removeItem('ujjwala_v3_last_error');
        window.location.reload();
    }
}

// ==================== ERROR HANDLING ====================
function showErrorModal(message, details) {
    $('#errorMessage').text(message);
    $('#errorDetails').text(details);
    $('#errorModal').modal('show');
}

function copyErrorDetails() {
    const details = $('#errorDetails').text();
    navigator.clipboard.writeText(details).then(() => {
        alert('Error details copied to clipboard!');
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}

// ==================== IMAGE VIEWER ====================
function viewImage(imageUrl, caption) {
    const modal = document.getElementById('imageModal');
    const modalImg = document.getElementById('modalImage');
    const modalCaption = document.getElementById('modalCaption');

    modal.style.display = 'block';
    modalImg.src = imageUrl;
    modalCaption.innerHTML = caption;

    modal.onclick = function(event) {
        if (event.target === modal) {
            closeImageModal();
        }
    };

    document.onkeydown = function(event) {
        if (event.key === 'Escape') {
            closeImageModal();
        }
    };
}

function closeImageModal() {
    document.getElementById('imageModal').style.display = 'none';
    document.onkeydown = null;
}

// ==================== EXPORTS ====================
window.nextStep = nextStep;
window.previousStep = previousStep;
window.goToStep = goToStep;
window.handleStepClick = handleStepClick;
window.submitApplication = submitApplication;
window.populateReviewSection = populateReviewSection;
window.toggleReviewSection = toggleReviewSection;
window.loadFormData = loadFormData;
window.discardAndStartOver = discardAndStartOver;
window.viewImage = viewImage;
window.closeImageModal = closeImageModal;
window.retryCurrentStep = retryCurrentStep;
window.enterManually = enterManually;
window.checkMigrationCertificate = checkMigrationCertificate;
window.copyErrorDetails = copyErrorDetails;

console.log('✅ Application Form Stepper Script Loaded');
