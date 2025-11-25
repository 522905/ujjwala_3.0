/**
 * Ujjwala V3 Form - Photo Upload and OCR Processing
 * Handles profile photo, bank passbook, and family member UID photos with OCR
 * Updated for Stepper Flow
 */

class PhotoUploadManager {
    constructor() {
        this.tusEndpoint = 'https://tus.dca.arungas.com/files/';
        this.ocrEndpoint = '/app_utilities/application-utilities/get_details_for_aadhar/';
        this.uploaders = {};
        this.familyMemberData = new Map();
    }

    /**
     * Initialize profile photo uploader (Step 6)
     * This is for the main applicant photo, NOT for family members
     */
    initProfilePhotoUploader() {
        // Check if target element exists
        if (!$('#profilePhotoUploader').length) {
            console.error('Profile photo uploader target not found');
            return;
        }

        // Check if already initialized
        if (this.uploaders.profile) {
            console.log('Profile photo uploader already initialized');
            return;
        }

        const profileUppy = new Uppy.Core({
            autoProceed: true,
            maxFileSize: 10000000, // 10 MB
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*'],
            restrictions: {
                maxFileSize: 10000000,
                maxNumberOfFiles: 1,
                minNumberOfFiles: null,
                allowedFileTypes: ['image/*']
            }
        })
        .use(Uppy.Dashboard, {
            inline: true,
            target: '#profilePhotoUploader',
            height: 250,
            hideUploadButton: true,
            showRemoveButtonAfterComplete: false,
            note: 'Upload clear photo (Max 10MB)'
        })
        .use(Uppy.ImageEditor, {
            target: Uppy.Dashboard
        })
        .use(Uppy.Compressor, {
            quality: 0.9,
            maxWidth: 1024,
            maxHeight: 1024
        })
        .use(Uppy.Tus, {
            endpoint: this.tusEndpoint
        });

        profileUppy.on('upload-success', (file, response) => {
            const photoUrl = response.uploadURL;
            $('#profilePhotoUrl').val(photoUrl);

            // Hide uploader and show preview
            $('#profilePhotoUploader').hide();
            $('#profilePhotoPreview').html(`
                <div class="photo-preview-container" style="position: relative; display: inline-block;">
                    <img src="${photoUrl}" alt="Profile Photo"
                         style="max-width: 250px; border-radius: 8px; border: 3px solid #28a745; cursor: pointer;"
                         onclick="viewImage('${photoUrl}', 'Applicant Photo')">
                    <div style="position: absolute; top: 10px; right: 10px;">
                        <button type="button" class="btn btn-sm btn-warning" onclick="window.photoUploadManager.changeProfilePhoto()">
                            <i class="fas fa-edit"></i> Change
                        </button>
                    </div>
                </div>
                <p class="text-success mt-2"><i class="fas fa-check-circle"></i> Profile photo uploaded successfully!</p>
            `).show();

            console.log('Profile photo uploaded:', photoUrl);
        });

        profileUppy.on('upload-error', (file, error, response) => {
            console.error('Profile photo upload error:', error);
            alert('Failed to upload profile photo. Please try again.');
        });

        this.uploaders.profile = profileUppy;
    }

    /**
     * Change profile photo - show uploader again
     */
    changeProfilePhoto() {
        $('#profilePhotoUploader').show();
        $('#profilePhotoPreview').hide();
        if (this.uploaders.profile) {
            this.uploaders.profile.reset();
        }
    }

    /**
     * Initialize bank passbook photo uploader (Step 2)
     */
    initBankPassbookUploader() {
        // Check if already initialized
        if (this.uploaders.bankPassbook) {
            console.log('Bank passbook uploader already initialized');
            return;
        }

        const passbookUppy = new Uppy.Core({
            autoProceed: true,
            maxFileSize: 10000000, // 10 MB
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*'],
            restrictions: {
                maxFileSize: 10000000,
                maxNumberOfFiles: 1,
                minNumberOfFiles: null,
                allowedFileTypes: ['image/*']
            }
        })
        .use(Uppy.Dashboard, {
            inline: true,
            target: '#bankPassbookUploader',
            height: 250,
            hideUploadButton: true,
            showRemoveButtonAfterComplete: false,
            note: 'Upload clear passbook photo (Max 10MB)'
        })
        .use(Uppy.ImageEditor, {
            target: Uppy.Dashboard
        })
        .use(Uppy.Compressor, {
            quality: 0.9,
            maxWidth: 2048,
            maxHeight: 2048
        })
        .use(Uppy.Tus, {
            endpoint: this.tusEndpoint
        });

        passbookUppy.on('upload-success', (file, response) => {
            const photoUrl = response.uploadURL;
            $('#bankPassbookUrl').val(photoUrl);

            // Hide uploader and show preview
            $('#bankPassbookUploader').hide();
            $('#bankPassbookPreview').html(`
                <div class="photo-preview-container" style="position: relative; display: inline-block;">
                    <img src="${photoUrl}" alt="Bank Passbook"
                         style="max-width: 350px; border-radius: 8px; border: 3px solid #28a745; cursor: pointer;"
                         onclick="viewImage('${photoUrl}', 'Bank Passbook')">
                    <div style="position: absolute; top: 10px; right: 10px;">
                        <button type="button" class="btn btn-sm btn-warning" onclick="window.photoUploadManager.changeBankPassbookPhoto()">
                            <i class="fas fa-edit"></i> Change
                        </button>
                    </div>
                </div>
                <p class="text-success mt-2"><i class="fas fa-check-circle"></i> Bank passbook uploaded successfully!</p>
            `).show();

            console.log('Bank passbook uploaded:', photoUrl);
        });

        passbookUppy.on('upload-error', (file, error, response) => {
            console.error('Bank passbook upload error:', error);
            alert('Failed to upload bank passbook. Please try again.');
        });

        this.uploaders.bankPassbook = passbookUppy;
    }

    /**
     * Change bank passbook photo - show uploader again
     */
    changeBankPassbookPhoto() {
        $('#bankPassbookUploader').show();
        $('#bankPassbookPreview').hide();
        if (this.uploaders.bankPassbook) {
            this.uploaders.bankPassbook.reset();
        }
    }

    /**
     * Initialize UID photo uploaders for a family member
     * @param {number} memberId - Unique identifier for the family member
     */
    initFamilyMemberUIDUploaders(memberId) {
        console.log(`Initializing UID uploaders for member ${memberId}`);

        // UID Front uploader
        const frontUppy = new Uppy.Core({
            id: `uidFront_${memberId}`,
            autoProceed: true,
            maxFileSize: 50000000,
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*'],
        })
        .use(Uppy.Dashboard, {
            inline: true,
            target: `#uidFrontUploader_${memberId}`,
            height: 200,
            hideUploadButton: true,
            showRemoveButtonAfterComplete: false,
            note: 'Aadhaar Front (Max 50MB)'
        })
        .use(Uppy.ImageEditor, {
            target: Uppy.Dashboard
        })
        .use(Uppy.Compressor, {
            quality: 0.92,
            maxWidth: 1520
        })
        .use(Uppy.Tus, {
            endpoint: this.tusEndpoint
        });

        // UID Back uploader
        const backUppy = new Uppy.Core({
            id: `uidBack_${memberId}`,
            autoProceed: true,
            maxFileSize: 50000000,
            maxNumberOfFiles: 1,
            allowedFileTypes: ['image/*'],
        })
        .use(Uppy.Dashboard, {
            inline: true,
            target: `#uidBackUploader_${memberId}`,
            height: 200,
            hideUploadButton: true,
            showRemoveButtonAfterComplete: false,
            note: 'Aadhaar Back (Max 50MB)'
        })
        .use(Uppy.ImageEditor, {
            target: Uppy.Dashboard
        })
        .use(Uppy.Compressor, {
            quality: 0.92,
            maxWidth: 1520
        })
        .use(Uppy.Tus, {
            endpoint: this.tusEndpoint
        });

        // Initialize member data storage
        if (!this.familyMemberData.has(memberId)) {
            this.familyMemberData.set(memberId, {
                uid_front_url: null,
                uid_back_url: null,
                uid_original_front_url: null,
                uid_original_back_url: null,
                ocr_result: null
            });
        }

        const memberData = this.familyMemberData.get(memberId);

        frontUppy.on('upload-success', (file, response) => {
            memberData.uid_front_url = response.uploadURL;
            memberData.uid_original_front_url = response.uploadURL;
            $(`#uidFrontUrl_${memberId}`).val(response.uploadURL);

            // Hide uploader and show preview
            $(`#uidFrontUploader_${memberId}`).hide();
            $(`#uidFrontPreview_${memberId}`).html(`
                <div class="photo-preview-container" style="position: relative; display: inline-block; width: 100%;">
                    <img src="${response.uploadURL}" alt="UID Front"
                         style="max-width: 100%; height: 150px; object-fit: cover; border: 2px solid #28a745; border-radius: 5px; cursor: pointer;"
                         onclick="viewImage('${response.uploadURL}', 'Aadhaar Front')">
                    <div style="position: absolute; top: 5px; right: 5px;">
                        <button type="button" class="btn btn-sm btn-warning" onclick="window.photoUploadManager.changeUIDPhoto(${memberId}, 'front')">
                            <i class="fas fa-edit"></i>
                        </button>
                    </div>
                </div>
            `).show();

            this.checkAndTriggerOCR(memberId);
        });

        backUppy.on('upload-success', (file, response) => {
            memberData.uid_back_url = response.uploadURL;
            memberData.uid_original_back_url = response.uploadURL;
            $(`#uidBackUrl_${memberId}`).val(response.uploadURL);

            // Hide uploader and show preview
            $(`#uidBackUploader_${memberId}`).hide();
            $(`#uidBackPreview_${memberId}`).html(`
                <div class="photo-preview-container" style="position: relative; display: inline-block; width: 100%;">
                    <img src="${response.uploadURL}" alt="UID Back"
                         style="max-width: 100%; height: 150px; object-fit: cover; border: 2px solid #28a745; border-radius: 5px; cursor: pointer;"
                         onclick="viewImage('${response.uploadURL}', 'Aadhaar Back')">
                    <div style="position: absolute; top: 5px; right: 5px;">
                        <button type="button" class="btn btn-sm btn-warning" onclick="window.photoUploadManager.changeUIDPhoto(${memberId}, 'back')">
                            <i class="fas fa-edit"></i>
                        </button>
                    </div>
                </div>
            `).show();

            this.checkAndTriggerOCR(memberId);
        });

        this.uploaders[`uidFront_${memberId}`] = frontUppy;
        this.uploaders[`uidBack_${memberId}`] = backUppy;
    }

    /**
     * Change UID photo - show uploader again
     */
    changeUIDPhoto(memberId, side) {
        if (side === 'front') {
            $(`#uidFrontUploader_${memberId}`).show();
            $(`#uidFrontPreview_${memberId}`).hide();
            if (this.uploaders[`uidFront_${memberId}`]) {
                this.uploaders[`uidFront_${memberId}`].reset();
            }
        } else {
            $(`#uidBackUploader_${memberId}`).show();
            $(`#uidBackPreview_${memberId}`).hide();
            if (this.uploaders[`uidBack_${memberId}`]) {
                this.uploaders[`uidBack_${memberId}`].reset();
            }
        }
    }

    /**
     * Check if both UID photos are uploaded and trigger OCR
     */
    checkAndTriggerOCR(memberId) {
        const memberData = this.familyMemberData.get(memberId);

        if (memberData.uid_front_url && memberData.uid_back_url && !memberData.ocr_result) {
            this.processOCR(memberId);
        }
    }

    /**
     * Process OCR for family member UID
     */
    async processOCR(memberId) {
        const memberData = this.familyMemberData.get(memberId);

        // Show loading
        $(`#ocrStatus_${memberId}`).html(`
            <div class="alert alert-info">
                <i class="fas fa-spinner fa-spin"></i> Processing OCR... This may take 30 seconds. Please wait.
                <br><small>OCR प्रक्रिया में 30 सेकंड लग सकते हैं। कृपया प्रतीक्षा करें।</small>
            </div>
        `);

        try {
            const response = await $.ajax({
                url: this.ocrEndpoint,
                method: 'POST',
                data: {
                    uid_front_url: memberData.uid_front_url,
                    uid_back_url: memberData.uid_back_url
                },
                headers: { 'X-CSRFToken': this.getCookie('csrftoken') },
                timeout: 45000
            });

            console.log('OCR response for member', memberId, ':', response);

            if (response.status === 'success') {
                const data = JSON.parse(response.data.text);
                memberData.ocr_result = data;
                this.prefillFromOCR(memberId, data);

                $(`#ocrStatus_${memberId}`).html(`
                    <div class="alert alert-success">
                        <i class="fas fa-check-circle"></i> OCR completed successfully! Data has been pre-filled.
                        <br><small>OCR सफलतापूर्वक पूर्ण हुआ! डेटा पूर्व-भरा गया है।</small>
                    </div>
                `);

                // Auto-hide success message after 5 seconds
                setTimeout(() => {
                    $(`#ocrStatus_${memberId}`).fadeOut();
                }, 5000);
            } else {
                throw new Error(response.message || 'OCR failed');
            }

        } catch (error) {
            console.error('OCR Error for member', memberId, ':', error);
            $(`#ocrStatus_${memberId}`).html(`
                <div class="alert alert-warning">
                    <i class="fas fa-exclamation-triangle"></i> OCR failed or data quality is low. Please fill the details manually.
                    <br><small>OCR विफल रहा। कृपया विवरण मैन्युअल रूप से भरें।</small>
                </div>
            `);
        }
    }

    /**
     * Prefill form fields from OCR data
     */
    prefillFromOCR(memberId, ocrData) {
        console.log('Prefilling OCR data for member', memberId, ':', ocrData);

        // Extract data with confidence checking
        const getName = (data) => data.name?.value || '';
        const getDOB = (data) => {
            if (!data.dob?.value) return '';
            // Convert DD/MM/YYYY to YYYY-MM-DD
            const parts = data.dob.value.split('/');
            if (parts.length === 3) {
                return `${parts[2]}-${parts[1].padStart(2, '0')}-${parts[0].padStart(2, '0')}`;
            } else if (parts.length === 1) {
                // Year only
                return `${parts[0]}-01-01`;
            }
            return '';
        };
        const getGender = (data) => {
            const gender = data.gender?.value?.toUpperCase();
            if (gender === 'MALE' || gender === 'M') return 'M';
            if (gender === 'FEMALE' || gender === 'F') return 'F';
            return 'O';
        };
        const getAadhaar = (data) => data.aadhaar?.value || data.uid?.value || '';

        // Prefill fields
        const name = getName(ocrData);
        const dob = getDOB(ocrData);
        const gender = getGender(ocrData);
        const aadhaar = getAadhaar(ocrData);

        if (name) {
            $(`[name="family_member_${memberId}_name"]`).val(name);
        }

        if (dob) {
            $(`[name="family_member_${memberId}_dob"]`).val(dob);
        }

        if (gender) {
            $(`[name="family_member_${memberId}_gender"]`).val(gender);
        }

        if (aadhaar) {
            $(`[name="family_member_${memberId}_aadhaar"]`).val(aadhaar);
        }

        // Store OCR result
        $(`#ocrResult_${memberId}`).val(JSON.stringify(ocrData));
    }

    /**
     * Get CSRF cookie
     */
    getCookie(name) {
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

    /**
     * Get family member data for submission
     */
    getFamilyMemberData(memberId) {
        const memberData = this.familyMemberData.get(memberId) || {};
        return {
            name: $(`[name="family_member_${memberId}_name"]`).val(),
            relation: $(`[name="family_member_${memberId}_relation"]`).val(),
            gender: $(`[name="family_member_${memberId}_gender"]`).val(),
            dob: $(`[name="family_member_${memberId}_dob"]`).val(),
            aadhaar_number: $(`[name="family_member_${memberId}_aadhaar"]`).val(),
            uid_front_link: memberData.uid_front_url,
            uid_back_link: memberData.uid_back_url,
            uid_original_front_link: memberData.uid_original_front_url,
            uid_original_back_link: memberData.uid_original_back_url,
            uid_check_result: memberData.ocr_result,
            is_valid_uid: !!memberData.ocr_result,
            validated: !!memberData.ocr_result
        };
    }

    /**
     * Remove family member and cleanup uploaders
     */
    removeFamilyMember(memberId) {
        // Cleanup uploaders
        if (this.uploaders[`uidFront_${memberId}`]) {
            this.uploaders[`uidFront_${memberId}`].close();
            delete this.uploaders[`uidFront_${memberId}`];
        }
        if (this.uploaders[`uidBack_${memberId}`]) {
            this.uploaders[`uidBack_${memberId}`].close();
            delete this.uploaders[`uidBack_${memberId}`];
        }

        // Remove data
        this.familyMemberData.delete(memberId);

        // Remove DOM element
        $(`#familyMember_${memberId}`).remove();
    }
}

// Global instance
window.photoUploadManager = new PhotoUploadManager();

// Initialize on document ready
$(document).ready(function() {
    console.log('📸 Initializing Photo Upload Manager...');

    // Profile photo uploader will be initialized when Step 6 is reached
    // Bank passbook uploader will be initialized when Step 2 is reached
    // Family member UID uploaders initialized dynamically when members are added

    console.log('✅ Photo Upload Manager Ready');
});
