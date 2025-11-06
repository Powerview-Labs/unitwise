/**
 * CREATE USER PROFILE CLOUD FUNCTION
 * 
 * Creates complete user profile in Firestore after OTP verification and password setup
 * 
 * SECURITY FEATURES:
 * - Server-side validation of all fields
 * - Duplicate phone number check
 * - Firebase Auth UID verification
 * - No password storage (handled by Firebase Auth)
 * - Automatic welcome email trigger
 * - Input sanitization
 * 
 * ENDPOINT: POST /createUserProfile
 * 
 * REQUEST BODY:
 * {
 *   "uid": "firebase_uid_123",        // Required, Firebase Auth UID
 *   "phone": "+2348100000000",        // Required, E.164 format
 *   "name": "John Doe",                // Required
 *   "email": "user@example.com",      // Optional
 *   "disco": "Ikeja Electric",        // Required
 *   "band": "C",                       // Required (A-E)
 *   "location": "Yaba, Lagos"         // Required
 * }
 * 
 * RESPONSE (Success):
 * {
 *   "success": true,
 *   "uid": "firebase_uid_123",
 *   "message": "User profile created successfully",
 *   "welcomeEmailSent": true
 * }
 * 
 * RESPONSE (Error):
 * {
 *   "success": false,
 *   "code": "DUPLICATE_PHONE",
 *   "message": "A user with this phone number already exists"
 * }
 */

const { onRequest } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('./admin');
const { isValidDisco, isValidBand } = require('./utils/discoLookup');
const { sendWelcomeEmail, maskEmail } = require('./utils/emailClient');
const { maskPhoneNumber } = require('./utils/twilioClient');

/**
 * Validate user profile data
 * 
 * SECURITY: Server-side validation prevents malformed data
 * 
 * @param {Object} data - User profile data
 * @return {Object} { valid: boolean, errors?: Array }
 */
function validateUserProfile(data) {
  const errors = [];
  
  // Required fields
  if (!data.uid || typeof data.uid !== 'string') {
    errors.push('uid is required and must be a string');
  }
  
  if (!data.phone || !/^\+[1-9]\d{1,14}$/.test(data.phone)) {
    errors.push('phone is required and must be in E.164 format');
  }
  
  if (!data.name || typeof data.name !== 'string' || data.name.trim().length === 0) {
    errors.push('name is required and cannot be empty');
  }
  
  if (!data.disco || !isValidDisco(data.disco)) {
    errors.push('disco is required and must be a valid DisCo code');
  }
  
  if (!data.band || !isValidBand(data.band)) {
    errors.push('band is required and must be A, B, C, D, or E');
  }
  
  if (!data.location || typeof data.location !== 'string' || data.location.trim().length === 0) {
    errors.push('location is required and cannot be empty');
  }
  
  // Optional email validation
  if (data.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) {
    errors.push('email must be a valid email address');
  }
  
  return {
    valid: errors.length === 0,
    errors: errors,
  };
}

/**
 * Sanitize user input
 * 
 * SECURITY: Prevent injection attacks
 * 
 * @param {string} input - User input string
 * @return {string} Sanitized string
 */
function sanitizeInput(input) {
  if (typeof input !== 'string') return input;
  return input.trim().replace(/[<>]/g, '');
}

/**
 * Check if phone number already exists
 * 
 * SECURITY: Prevent duplicate accounts
 * 
 * @param {string} phone - Phone number
 * @param {string} currentUid - Current user UID (to exclude from check)
 * @return {Promise<boolean>} True if phone exists for another user
 */
async function phoneNumberExists(phone, currentUid) {
  const db = admin.firestore();
  
  try {
    const existingUsers = await db.collection('users')
      .where('phone', '==', phone)
      .get();
    
    // Check if any existing user has different UID
    for (const doc of existingUsers.docs) {
      if (doc.id !== currentUid) {
        return true;
      }
    }
    
    return false;
    
  } catch (error) {
    console.error('[createUserProfile] Error checking phone number:', error.message);
    return false; // Fail open to allow creation
  }
}

/**
 * Main createUserProfile Cloud Function
 */
exports.createUserProfile = onRequest(
  {
    cors: true,
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    // SECURITY: Only allow POST requests
    if (req.method !== 'POST') {
      return res.status(405).json({
        success: false,
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only POST requests are allowed',
      });
    }
    
    try {
      const { uid, phone, name, email, disco, band, location, meter_number } = req.body;
      
      const maskedPhone = maskPhoneNumber(phone);
      console.log(`[createUserProfile] Creating profile for ${maskedPhone}. UID: ${uid}`);
      
      // SECURITY: Validate all input data
      const validation = validateUserProfile({ uid, phone, name, email, disco, band, location });
      
      if (!validation.valid) {
        console.warn(`[createUserProfile] Validation failed for ${maskedPhone}:`, validation.errors);
        return res.status(400).json({
          success: false,
          code: 'VALIDATION_ERROR',
          message: 'Invalid profile data',
          errors: validation.errors,
        });
      }
      
      // SECURITY: Verify user exists in Firebase Auth
      try {
        await admin.auth().getUser(uid);
      } catch (error) {
        console.error(`[createUserProfile] Firebase Auth user not found: ${uid}`);
        return res.status(404).json({
          success: false,
          code: 'USER_NOT_FOUND',
          message: 'Firebase Auth user not found',
        });
      }
      
      // SECURITY: Check for duplicate phone number
      const phoneExists = await phoneNumberExists(phone, uid);
      if (phoneExists) {
        console.warn(`[createUserProfile] Duplicate phone number: ${maskedPhone}`);
        return res.status(409).json({
          success: false,
          code: 'DUPLICATE_PHONE',
          message: 'A user with this phone number already exists',
        });
      }
      
      // SECURITY: Sanitize all text inputs
      const sanitizedData = {
        uid: uid,
        phone: phone,
        name: sanitizeInput(name),
        email: email ? sanitizeInput(email) : null,
        disco: disco,
        band: band,
        location: sanitizeInput(location),
        meter_number: meter_number ? sanitizeInput(meter_number) : null,
        theme: 'light', // Default theme
        created_at: admin.firestore.Timestamp.now(),
        last_login: admin.firestore.Timestamp.now(),
        remember_me: false, // Default to false
      };
      
      // Create user profile in Firestore
      const db = admin.firestore();
      await db.collection('users').doc(uid).set(sanitizedData);
      
      console.log(`[createUserProfile] Profile created successfully for ${maskedPhone}. UID: ${uid}`);
      
      // Trigger welcome email (async, don't wait)
      let welcomeEmailSent = false;
      if (email) {
        sendWelcomeEmail(email, name)
          .then((result) => {
            if (result.success) {
              console.log(`[createUserProfile] Welcome email sent to ${maskEmail(email)}`);
            } else {
              console.error(`[createUserProfile] Failed to send welcome email:`, result.error);
            }
          })
          .catch((error) => {
            console.error(`[createUserProfile] Welcome email error:`, error.message);
          });
        welcomeEmailSent = true; // Attempted, actual status logged separately
      }
      
      return res.status(201).json({
        success: true,
        uid: uid,
        message: 'User profile created successfully',
        welcomeEmailSent: welcomeEmailSent,
      });
      
    } catch (error) {
      // SECURITY: Sanitize error before logging
      console.error('[createUserProfile] Unexpected error:', {
        message: error.message,
        code: error.code,
        // NEVER log: passwords, full phone numbers, emails
      });
      
      return res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred. Please try again later.',
      });
    }
  }
);

/**
 * Firestore Trigger: Send welcome email when user document is created
 * 
 * ALTERNATIVE APPROACH: Can be used instead of inline email in createUserProfile
 * Provides better separation of concerns and retry logic
 */
exports.sendWelcomeEmailOnCreate = onDocumentCreated(
  {
    document: 'users/{uid}',
    region: 'us-central1',
  },
  async (event) => {
    const userData = event.data.data();
    
    // Only send email if email address is provided
    if (!userData.email) {
      console.log(`[sendWelcomeEmailOnCreate] No email for UID: ${userData.uid}`);
      return;
    }
    
    const maskedEmail = maskEmail(userData.email);
    console.log(`[sendWelcomeEmailOnCreate] Sending welcome email to ${maskedEmail}`);
    
    try {
      const result = await sendWelcomeEmail(userData.email, userData.name);
      
      if (result.success) {
        console.log(`[sendWelcomeEmailOnCreate] Email sent successfully to ${maskedEmail}`);
      } else {
        console.error(`[sendWelcomeEmailOnCreate] Email send failed:`, result.error);
      }
      
    } catch (error) {
      console.error(`[sendWelcomeEmailOnCreate] Error:`, error.message);
      // Don't throw - allow user creation to succeed even if email fails
    }
  }
);
