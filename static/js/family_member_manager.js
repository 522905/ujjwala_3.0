/**
 * Family Member Manager for Ujjwala V3
 * Handles adding/removing family members with UID photo upload capability
 * Updated for Stepper Flow - Reuses Step 1 Aadhaar data for SELF member
 */

let familyMemberCounter = 0;
let selfMemberAdded = false;

/**
 * Add a new family member with UID photo uploaders
 */
function addFamilyMemberWithUID() {
    familyMemberCounter++;
    const memberId = familyMemberCounter;

    // Determine if SELF should be pre-selected (first member and not already added)
    const shouldPreSelectSelf = !selfMemberAdded && familyMemberCounter === 1;

    // Load the family member HTML template
    const memberHtml = `
        <div class="card family-member-item" id="familyMember_${memberId}" style="margin-bottom: 20px; border: 2px solid #4299e1;">
            <div class="card-header" style="background: #2d3748; color: white;">
                <div class="d-flex justify-content-between align-items-center">
                    <h6 class="mb-0">
                        <i class="fas fa-user"></i> Family Member ${memberId}
                        <span class="member-relation-label" id="relationLabel_${memberId}"></span>
                    </h6>
                    <button type="button" class="btn btn-sm btn-danger" onclick="removeFamilyMemberWithUID(${memberId})">
                        <i class="fas fa-trash"></i> Remove
                    </button>
                </div>
            </div>
            <div class="card-body">
                <!-- Step 1: Relation to Applicant -->
                <div class="alert alert-primary">
                    <i class="fas fa-users"></i> <strong>Step 1: Select Relation to Applicant</strong><br>
                    ${!selfMemberAdded ? '<strong class="text-danger">⚠️ Please add yourself (SELF) first!</strong><br>' : ''}
                    Select the relationship of this family member to the applicant.
                    <br><small>आवेदक से इस परिवार के सदस्य का संबंध चुनें।</small>
                </div>

                <div class="row">
                    <div class="col-md-12 form-group">
                        <label class="required-field">Relation to Applicant</label>
                        <select name="family_member_${memberId}_relation" id="familyMember_${memberId}_relation"
                                class="form-control" required onchange="updateRelationLabel(${memberId})">
                            <option value="">-- Select Relation --</option>
                            <option value="SELF" ${shouldPreSelectSelf ? 'selected' : ''} ${selfMemberAdded ? 'disabled' : ''}>Self (स्वयं) - Applicant ${selfMemberAdded ? '(Already added)' : ''}</option>
                            <option value="HUSBAND">Husband (पति)</option>
                            <option value="FATHER">Father (पिता)</option>
                            <option value="MOTHER">Mother (माता)</option>
                            <option value="SON">Son (पुत्र)</option>
                            <option value="DAUGHTER">Daughter (पुत्री)</option>
                            <option value="BROTHER">Brother (भाई)</option>
                            <option value="SISTER">Sister (बहन)</option>
                            <option value="FATHER_IN_LAW">Father-in-law (ससुर)</option>
                            <option value="MOTHER_IN_LAW">Mother-in-law (सास)</option>
                            <option value="DAUGHTER_IN_LAW">Daughter-in-law (बहू)</option>
                            <option value="SON_IN_LAW">Son-in-law (दामाद)</option>
                            <option value="GRANDFATHER">Grandfather (दादा/नाना)</option>
                            <option value="GRANDMOTHER">Grandmother (दादी/नानी)</option>
                            <option value="GRANDSON">Grandson (पोता/नाती)</option>
                            <option value="GRANDDAUGHTER">Granddaughter (पोती/नातिन)</option>
                            <option value="UNCLE">Uncle (चाचा/मामा)</option>
                            <option value="AUNT">Aunt (चाची/मामी)</option>
                            <option value="OTHER">Other (अन्य)</option>
                        </select>
                    </div>
                </div>

                <!-- Step 2: Aadhaar Photo Upload (Hidden for SELF member) -->
                <div id="aadhaarUploadSection_${memberId}">
                    <div class="alert alert-secondary">
                        <i class="fas fa-camera"></i> <strong>Step 2: Upload Aadhaar/UID Photos</strong><br>
                        Upload both front and back photos of the Aadhaar card. The system will automatically extract and fill the details using OCR.
                        <br><small>आधार कार्ड के आगे और पीछे की फोटो अपलोड करें। सिस्टम OCR का उपयोग करके विवरण स्वचालित रूप से भर देगा।</small>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="required-field">Aadhaar Front Photo</label>
                                <div id="uidFrontUploader_${memberId}"></div>
                                <input type="hidden" name="family_member_${memberId}_uid_front_url" id="uidFrontUrl_${memberId}">
                                <div id="uidFrontPreview_${memberId}" class="mt-2"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="form-group">
                                <label class="required-field">Aadhaar Back Photo</label>
                                <div id="uidBackUploader_${memberId}"></div>
                                <input type="hidden" name="family_member_${memberId}_uid_back_url" id="uidBackUrl_${memberId}">
                                <div id="uidBackPreview_${memberId}" class="mt-2"></div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- OCR Status -->
                <div id="ocrStatus_${memberId}" class="mb-3"></div>

                <!-- Step 3: Member Details (Auto-filled by OCR or Manual Entry) -->
                <div class="alert alert-secondary">
                    <i class="fas fa-edit"></i> <strong>Step 3: Verify/Edit Member Details</strong><br>
                    After uploading photos, details will be auto-filled. Please verify and edit if needed.
                    <br><small>फोटो अपलोड करने के बाद, विवरण स्वचालित रूप से भर जाएंगे। कृपया सत्यापित करें।</small>
                </div>

                <!-- Basic Details Row -->
                <div class="row">
                    <div class="col-md-6 form-group">
                        <label class="required-field">Full Name</label>
                        <input type="text" name="family_member_${memberId}_name" id="familyMember_${memberId}_name"
                               class="form-control" placeholder="As per Aadhaar" required>
                    </div>
                    <div class="col-md-3 form-group">
                        <label class="required-field">Gender</label>
                        <select name="family_member_${memberId}_gender" id="familyMember_${memberId}_gender"
                                class="form-control" required>
                            <option value="">-- Select --</option>
                            <option value="M">Male (पुरुष)</option>
                            <option value="F">Female (महिला)</option>
                            <option value="O">Other (अन्य)</option>
                        </select>
                    </div>
                    <div class="col-md-3 form-group">
                        <label class="required-field">Date of Birth</label>
                        <input type="date" name="family_member_${memberId}_dob" id="familyMember_${memberId}_dob"
                               class="form-control" required>
                    </div>
                </div>

                <div class="row">
                    <div class="col-md-12 form-group">
                        <label class="required-field">Aadhaar Number</label>
                        <input type="text" name="family_member_${memberId}_aadhaar" id="familyMember_${memberId}_aadhaar"
                               class="form-control" placeholder="12-digit Aadhaar"
                               pattern="[0-9]{12}" maxlength="12" required>
                    </div>
                </div>

                <!-- Hidden fields for OCR data -->
                <input type="hidden" id="ocrResult_${memberId}" name="family_member_${memberId}_ocr_result">
            </div>
        </div>
    `;

    // Append to container
    $('#familyMembersContainer').append(memberHtml);

    // If this is SELF member (pre-selected), trigger relation update immediately
    if (shouldPreSelectSelf) {
        setTimeout(() => {
            updateRelationLabel(memberId);
        }, 100);
    } else {
        // Initialize UID uploaders for non-SELF members
        if (window.photoUploadManager) {
            window.photoUploadManager.initFamilyMemberUIDUploaders(memberId);
        }
    }

    // Scroll to the new member
    $(`#familyMember_${memberId}`)[0].scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/**
 * Remove family member with cleanup
 */
function removeFamilyMemberWithUID(memberId) {
    if (confirm('Are you sure you want to remove this family member?')) {
        // Check if this was the SELF member
        const relation = $(`#familyMember_${memberId}_relation`).val();
        if (relation === 'SELF') {
            selfMemberAdded = false;
            // Re-enable SELF option in other family members
            $('select[name^="family_member_"][name$="_relation"] option[value="SELF"]').each(function() {
                $(this).prop('disabled', false).text('Self (स्वयं) - Applicant');
            });
        }

        // Cleanup via photo upload manager
        if (window.photoUploadManager) {
            window.photoUploadManager.removeFamilyMember(memberId);
        }
    }
}

/**
 * Update relation label in card header and handle SELF member logic
 */
function updateRelationLabel(memberId) {
    const relation = $(`[name="family_member_${memberId}_relation"]`).val();
    const relationText = $(`[name="family_member_${memberId}_relation"] option:selected`).text();
    $(`#relationLabel_${memberId}`).text(`(${relationText})`);

    // Handle SELF member special logic
    if (relation === 'SELF') {
        selfMemberAdded = true;

        // Highlight as primary member
        $(`#familyMember_${memberId}`).css('border-color', '#dc3545');
        $(`#familyMember_${memberId} .card-header`).css('background', '#dc3545');

        // Hide Aadhaar upload section (reuse Step 1 data)
        $(`#aadhaarUploadSection_${memberId}`).hide();

        // Show info that Step 1 Aadhaar will be used
        $(`#ocrStatus_${memberId}`).html(`
            <div class="alert alert-info">
                <i class="fas fa-info-circle"></i> <strong>Note:</strong> Your Aadhaar has already been uploaded and verified in Step 1.
                <br>The details below are automatically filled from your Step 1 Aadhaar verification.
                <br><small>आपका आधार पहले ही चरण 1 में अपलोड और सत्यापित हो चुका है। नीचे के विवरण स्वचालित रूप से भरे गए हैं।</small>
            </div>
        `);

        // Reuse Step 1 Aadhaar data
        reuseSelfAadhaarDataFromStep1(memberId);

        // Disable SELF option in all other family members
        $('select[name^="family_member_"][name$="_relation"]').each(function() {
            if ($(this).attr('id') !== `familyMember_${memberId}_relation`) {
                $(this).find('option[value="SELF"]').prop('disabled', true).text('Self (स्वयं) - Applicant (Already added)');
            }
        });
    } else {
        // Reset styling for non-SELF members
        $(`#familyMember_${memberId}`).css('border-color', '#4299e1');
        $(`#familyMember_${memberId} .card-header`).css('background', '#2d3748');

        // Show Aadhaar upload section
        $(`#aadhaarUploadSection_${memberId}`).show();
        $(`#ocrStatus_${memberId}`).html('');

        // Initialize UID uploaders if not already done
        if (window.photoUploadManager && !window.photoUploadManager.uploaders[`uidFront_${memberId}`]) {
            window.photoUploadManager.initFamilyMemberUIDUploaders(memberId);
        }
    }
}

/**
 * Reuse Aadhaar data from Step 1 for SELF member
 * This avoids the need to re-upload Aadhaar for the applicant
 */
function reuseSelfAadhaarDataFromStep1(memberId) {
    console.log('Reusing Step 1 Aadhaar data for SELF member', memberId);

    // Get data from Step 1 applicant form
    const firstName = $('#applicant_first_name').val();
    const middleName = $('#applicant_middle_name').val();
    const lastName = $('#applicant_last_name').val();
    const fullName = [firstName, middleName, lastName].filter(n => n).join(' ');

    const gender = $('#applicant_gender').val();
    const dob = $('#applicant_dob_input').val();
    const aadhaar = $('#applicant_aadhaar_number').val();

    // Get Aadhaar photo URLs from Step 1
    const aadhaarFrontUrl = $('#uid_front_url').val();
    const aadhaarBackUrl = $('#uid_back_url').val();

    // Pre-fill family member form
    $(`[name="family_member_${memberId}_name"]`).val(fullName);
    $(`[name="family_member_${memberId}_gender"]`).val(gender);
    $(`[name="family_member_${memberId}_dob"]`).val(dob);
    $(`[name="family_member_${memberId}_aadhaar"]`).val(aadhaar);

    // Set UID photo URLs (reusing Step 1 photos)
    $(`#uidFrontUrl_${memberId}`).val(aadhaarFrontUrl);
    $(`#uidBackUrl_${memberId}`).val(aadhaarBackUrl);

    // Get OCR data if available
    if (window.APP_STATE && window.APP_STATE.ocrData) {
        $(`#ocrResult_${memberId}`).val(JSON.stringify(window.APP_STATE.ocrData));

        // Store in photo upload manager
        if (window.photoUploadManager) {
            window.photoUploadManager.familyMemberData.set(memberId, {
                uid_front_url: aadhaarFrontUrl,
                uid_back_url: aadhaarBackUrl,
                uid_original_front_url: aadhaarFrontUrl,
                uid_original_back_url: aadhaarBackUrl,
                ocr_result: window.APP_STATE.ocrData
            });
        }
    }

    // Make fields read-only since they're coming from verified Step 1 data
    $(`[name="family_member_${memberId}_name"]`).prop('readonly', true).css('background-color', '#e9ecef');
    $(`[name="family_member_${memberId}_gender"]`).prop('disabled', true).css('background-color', '#e9ecef');
    $(`[name="family_member_${memberId}_dob"]`).prop('readonly', true).css('background-color', '#e9ecef');
    $(`[name="family_member_${memberId}_aadhaar"]`).prop('readonly', true).css('background-color', '#e9ecef');

    console.log('✅ SELF member data populated from Step 1');
}

/**
 * Collect all family member data for submission
 */
function collectFamilyMemberData() {
    const familyMembers = [];

    $('.family-member-item').each(function() {
        const memberId = $(this).attr('id').replace('familyMember_', '');

        if (window.photoUploadManager) {
            const memberData = window.photoUploadManager.getFamilyMemberData(memberId);

            if (memberData.name && memberData.relation) {
                familyMembers.push(memberData);
            }
        }
    });

    return familyMembers;
}

/**
 * Validate that at least one SELF member exists
 */
function validateFamilyMembers() {
    const hasSelf = $('[name^="family_member_"][name$="_relation"]').filter(function() {
        return $(this).val() === 'SELF';
    }).length > 0;

    if (!hasSelf) {
        alert('Error: You must add yourself (SELF) as a family member.\n\nत्रुटि: आपको अपने आप को (SELF) परिवार के सदस्य के रूप में जोड़ना होगा।');
        return false;
    }

    // Validate UID photos uploaded for all non-SELF members
    let allHavePhotos = true;
    $('.family-member-item').each(function() {
        const memberId = $(this).attr('id').replace('familyMember_', '');
        const relation = $(`[name="family_member_${memberId}_relation"]`).val();
        const frontUrl = $(`#uidFrontUrl_${memberId}`).val();
        const backUrl = $(`#uidBackUrl_${memberId}`).val();

        // SELF member uses Step 1 photos, so skip validation
        if (relation !== 'SELF' && (!frontUrl || !backUrl)) {
            const name = $(`[name="family_member_${memberId}_name"]`).val() || 'Unnamed member';
            alert(`Error: Please upload both Aadhaar front and back photos for ${name}\n\nत्रुटि: कृपया ${name} के लिए आधार के आगे और पीछे दोनों फोटो अपलोड करें`);
            allHavePhotos = false;
            return false;
        }
    });

    return hasSelf && allHavePhotos;
}

// Initialize when document is ready
$(document).ready(function() {
    console.log('👨‍👩‍👧‍👦 Initializing Family Member Manager...');

    // Bind the add family member button
    $('#addFamilyMember').click(function() {
        addFamilyMemberWithUID();
    });

    // Show prompt to add SELF first if no members exist
    if ($('#familyMembersContainer').children().length === 0) {
        $('#familyMembersContainer').html(`
            <div class="alert alert-warning" id="addSelfPrompt">
                <i class="fas fa-user-plus"></i> <strong>Start by adding yourself!</strong><br>
                Click "Add Family Member" below and select relation as "SELF" to add yourself first.
                <br><small>सबसे पहले अपने आप को जोड़ें! नीचे "Add Family Member" पर क्लिक करें और "SELF" के रूप में अपने आप को जोड़ें।</small>
            </div>
        `);
    }

    console.log('✅ Family Member Manager Ready');
});
