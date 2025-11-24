# Agent Aadhaar KYC Implementation Guide
## Cashfree OTP Verification Integration

**Version:** 1.0
**Date:** November 24, 2025
**Purpose:** Replace manual agent signup with Cashfree Aadhaar OTP verification

---

## Table of Contents

1. [Overview](#1-overview)
2. [Backend Implementation (Django)](#2-backend-implementation-django)
3. [Frontend Implementation (Flutter)](#3-frontend-implementation-flutter)
4. [Testing Guide](#4-testing-guide)
5. [Deployment Checklist](#5-deployment-checklist)

---

## 1. Overview

### 1.1 Current Flow (Manual Signup)
```
Agent → Enters Aadhaar + Mobile + Name + Address → Submit
       ↓
Admin Reviews → Approves → SMS sent with password
```

### 1.2 New Flow (Cashfree Aadhaar OTP)
```
Agent → Enters Aadhaar + Mobile → Generate OTP
       ↓
OTP sent to Aadhaar-linked mobile
       ↓
Agent → Enters OTP → Verify
       ↓
UIDAI data auto-retrieved (Name, DOB, Gender, Address, Photo)
       ↓
Admin Reviews verified data → Approves → SMS sent with password
```

### 1.3 Key Benefits
- ✅ No manual data entry (all verified from UIDAI)
- ✅ Fraud prevention (real Aadhaar verification)
- ✅ Data accuracy (no typos)
- ✅ Photo included for admin review
- ✅ Address auto-filled from Aadhaar
- ✅ Deduplication (same Aadhaar can't register twice)

---

## 2. Backend Implementation (Django)

### 2.1 Prerequisites

**Install Cashfree SDK dependencies:**
```bash
pip install requests arrow
```

**Add to `requirements.txt`:**
```txt
requests>=2.28.0
arrow>=1.2.2
```

### 2.2 Settings Configuration

**File:** `domestic_app/settings.py`

Add Cashfree API credentials:

```python
# Cashfree Verification API Configuration
CASHFREE_CLIENT_ID = os.environ.get('CASHFREE_CLIENT_ID', '')
CASHFREE_CLIENT_SECRET = os.environ.get('CASHFREE_CLIENT_SECRET', '')
CASHFREE_ENV = os.environ.get('CASHFREE_ENV', 'sandbox')  # or 'production'
CASHFREE_API_TIMEOUT = 30  # seconds
```

**Environment variables (`.env` file):**
```bash
CASHFREE_CLIENT_ID=your_client_id_here
CASHFREE_CLIENT_SECRET=your_client_secret_here
CASHFREE_ENV=sandbox
```

### 2.3 Create Cashfree API Client

**File:** `agent_auth/api/cashfree_api.py` (NEW)

```python
"""
Cashfree API Integration for Agent Aadhaar OTP verification
"""
import logging
import requests
from typing import Dict, Any, Optional
from django.conf import settings

logger = logging.getLogger(__name__)


class CashfreeAPIError(Exception):
    """Custom exception for Cashfree API errors"""

    def __init__(self, message: str, status_code: Optional[int] = None, response_data: Optional[Dict] = None):
        self.message = message
        self.status_code = status_code
        self.response_data = response_data or {}
        super().__init__(self.message)


class CashfreeAPI:
    """
    Cashfree Verification API client for Aadhaar OTP verification.
    Handles both sandbox and production environments.
    """

    def __init__(self):
        self.client_id = getattr(settings, 'CASHFREE_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'CASHFREE_CLIENT_SECRET', '')
        self.environment = getattr(settings, 'CASHFREE_ENV', 'sandbox')

        if not all([self.client_id, self.client_secret]):
            raise ValueError("Cashfree API credentials not configured in settings")

        # Set base URL based on environment
        if self.environment == 'production':
            self.base_url = 'https://api.cashfree.com'
        else:
            self.base_url = 'https://sandbox.cashfree.com'

        self.timeout = getattr(settings, 'CASHFREE_API_TIMEOUT', 30)

        logger.info(f"CashfreeAPI initialized for {self.environment} environment")

    def _get_headers(self) -> Dict[str, str]:
        """Get standard headers for Cashfree API requests"""
        return {
            'X-Client-Id': self.client_id,
            'X-Client-Secret': self.client_secret,
            'Content-Type': 'application/json'
        }

    def _make_request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Make HTTP request to Cashfree API with error handling.

        Args:
            method: HTTP method (GET, POST)
            endpoint: API endpoint path
            data: Request payload for POST requests

        Returns:
            API response data as dict

        Raises:
            CashfreeAPIError: If API request fails
        """
        url = f"{self.base_url}{endpoint}"
        headers = self._get_headers()

        try:
            logger.debug(f"Making {method} request to {url}")

            if method.upper() == 'POST':
                response = requests.post(url, json=data, headers=headers, timeout=self.timeout)
            elif method.upper() == 'GET':
                response = requests.get(url, headers=headers, timeout=self.timeout)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")

            # Parse response
            try:
                response_data = response.json()
            except ValueError:
                response_data = {'raw_response': response.text}

            # Check for API errors
            if response.status_code not in [200, 201]:
                error_message = response_data.get('message', f'API returned {response.status_code}')
                logger.error(f"Cashfree API error {response.status_code}: {error_message}")
                raise CashfreeAPIError(
                    message=error_message,
                    status_code=response.status_code,
                    response_data=response_data
                )

            logger.debug(f"Cashfree API request successful: {response.status_code}")
            return response_data

        except requests.RequestException as e:
            logger.error(f"Network error calling Cashfree API: {str(e)}")
            raise CashfreeAPIError(f"Network error: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected error calling Cashfree API: {str(e)}")
            raise CashfreeAPIError(f"Unexpected error: {str(e)}")

    def generate_aadhaar_otp(self, aadhaar_number: str) -> Dict[str, Any]:
        """
        Generate OTP for Aadhaar verification.

        Args:
            aadhaar_number: 12-digit Aadhaar number

        Returns:
            {
                'success': bool,
                'ref_id': str,           # Reference ID for OTP submission
                'message': str,          # Status message
                'if_number': str,        # Masked mobile number (if available)
                'error': str             # Error message if success=False
            }
        """
        try:
            # Clean Aadhaar number
            aadhaar_clean = aadhaar_number.replace(' ', '').replace('-', '')

            if len(aadhaar_clean) != 12 or not aadhaar_clean.isdigit():
                return {
                    'success': False,
                    'error': 'Invalid Aadhaar number format'
                }

            endpoint = '/verification/offline-aadhaar/otp'
            payload = {
                'aadhaar_number': aadhaar_clean
            }

            logger.info(f"Generating Aadhaar OTP for ****{aadhaar_clean[-4:]}")
            response_data = self._make_request('POST', endpoint, payload)

            return {
                'success': True,
                'ref_id': response_data.get('ref_id', ''),
                'message': response_data.get('message', 'OTP sent successfully'),
                'if_number': response_data.get('if_number', ''),  # Masked mobile number
            }

        except CashfreeAPIError as e:
            logger.error(f"Aadhaar OTP generation failed: {e.message}")
            return {
                'success': False,
                'error': e.message,
                'status_code': e.status_code
            }
        except Exception as e:
            logger.error(f"Unexpected error in Aadhaar OTP generation: {str(e)}")
            return {
                'success': False,
                'error': f'Unexpected error: {str(e)}'
            }

    def submit_aadhaar_otp(self, ref_id: str, otp: str) -> Dict[str, Any]:
        """
        Submit OTP for Aadhaar verification and retrieve user details.

        Args:
            ref_id: Reference ID from OTP generation
            otp: 6-digit OTP entered by user

        Returns:
            {
                'success': bool,
                'ref_id': str,
                'name': str,             # Full name from Aadhaar
                'dob': str,              # Date of birth (DD-MM-YYYY)
                'gender': str,           # Gender (M/F/O)
                'address': str,          # Full address string
                'split_address': dict,   # Parsed address components
                'photo_link': str,       # Base64 encoded photo
                'error': str             # Error message if success=False
            }
        """
        try:
            if not ref_id:
                return {
                    'success': False,
                    'error': 'Reference ID is required'
                }

            if not otp or len(otp) != 6 or not otp.isdigit():
                return {
                    'success': False,
                    'error': 'Invalid OTP format. Must be 6 digits'
                }

            endpoint = '/verification/offline-aadhaar/verify'
            payload = {
                'ref_id': ref_id,
                'otp': otp
            }

            logger.info(f"Submitting Aadhaar OTP for ref_id: {ref_id}")
            response_data = self._make_request('POST', endpoint, payload)

            # Extract user details from response
            result = {
                'success': True,
                'ref_id': response_data.get('ref_id', ref_id),
                'name': response_data.get('name', ''),
                'dob': response_data.get('dob', ''),  # Format: DD-MM-YYYY
                'gender': response_data.get('gender', ''),
                'address': response_data.get('address', ''),
                'split_address': response_data.get('split_address', {}),
                'photo_link': response_data.get('photo_link', ''),
            }

            logger.info(f"Aadhaar verification successful for {result['name']}")
            return result

        except CashfreeAPIError as e:
            logger.error(f"Aadhaar OTP submission failed: {e.message}")
            return {
                'success': False,
                'error': e.message,
                'status_code': e.status_code
            }
        except Exception as e:
            logger.error(f"Unexpected error in Aadhaar OTP submission: {str(e)}")
            return {
                'success': False,
                'error': f'Unexpected error: {str(e)}'
            }


# Global API client instance
_cashfree_api = None


def get_cashfree_api() -> CashfreeAPI:
    """Get or create global Cashfree API instance"""
    global _cashfree_api
    if _cashfree_api is None:
        _cashfree_api = CashfreeAPI()
    return _cashfree_api
```

### 2.4 Create AgentKYC Model

**File:** `agent_auth/models.py`

```python
from django.db import models
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.utils import timezone
import secrets
import string

User = get_user_model()


class AgentKYC(models.Model):
    """
    Agent KYC record created after successful Aadhaar OTP verification.
    Agent account is only created after admin approval.
    """
    STATUS_CHOICES = [
        ('aadhaar_verified', 'Aadhaar Verified - Pending Approval'),
        ('approved', 'Approved - Agent Created'),
        ('rejected', 'Rejected'),
    ]

    # User input during signup
    aadhaar_number = models.CharField(max_length=12, unique=True, help_text="Full 12-digit Aadhaar number")
    phone_number = models.CharField(max_length=15, help_text="Phone number for SMS notifications")

    # Cashfree verification data (populated after OTP submission)
    cashfree_ref_id = models.CharField(max_length=100, help_text="Cashfree reference ID for audit")
    aadhaar_name = models.CharField(max_length=100, help_text="Legal name from Aadhaar")
    aadhaar_dob = models.DateField(help_text="Date of birth from Aadhaar")
    aadhaar_gender = models.CharField(max_length=10, help_text="Gender from Aadhaar")
    aadhaar_address = models.TextField(help_text="Complete address from Aadhaar")
    aadhaar_photo = models.ImageField(
        upload_to='agent_kyc/aadhaar_photos/%Y/%m/', blank=True, null=True,
        help_text="Photo from Aadhaar verification"
    )
    aadhaar_response_data = models.JSONField(
        blank=True, null=True, help_text="Complete Aadhaar API response for audit"
    )

    # Status and approval workflow
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='aadhaar_verified')
    rejection_reason = models.TextField(blank=True, help_text="Reason for rejection if applicable")

    # Admin tracking
    approved_by = models.ForeignKey(
        User, null=True, blank=True, on_delete=models.SET_NULL, related_name='approved_agent_kycs'
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    # Generated agent account (set after approval)
    created_agent = models.OneToOneField(
        User, null=True, blank=True, on_delete=models.CASCADE,
        related_name='agent_kyc_source', help_text="Agent account created from this KYC"
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Agent KYC"
        verbose_name_plural = "Agent KYCs"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['aadhaar_number']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        name = self.aadhaar_name if self.aadhaar_name else "Unknown"
        last_4 = self.aadhaar_number[-4:] if self.aadhaar_number else "----"
        return f"{name} (****{last_4})"

    @property
    def aadhaar_last_4(self):
        """Display-safe Aadhaar representation"""
        return self.aadhaar_number[-4:] if self.aadhaar_number else "----"

    def clean(self):
        super().clean()
        if self.status == 'rejected' and not self.rejection_reason:
            raise ValidationError("Rejection reason is required when status is rejected.")

    def approve_and_create_agent(self, approved_by_user):
        """
        Approve KYC and create Agent account.
        Returns tuple: (created_agent, password)
        """
        if self.status != 'aadhaar_verified':
            raise ValueError(f"Cannot approve KYC with status {self.status}")

        if self.created_agent:
            raise ValueError("Agent already created for this KYC")

        # Generate random password
        password = self._generate_password()

        # Split name for agent account
        first_name, last_name = self._split_name(self.aadhaar_name)

        # Create agent account
        agent = User.objects.create_user(
            username=self.aadhaar_number,  # Use Aadhaar as username
            first_name=first_name,
            last_name=last_name,
            phone_number=self.phone_number,
            password=password,
            is_active=True,
        )

        # TODO: Assign agent role/permissions here
        # Example: agent.groups.add(agent_group)

        # Update KYC record
        self.status = 'approved'
        self.approved_by = approved_by_user
        self.approved_at = timezone.now()
        self.created_agent = agent
        self.save()

        return agent, password

    def reject(self, rejected_by_user, reason):
        """Reject KYC with reason"""
        self.status = 'rejected'
        self.rejection_reason = reason
        self.approved_by = rejected_by_user
        self.approved_at = timezone.now()
        self.save()

    def _generate_password(self, length=8):
        """Generate random password for SMS"""
        alphabet = string.ascii_letters + string.digits
        return ''.join(secrets.choice(alphabet) for _ in range(length))

    def _split_name(self, full_name):
        """Split full name into first and last name"""
        if not full_name:
            return "", ""

        parts = full_name.strip().split()
        if len(parts) == 1:
            return parts[0], ""
        else:
            return parts[0], ' '.join(parts[1:])
```

### 2.5 Create Migration

```bash
cd /Users/user/PycharmProjects/domestic_app
python manage.py makemigrations agent_auth
python manage.py migrate agent_auth
```

### 2.6 Create Utils

**File:** `agent_auth/utils.py` (NEW)

```python
"""
Utility functions for Agent KYC processing
"""
import logging
import base64
import io
from typing import Tuple
from django.core.files.base import ContentFile
from PIL import Image
import requests

logger = logging.getLogger(__name__)


def save_aadhaar_photo(base64_photo: str, filename_prefix: str) -> ContentFile:
    """
    Save base64 encoded photo to ContentFile for ImageField.

    Args:
        base64_photo: Base64 encoded image data
        filename_prefix: Prefix for filename (usually aadhaar last 4 digits)

    Returns:
        ContentFile: Django file object ready for ImageField
    """
    if not base64_photo:
        return None

    try:
        # Decode base64 image
        image_data = base64.b64decode(base64_photo)
        image_file = io.BytesIO(image_data)

        # Open with PIL to validate and get format
        with Image.open(image_file) as img:
            # Convert to RGB if necessary (removes alpha channel)
            if img.mode in ('RGBA', 'LA', 'P'):
                img = img.convert('RGB')

            # Create filename
            filename = f"aadhaar_photo_{filename_prefix}.jpg"

            # Save as JPEG with optimization
            output = io.BytesIO()
            img.save(output, format='JPEG', quality=85, optimize=True)
            output.seek(0)

            # Create Django file object
            django_file = ContentFile(output.read(), name=filename)

            return django_file

    except Exception as e:
        logger.error(f"Failed to save Aadhaar photo for {filename_prefix}: {str(e)}")
        return None


def send_sms_password(phone_number: str, username: str, password: str) -> bool:
    """
    Send login credentials via SMS using your SMS gateway.

    Args:
        phone_number: Agent's phone number
        username: Agent's username (Aadhaar number)
        password: Generated password

    Returns:
        bool: True if SMS sent successfully
    """
    try:
        # TODO: Integrate with your OpenVox SMS gateway
        # For now, just log the credentials
        message = f"""Arun Gas Agent Access Approved
Username: {username}
Password: {password}
You can now log in to the agent app."""

        logger.info(f"SMS credentials for {phone_number}: username={username}, password={password}")

        # TODO: Call your OpenVox SMS gateway here
        # return send_sms_via_openvox(phone_number, message)

        return True

    except Exception as e:
        logger.error(f"Failed to send password SMS to {phone_number}: {str(e)}")
        return False


def validate_aadhaar_number(aadhaar: str) -> Tuple[bool, str]:
    """
    Validate Aadhaar number format.

    Returns: (is_valid: bool, error_message: str)
    """
    if not aadhaar:
        return False, "Aadhaar number is required"

    # Remove spaces and check length
    aadhaar_clean = aadhaar.replace(' ', '')

    if len(aadhaar_clean) != 12:
        return False, "Aadhaar number must be exactly 12 digits"

    if not aadhaar_clean.isdigit():
        return False, "Aadhaar number must contain only digits"

    # Basic validation: should not start with 0 or 1
    if aadhaar_clean[0] in ['0', '1']:
        return False, "Invalid Aadhaar number format"

    return True, ""
```

### 2.7 Create API Views

**File:** `agent_auth/views.py`

```python
"""
Django REST API views for Agent KYC with Cashfree Aadhaar OTP verification
"""
import logging
import arrow
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.db import transaction

from .models import AgentKYC
from .api.cashfree_api import get_cashfree_api
from .utils import validate_aadhaar_number, save_aadhaar_photo, send_sms_password

logger = logging.getLogger(__name__)


@api_view(['POST'])
@permission_classes([AllowAny])
def initiate_agent_aadhaar_verification(request):
    """
    Step 1: Generate OTP for Aadhaar verification.

    Payload: {
        "aadhaar_number": "123456789012",
        "phone_number": "+919876543210"
    }

    Response: {
        "success": bool,
        "ref_id": str,        # Store this on client side
        "message": str,
        "if_number": str      # Masked mobile number
    }
    """
    try:
        aadhaar_number = request.data.get('aadhaar_number', '').strip()
        phone_number = request.data.get('phone_number', '').strip()

        # Validate inputs
        if not aadhaar_number or not phone_number:
            return Response({
                'success': False,
                'error': 'Aadhaar number and phone number are required'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validate Aadhaar format
        is_valid, error_msg = validate_aadhaar_number(aadhaar_number)
        if not is_valid:
            return Response({
                'success': False,
                'error': error_msg
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if Aadhaar already exists (prevent duplicate KYC)
        if AgentKYC.objects.filter(aadhaar_number=aadhaar_number).exists():
            return Response({
                'success': False,
                'error': 'Agent already exists with this Aadhaar number'
            }, status=status.HTTP_409_CONFLICT)

        # Call Cashfree API to generate OTP
        cashfree_api = get_cashfree_api()
        result = cashfree_api.generate_aadhaar_otp(aadhaar_number)

        if result['success']:
            logger.info(f"Agent Aadhaar OTP generated for ****{aadhaar_number[-4:]} via phone {phone_number}")

            return Response({
                'success': True,
                'ref_id': result['ref_id'],
                'message': result.get('message', 'OTP sent to your Aadhaar-linked mobile number'),
                'if_number': result.get('if_number', ''),
            })
        else:
            logger.error(f"Agent Aadhaar OTP generation failed for ****{aadhaar_number[-4:]}: {result.get('error')}")

            return Response({
                'success': False,
                'error': result.get('error', 'Failed to generate OTP')
            }, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Unexpected error in Agent Aadhaar OTP generation: {str(e)}")
        return Response({
            'success': False,
            'error': 'Internal server error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def submit_agent_aadhaar_otp(request):
    """
    Step 2: Submit OTP and create AgentKYC record.

    Payload: {
        "ref_id": "cashfree_reference_id",
        "otp": "123456",
        "aadhaar_number": "123456789012",  # for validation
        "phone_number": "+919876543210"    # for SMS later
    }

    Response: {
        "success": bool,
        "kyc_id": int,        # AgentKYC ID for reference
        "name": str,          # Name from Aadhaar
        "message": str
    }
    """
    try:
        ref_id = request.data.get('ref_id', '').strip()
        otp = request.data.get('otp', '').strip()
        aadhaar_number = request.data.get('aadhaar_number', '').strip()
        phone_number = request.data.get('phone_number', '').strip()

        # Validate inputs
        if not all([ref_id, otp, aadhaar_number, phone_number]):
            return Response({
                'success': False,
                'error': 'All fields are required: ref_id, otp, aadhaar_number, phone_number'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check duplicate Aadhaar
        if AgentKYC.objects.filter(aadhaar_number=aadhaar_number).exists():
            return Response({
                'success': False,
                'error': 'Agent already exists with this Aadhaar number'
            }, status=status.HTTP_409_CONFLICT)

        # Submit OTP to Cashfree
        cashfree_api = get_cashfree_api()
        result = cashfree_api.submit_aadhaar_otp(ref_id, otp)

        if result['success']:
            # Create AgentKYC record
            try:
                with transaction.atomic():
                    # Handle photo if present
                    photo_file = None
                    if result.get('photo_link'):
                        filename_prefix = aadhaar_number[-4:]
                        photo_file = save_aadhaar_photo(result['photo_link'], filename_prefix)

                    # Parse DOB (format: DD-MM-YYYY)
                    dob_str = result.get('dob', '01-01-1900')
                    dob_date = arrow.get(dob_str, 'DD-MM-YYYY').date()

                    # Extract address from split_address or use full address
                    address_data = result.get('split_address', {})
                    if address_data:
                        # Build formatted address from components
                        address_parts = [
                            address_data.get('house', ''),
                            address_data.get('street', ''),
                            address_data.get('locality', ''),
                            address_data.get('vtc', ''),
                            address_data.get('subdist', ''),
                            address_data.get('dist', ''),
                            address_data.get('state', ''),
                            address_data.get('country', ''),
                            f"PIN: {address_data.get('pincode', '')}" if address_data.get('pincode') else '',
                        ]
                        full_address = ', '.join(filter(None, address_parts))
                    else:
                        full_address = result.get('address', '')

                    agent_kyc = AgentKYC.objects.create(
                        aadhaar_number=aadhaar_number,
                        phone_number=phone_number,
                        cashfree_ref_id=result['ref_id'],
                        aadhaar_name=result.get('name', ''),
                        aadhaar_dob=dob_date,
                        aadhaar_gender=result.get('gender', ''),
                        aadhaar_address=full_address,
                        aadhaar_photo=photo_file,
                        aadhaar_response_data=result,
                        status='aadhaar_verified',
                    )

                    logger.info(f"AgentKYC created: ID {agent_kyc.pk} for {result.get('name', 'Unknown')}")

                    return Response({
                        'success': True,
                        'kyc_id': agent_kyc.pk,
                        'name': result.get('name', ''),
                        'message': 'Aadhaar verification successful. Your application is under review. You will receive login credentials via SMS once approved.'
                    })

            except Exception as e:
                logger.error(f"AgentKYC creation error: {str(e)}")
                return Response({
                    'success': False,
                    'error': 'Failed to create KYC record'
                }, status=status.HTTP_400_BAD_REQUEST)

        else:
            logger.error(f"Agent Aadhaar OTP verification failed for ref_id {ref_id}: {result.get('error')}")

            return Response({
                'success': False,
                'error': result.get('error', 'OTP verification failed')
            }, status=status.HTTP_400_BAD_REQUEST)

    except Exception as e:
        logger.error(f"Unexpected error in Agent Aadhaar OTP submission: {str(e)}")
        return Response({
            'success': False,
            'error': 'Internal server error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
```

### 2.8 Create URL Configuration

**File:** `agent_auth/urls.py`

```python
"""
Agent Authentication URLs
"""
from django.urls import path
from . import views

app_name = 'agent_auth'

urlpatterns = [
    # Aadhaar KYC endpoints
    path('initiate-aadhaar/', views.initiate_agent_aadhaar_verification, name='initiate_aadhaar'),
    path('submit-aadhaar-otp/', views.submit_agent_aadhaar_otp, name='submit_aadhaar_otp'),
]
```

**Update main `urls.py`:**

**File:** `domestic_app/urls.py`

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    # ... other URLs ...

    # Agent authentication
    path('auth/agent/', include('agent_auth.urls')),
]
```

### 2.9 Create Django Admin

**File:** `agent_auth/admin.py`

```python
from django.contrib import admin
from django.contrib import messages
from django.utils.html import format_html
from django.shortcuts import redirect
from django.urls import path, reverse
from django.http import HttpResponseRedirect
from django.template.response import TemplateResponse

from .models import AgentKYC
from .utils import send_sms_password


@admin.register(AgentKYC)
class AgentKYCAdmin(admin.ModelAdmin):
    list_display = [
        'aadhaar_display', 'aadhaar_name', 'phone_number', 'status_badge',
        'created_agent_link', 'created_at'
    ]
    list_filter = ['status', 'created_at', 'approved_by']
    search_fields = ['aadhaar_name', 'phone_number', 'aadhaar_number']
    readonly_fields = [
        'cashfree_ref_id', 'created_at', 'updated_at',
        'created_agent', 'photo_display', 'aadhaar_data_display'
    ]

    fieldsets = (
        ('User Input', {
            'fields': ('aadhaar_number', 'phone_number')
        }),
        ('Aadhaar Verification Data', {
            'fields': ('cashfree_ref_id', 'aadhaar_name', 'aadhaar_dob', 'aadhaar_gender',
                       'aadhaar_address', 'photo_display', 'aadhaar_data_display'),
            'description': 'Data retrieved from Cashfree after successful OTP verification'
        }),
        ('Approval Workflow', {
            'fields': ('status', 'rejection_reason', 'approved_by', 'approved_at', 'created_agent')
        }),
        ('Audit Trail', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )

    actions = ['approve_selected', 'reject_selected']

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('<int:object_id>/approve/', self.admin_site.admin_view(self.approve_view),
                 name='agent_auth_agentkyc_approve'),
            path('<int:object_id>/reject/', self.admin_site.admin_view(self.reject_view),
                 name='agent_auth_agentkyc_reject'),
        ]
        return custom_urls + urls

    def aadhaar_display(self, obj):
        """Display only last 4 digits for privacy"""
        return f"****{obj.aadhaar_last_4}"
    aadhaar_display.short_description = "Aadhaar"

    def aadhaar_data_display(self, obj):
        """Display formatted Aadhaar API response"""
        if obj.aadhaar_response_data:
            import json
            formatted_json = json.dumps(obj.aadhaar_response_data, indent=2)
            return format_html(
                '<pre style="background: #f8f9fa; padding: 10px; border-radius: 4px; max-height: 300px; overflow-y: auto;">{}</pre>',
                formatted_json)
        return "No data available"
    aadhaar_data_display.short_description = "Complete API Response"

    def status_badge(self, obj):
        colors = {
            'aadhaar_verified': 'orange',
            'approved': 'green',
            'rejected': 'red'
        }
        color = colors.get(obj.status, 'gray')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px; font-size: 11px;">{}</span>',
            color, obj.get_status_display()
        )
    status_badge.short_description = "Status"

    def created_agent_link(self, obj):
        if obj.created_agent:
            url = reverse('admin:users_user_change', args=[obj.created_agent.pk])
            return format_html('<a href="{}">{}</a>', url, obj.created_agent.username)
        return "—"
    created_agent_link.short_description = "Created Agent"

    def photo_display(self, obj):
        """Display Aadhaar photo in admin"""
        if obj.aadhaar_photo:
            return format_html(
                '<img src="{}" style="max-width: 150px; max-height: 200px; border: 1px solid #ddd; border-radius: 4px;" />',
                obj.aadhaar_photo.url
            )
        return "No photo available"
    photo_display.short_description = "Aadhaar Photo"

    def approve_view(self, request, object_id):
        """Approve KYC and create agent account"""
        kyc = self.get_object(request, object_id)
        if kyc is None:
            return self.response_post_save_change(request, None)

        if request.method == 'POST':
            try:
                agent, password = kyc.approve_and_create_agent(request.user)

                # Send SMS with login credentials
                sms_sent = send_sms_password(kyc.phone_number, kyc.aadhaar_number, password)

                if sms_sent:
                    messages.success(request, f"KYC approved! Agent {agent.username} created and SMS sent.")
                else:
                    messages.warning(request,
                                     f"KYC approved! Agent {agent.username} created but SMS failed. Password: {password}")

                return HttpResponseRedirect(reverse('admin:agent_auth_agentkyc_changelist'))

            except Exception as e:
                messages.error(request, f"Failed to approve KYC: {str(e)}")
                return HttpResponseRedirect(reverse('admin:agent_auth_agentkyc_change', args=[object_id]))

        context = {
            'title': f'Approve KYC: {kyc}',
            'kyc': kyc,
            'opts': self.model._meta,
        }
        return TemplateResponse(request, 'admin/agent_auth/approve_confirmation.html', context)

    def reject_view(self, request, object_id):
        """Reject KYC with reason"""
        kyc = self.get_object(request, object_id)
        if kyc is None:
            return self.response_post_save_change(request, None)

        if request.method == 'POST':
            reason = request.POST.get('reason', '').strip()
            if not reason:
                messages.error(request, "Rejection reason is required")
                return HttpResponseRedirect(request.get_full_path())

            try:
                kyc.reject(request.user, reason)
                messages.success(request, f"KYC rejected: {kyc}")
                return HttpResponseRedirect(reverse('admin:agent_auth_agentkyc_changelist'))
            except Exception as e:
                messages.error(request, f"Failed to reject KYC: {str(e)}")

        context = {
            'title': f'Reject KYC: {kyc}',
            'kyc': kyc,
            'opts': self.model._meta,
        }
        return TemplateResponse(request, 'admin/agent_auth/reject_form.html', context)

    def approve_selected(self, request, queryset):
        """Bulk approve action"""
        approved_count = 0
        for kyc in queryset.filter(status='aadhaar_verified'):
            try:
                agent, password = kyc.approve_and_create_agent(request.user)
                send_sms_password(kyc.phone_number, kyc.aadhaar_number, password)
                approved_count += 1
            except Exception as e:
                messages.error(request, f"Failed to approve {kyc}: {str(e)}")

        if approved_count:
            messages.success(request, f"Successfully approved {approved_count} KYC records")
    approve_selected.short_description = "Approve selected KYCs"

    def reject_selected(self, request, queryset):
        """Bulk reject - requires reason"""
        # Implementation similar to UserKYC reject_selected
        pass
    reject_selected.short_description = "Reject selected KYCs"
```

### 2.10 Create Admin Templates

**File:** `agent_auth/templates/admin/agent_auth/approve_confirmation.html`

```html
{% extends "admin/base_site.html" %}
{% load i18n %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="submit-row">
    <h1>{{ title }}</h1>

    <div class="form-row">
        <div class="field-box">
            <h2>KYC Details</h2>
            <div style="display: flex; gap: 20px; align-items: flex-start;">
                <div style="flex: 1;">
                    <p><strong>Name:</strong> {{ kyc.aadhaar_name }}</p>
                    <p><strong>Aadhaar:</strong> ****{{ kyc.aadhaar_last_4 }}</p>
                    <p><strong>Phone:</strong> {{ kyc.phone_number }}</p>
                    <p><strong>DOB:</strong> {{ kyc.aadhaar_dob }}</p>
                    <p><strong>Gender:</strong> {{ kyc.aadhaar_gender }}</p>
                    <p><strong>Address:</strong> {{ kyc.aadhaar_address }}</p>
                    <p><strong>Status:</strong> {{ kyc.get_status_display }}</p>
                </div>
                {% if kyc.aadhaar_photo %}
                <div style="flex: 0 0 auto;">
                    <img src="{{ kyc.aadhaar_photo.url }}"
                         style="max-width: 120px; max-height: 150px; border: 1px solid #ddd; border-radius: 4px;"
                         alt="Aadhaar Photo" />
                </div>
                {% endif %}
            </div>
        </div>
    </div>

    <div class="form-row">
        <p>
            <strong>Confirm approval:</strong> This will create an Agent account and send SMS with login credentials.
        </p>
    </div>

    <form method="post">
        {% csrf_token %}
        <div class="submit-row">
            <input type="submit" value="Approve KYC" class="default" />
            <a href="{% url 'admin:agent_auth_agentkyc_changelist' %}" class="button">Cancel</a>
        </div>
    </form>
</div>
{% endblock %}
```

**File:** `agent_auth/templates/admin/agent_auth/reject_form.html`

```html
{% extends "admin/base_site.html" %}
{% load i18n %}

{% block title %}{{ title }}{% endblock %}

{% block content %}
<div class="submit-row">
    <h1>{{ title }}</h1>

    <div class="form-row">
        <div class="field-box">
            <h2>KYC Details</h2>
            <p><strong>Name:</strong> {{ kyc.aadhaar_name }}</p>
            <p><strong>Aadhaar:</strong> ****{{ kyc.aadhaar_last_4 }}</p>
            <p><strong>Phone:</strong> {{ kyc.phone_number }}</p>
        </div>
    </div>

    <form method="post">
        {% csrf_token %}
        <div class="form-row">
            <label for="reason"><strong>Rejection Reason:</strong></label>
            <textarea name="reason" id="reason" rows="4" cols="60" required></textarea>
        </div>

        <div class="submit-row">
            <input type="submit" value="Reject KYC" class="default" />
            <a href="{% url 'admin:agent_auth_agentkyc_changelist' %}" class="button">Cancel</a>
        </div>
    </form>
</div>
{% endblock %}
```

---

## 3. Frontend Implementation (Flutter)

### 3.1 Add Dependencies

**File:** `pubspec.yaml`

Add if not already present:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.0

  # Networking
  dio: ^5.3.0

  # Secure Storage
  flutter_secure_storage: ^9.0.0

  # UI
  flutter_spinkit: ^5.2.0
```

Run:
```bash
flutter pub get
```

### 3.2 Create Data Models

**File:** `lib/data/models/agent_kyc_models.dart` (NEW)

```dart
/// Agent KYC status enum
enum AgentKYCStatus {
  pending,
  aadhaarVerified,
  approved,
  rejected;

  String toServerValue() {
    switch (this) {
      case AgentKYCStatus.aadhaarVerified:
        return 'aadhaar_verified';
      case AgentKYCStatus.approved:
        return 'approved';
      case AgentKYCStatus.rejected:
        return 'rejected';
      default:
        return 'pending';
    }
  }

  static AgentKYCStatus fromServerValue(String value) {
    switch (value) {
      case 'aadhaar_verified':
        return AgentKYCStatus.aadhaarVerified;
      case 'approved':
        return AgentKYCStatus.approved;
      case 'rejected':
        return AgentKYCStatus.rejected;
      default:
        return AgentKYCStatus.pending;
    }
  }
}

/// Response from initiate Aadhaar verification
class AadhaarOTPResponse {
  final bool success;
  final String refId;
  final String message;
  final String? maskedNumber;
  final String? error;

  AadhaarOTPResponse({
    required this.success,
    required this.refId,
    required this.message,
    this.maskedNumber,
    this.error,
  });

  factory AadhaarOTPResponse.fromJson(Map<String, dynamic> json) {
    return AadhaarOTPResponse(
      success: json['success'] ?? false,
      refId: json['ref_id'] ?? '',
      message: json['message'] ?? '',
      maskedNumber: json['if_number'],
      error: json['error'],
    );
  }
}

/// Response from OTP submission
class AgentKYCResponse {
  final bool success;
  final int? kycId;
  final String? name;
  final String message;
  final String? error;

  AgentKYCResponse({
    required this.success,
    this.kycId,
    this.name,
    required this.message,
    this.error,
  });

  factory AgentKYCResponse.fromJson(Map<String, dynamic> json) {
    return AgentKYCResponse(
      success: json['success'] ?? false,
      kycId: json['kyc_id'],
      name: json['name'],
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

/// Exception for Agent KYC errors
class AgentKYCException implements Exception {
  final String message;
  final int? statusCode;

  AgentKYCException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
```

### 3.3 Create API Service

**File:** `lib/data/services/agent_auth_service.dart` (NEW)

```dart
import 'package:dio/dio.dart';
import '../models/agent_kyc_models.dart';

class AgentAuthService {
  final Dio _dio;
  final String baseUrl;

  AgentAuthService(this._dio, {required this.baseUrl});

  /// Step 1: Initiate Aadhaar verification and generate OTP
  Future<AadhaarOTPResponse> initiateAadhaarVerification({
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/agent/initiate-aadhaar/',
        data: {
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      final otpResponse = AadhaarOTPResponse.fromJson(response.data);

      if (!otpResponse.success) {
        throw AgentKYCException(
          otpResponse.error ?? 'Failed to generate OTP',
        );
      }

      return otpResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AgentKYCException(
          'Agent with this Aadhaar already exists',
          statusCode: 409,
        );
      }

      final errorMessage = e.response?.data?['error'] ?? 'Failed to initiate verification';
      throw AgentKYCException(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      throw AgentKYCException('Unexpected error: ${e.toString()}');
    }
  }

  /// Step 2: Submit OTP and complete KYC
  Future<AgentKYCResponse> submitAadhaarOTP({
    required String refId,
    required String otp,
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/agent/submit-aadhaar-otp/',
        data: {
          'ref_id': refId,
          'otp': otp,
          'aadhaar_number': aadhaarNumber,
          'phone_number': phoneNumber,
        },
      );

      final kycResponse = AgentKYCResponse.fromJson(response.data);

      if (!kycResponse.success) {
        throw AgentKYCException(
          kycResponse.error ?? 'OTP verification failed',
        );
      }

      return kycResponse;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AgentKYCException(
          'Agent with this Aadhaar already exists',
          statusCode: 409,
        );
      }

      final errorMessage = e.response?.data?['error'] ?? 'OTP verification failed';
      throw AgentKYCException(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      throw AgentKYCException('Unexpected error: ${e.toString()}');
    }
  }
}
```

### 3.4 Create Provider (State Management)

**File:** `lib/providers/agent_auth_provider.dart` (NEW)

```dart
import 'package:flutter/foundation.dart';
import '../data/services/agent_auth_service.dart';
import '../data/models/agent_kyc_models.dart';

class AgentAuthProvider extends ChangeNotifier {
  final AgentAuthService _authService;

  AgentAuthProvider(this._authService);

  bool _isLoading = false;
  String? _errorMessage;
  AadhaarOTPResponse? _otpResponse;
  AgentKYCResponse? _kycResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AadhaarOTPResponse? get otpResponse => _otpResponse;
  AgentKYCResponse? get kycResponse => _kycResponse;

  /// Generate OTP for Aadhaar verification
  Future<bool> generateOTP({
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _otpResponse = await _authService.initiateAadhaarVerification(
        aadhaarNumber: aadhaarNumber,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AgentKYCException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit OTP and complete KYC
  Future<bool> verifyOTP({
    required String otp,
    required String aadhaarNumber,
    required String phoneNumber,
  }) async {
    if (_otpResponse == null) {
      _errorMessage = 'Please generate OTP first';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kycResponse = await _authService.submitAadhaarOTP(
        refId: _otpResponse!.refId,
        otp: otp,
        aadhaarNumber: aadhaarNumber,
        phoneNumber: phoneNumber,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on AgentKYCException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear state
  void clear() {
    _isLoading = false;
    _errorMessage = null;
    _otpResponse = null;
    _kycResponse = null;
    notifyListeners();
  }
}
```

### 3.5 Create UI Screens

#### Screen 1: Agent Signup (Aadhaar Input)

**File:** `lib/presentation/auth/agent_signup_screen.dart` (REPLACE)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/agent_auth_provider.dart';
import 'agent_otp_screen.dart';

class AgentSignupScreen extends StatefulWidget {
  const AgentSignupScreen({Key? key}) : super(key: key);

  @override
  State<AgentSignupScreen> createState() => _AgentSignupScreenState();
}

class _AgentSignupScreenState extends State<AgentSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Signup - KYC Verification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Icon(
                  Icons.verified_user,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                Text(
                  'Aadhaar OTP Verification',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Your data will be automatically verified from UIDAI. No manual entry required.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Aadhaar Number Input
                TextFormField(
                  controller: _aadhaarController,
                  decoration: InputDecoration(
                    labelText: 'Aadhaar Number',
                    hintText: 'Enter 12-digit Aadhaar number',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Aadhaar number is required';
                    }
                    if (value.length != 12) {
                      return 'Aadhaar must be 12 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: const Icon(Icons.phone),
                    prefix: const Text('+91 '),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (value.length != 10) {
                      return 'Phone must be 10 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Generate OTP Button
                Consumer<AgentAuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _generateOTP,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Generate OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Info Text
                Text(
                  'OTP will be sent to your Aadhaar-linked mobile number',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateOTP() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AgentAuthProvider>(context, listen: false);

    final success = await authProvider.generateOTP(
      aadhaarNumber: _aadhaarController.text,
      phoneNumber: '+91${_phoneController.text}',
    );

    if (!mounted) return;

    if (success) {
      // Navigate to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgentOTPScreen(
            aadhaarNumber: _aadhaarController.text,
            phoneNumber: '+91${_phoneController.text}',
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to generate OTP'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
```

#### Screen 2: OTP Verification

**File:** `lib/presentation/auth/agent_otp_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/agent_auth_provider.dart';
import 'agent_kyc_review_screen.dart';

class AgentOTPScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String phoneNumber;

  const AgentOTPScreen({
    Key? key,
    required this.aadhaarNumber,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<AgentOTPScreen> createState() => _AgentOTPScreenState();
}

class _AgentOTPScreenState extends State<AgentOTPScreen> {
  final _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AgentAuthProvider>(context);
    final maskedNumber = authProvider.otpResponse?.maskedNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.verified_user,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              Text(
                'OTP Verification',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                maskedNumber != null
                    ? 'OTP sent to Aadhaar-linked mobile:\n$maskedNumber'
                    : 'OTP sent to your Aadhaar-linked mobile',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // OTP Input
              TextFormField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter 6-digit OTP',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 24),

              // Verify Button
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Resend OTP
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AgentAuthProvider>(context, listen: false);

    final success = await authProvider.verifyOTP(
      otp: _otpController.text,
      aadhaarNumber: widget.aadhaarNumber,
      phoneNumber: widget.phoneNumber,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AgentKYCReviewScreen(
            kycId: authProvider.kycResponse!.kycId!,
            name: authProvider.kycResponse!.name!,
            message: authProvider.kycResponse!.message,
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'OTP verification failed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
```

#### Screen 3: KYC Review/Success

**File:** `lib/presentation/auth/agent_kyc_review_screen.dart` (NEW)

```dart
import 'package:flutter/material.dart';

class AgentKYCReviewScreen extends StatelessWidget {
  final int kycId;
  final String name;
  final String message;

  const AgentKYCReviewScreen({
    Key? key,
    required this.kycId,
    required this.name,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Submitted'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 120,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),

                Text(
                  'KYC Verification Successful!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Name: $name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'KYC ID: #$kycId',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Status Card
                Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 48,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Application Under Review',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You will receive login credentials via SMS once your application is approved by the admin.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Back to Login Button
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to login screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 3.6 Wire Up Provider in Main App

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'data/services/agent_auth_service.dart';
import 'providers/agent_auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize Dio
    final dio = Dio(BaseOptions(
      baseUrl: 'https://your-domain.com',  // TODO: Update with your API URL
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Initialize services
    final agentAuthService = AgentAuthService(
      dio,
      baseUrl: 'https://your-domain.com',  // TODO: Update with your API URL
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AgentAuthProvider(agentAuthService),
        ),
        // ... other providers ...
      ],
      child: MaterialApp(
        title: 'Arun Gas Agent App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const YourHomeScreen(),  // Your existing home screen
      ),
    );
  }
}
```

---

## 4. Testing Guide

### 4.1 Backend Testing

#### Test Cashfree API Configuration

```python
# Run in Django shell
python manage.py shell

from agent_auth.api.cashfree_api import get_cashfree_api

# Test API initialization
api = get_cashfree_api()
print(f"Environment: {api.environment}")
print(f"Base URL: {api.base_url}")
```

#### Test OTP Generation (Sandbox)

```python
# In Django shell
from agent_auth.api.cashfree_api import get_cashfree_api

api = get_cashfree_api()

# Use sandbox test Aadhaar: 999999990019
result = api.generate_aadhaar_otp('999999990019')
print(result)

# Expected output:
# {'success': True, 'ref_id': 'some_ref_id', 'message': '...', 'if_number': '...'}
```

#### Test OTP Verification (Sandbox)

```python
# In sandbox, OTP is usually 123456
result = api.submit_aadhaar_otp(ref_id='your_ref_id', otp='123456')
print(result)

# Check that name, DOB, gender, address are populated
```

#### Test API Endpoints with cURL

**Generate OTP:**
```bash
curl -X POST http://localhost:8000/auth/agent/initiate-aadhaar/ \
  -H "Content-Type: application/json" \
  -d '{"aadhaar_number": "999999990019", "phone_number": "+919876543210"}'
```

**Submit OTP:**
```bash
curl -X POST http://localhost:8000/auth/agent/submit-aadhaar-otp/ \
  -H "Content-Type: application/json" \
  -d '{
    "ref_id": "your_ref_id_here",
    "otp": "123456",
    "aadhaar_number": "999999990019",
    "phone_number": "+919876543210"
  }'
```

### 4.2 Frontend Testing

#### Test in Flutter

```dart
// Test OTP generation
final authProvider = Provider.of<AgentAuthProvider>(context, listen: false);

final success = await authProvider.generateOTP(
  aadhaarNumber: '999999990019',  // Sandbox test Aadhaar
  phoneNumber: '+919876543210',
);

print('OTP Generation: $success');
print('Ref ID: ${authProvider.otpResponse?.refId}');
```

#### Test OTP Verification

```dart
// Test OTP verification (sandbox OTP is usually 123456)
final success = await authProvider.verifyOTP(
  otp: '123456',
  aadhaarNumber: '999999990019',
  phoneNumber: '+919876543210',
);

print('OTP Verification: $success');
print('KYC ID: ${authProvider.kycResponse?.kycId}');
print('Name: ${authProvider.kycResponse?.name}');
```

### 4.3 Admin Testing

1. **Access Django Admin**: `http://localhost:8000/admin/agent_auth/agentkyc/`
2. **Find Pending KYC**: Filter by status = "Aadhaar Verified - Pending Approval"
3. **Review Data**: Check name, DOB, gender, address, photo
4. **Approve KYC**: Click "Approve" button
5. **Check SMS**: Verify SMS sent with username + password
6. **Check User Created**: Navigate to Users admin, find new agent account

### 4.4 Integration Testing

**Complete Flow Test:**

1. Open Flutter app → Navigate to Agent Signup
2. Enter test Aadhaar: `999999990019`
3. Enter phone: `9876543210`
4. Click "Generate OTP"
5. Verify API call successful (check Django logs)
6. Enter OTP: `123456` (sandbox default)
7. Click "Verify OTP"
8. Verify success screen shows
9. Check Django admin for new AgentKYC record
10. Admin approves KYC
11. Verify SMS sent (check logs)
12. Test login with Aadhaar + generated password

---

## 5. Deployment Checklist

### 5.1 Backend Deployment

- [ ] **Add environment variables** to production server:
  ```bash
  CASHFREE_CLIENT_ID=your_production_client_id
  CASHFREE_CLIENT_SECRET=your_production_secret
  CASHFREE_ENV=production
  ```

- [ ] **Run migrations**:
  ```bash
  python manage.py migrate agent_auth
  ```

- [ ] **Collect static files**:
  ```bash
  python manage.py collectstatic --noinput
  ```

- [ ] **Test Cashfree API** in production:
  ```python
  from agent_auth.api.cashfree_api import get_cashfree_api
  api = get_cashfree_api()
  # Test with real Aadhaar (with consent)
  ```

- [ ] **Configure SMS gateway** in `agent_auth/utils.py`:
  - Update `send_sms_password()` function
  - Integrate with OpenVox SMS gateway

- [ ] **Set up logging**:
  - Configure `LOGGING` in settings.py
  - Monitor Cashfree API calls
  - Track KYC approvals

- [ ] **Set up monitoring**:
  - Track failed OTP attempts
  - Monitor duplicate Aadhaar attempts
  - Alert on API errors

### 5.2 Frontend Deployment

- [ ] **Update API base URL** in `lib/main.dart`:
  ```dart
  baseUrl: 'https://your-production-domain.com',
  ```

- [ ] **Test in production build**:
  ```bash
  flutter build apk --release
  # or
  flutter build ios --release
  ```

- [ ] **Test complete flow** on production:
  - Generate OTP
  - Verify OTP
  - Check success screen
  - Verify backend record created

### 5.3 Security Checklist

- [ ] **Never log sensitive data**:
  - Don't log full Aadhaar numbers
  - Don't log OTPs
  - Don't log generated passwords

- [ ] **Rate limiting**:
  - Add rate limiting to OTP endpoints
  - Prevent brute force OTP attempts
  - Maximum 3 OTP generations per Aadhaar per hour

- [ ] **Input validation**:
  - Validate Aadhaar format
  - Validate phone format
  - Sanitize all inputs

- [ ] **HTTPS only**:
  - Force HTTPS in production
  - Use secure cookies
  - Enable HSTS

### 5.4 Documentation

- [ ] **Update API documentation** with new endpoints
- [ ] **Document admin approval workflow**
- [ ] **Create user guide** for agents
- [ ] **Document error codes** and troubleshooting

---

## 6. Troubleshooting

### Common Issues

#### Issue: "Cashfree API credentials not configured"

**Solution:**
- Check `.env` file exists
- Verify `CASHFREE_CLIENT_ID` and `CASHFREE_CLIENT_SECRET` are set
- Restart Django server after adding credentials

#### Issue: "OTP verification failed"

**Possible causes:**
- Incorrect OTP entered
- OTP expired (valid for 10 minutes)
- Network timeout
- Cashfree API error

**Solution:**
- Check Django logs for exact error
- Verify ref_id is correct
- Try resending OTP
- Check Cashfree dashboard for API status

#### Issue: "Agent already exists with this Aadhaar"

**Solution:**
- This is expected behavior (deduplication)
- Check Django admin for existing AgentKYC record
- If duplicate is error, delete old record and retry

#### Issue: "Photo not displaying in admin"

**Solution:**
- Check `MEDIA_URL` and `MEDIA_ROOT` configured
- Verify photo saved correctly (check file system)
- Check base64 decoding successful
- Verify PIL dependencies installed

#### Issue: "SMS not sent after approval"

**Solution:**
- Check `send_sms_password()` implementation
- Verify OpenVox gateway accessible
- Check SMS gateway logs
- Test SMS gateway separately

---

## Appendix: API Response Examples

### Successful OTP Generation

```json
{
  "success": true,
  "ref_id": "ABC123XYZ789",
  "message": "OTP sent to your Aadhaar-linked mobile number",
  "if_number": "XXXXXXX3210"
}
```

### Successful OTP Verification

```json
{
  "success": true,
  "kyc_id": 42,
  "name": "Rajesh Kumar Singh",
  "message": "Aadhaar verification successful. Your application is under review. You will receive login credentials via SMS once approved."
}
```

### Error: Duplicate Aadhaar (409 Conflict)

```json
{
  "success": false,
  "error": "Agent already exists with this Aadhaar number"
}
```

### Error: Invalid OTP (400 Bad Request)

```json
{
  "success": false,
  "error": "OTP verification failed. Invalid or expired OTP."
}
```

---

**Document Version:** 1.0
**Last Updated:** November 24, 2025
**Status:** Ready for Implementation
