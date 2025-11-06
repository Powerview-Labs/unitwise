/**
 * TWILIO CLIENT UTILITY
 * 
 * Handles WhatsApp OTP delivery via Twilio Content API
 * 
 * SECURITY FEATURES:
 * - Credentials loaded from environment variables only
 * - Masked logging (phone numbers redacted in logs)
 * - HTTPS-only communication with Twilio API
 * - Error sanitization (no sensitive data in error messages)
 * - Rate limiting at application layer (enforced in sendOtp function)
 * 
 * USAGE:
 * const { sendWhatsAppOTP } = require('./utils/twilioClient');
 * await sendWhatsAppOTP('+2348100000000', '123456');
 */

const twilio = require('twilio');

/**
 * Initialize Twilio client with credentials from environment
 * SECURITY: Credentials never hardcoded, always from process.env
 */
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const whatsappNumber = process.env.TWILIO_WHATSAPP_NUMBER;
const contentSid = process.env.TWILIO_CONTENT_SID;

// Validate required environment variables on module load
if (!accountSid || !authToken || !whatsappNumber || !contentSid) {
  console.error('[Twilio] CRITICAL: Missing required Twilio environment variables');
  throw new Error('Twilio configuration incomplete. Check environment variables.');
}

// Initialize Twilio client
const client = twilio(accountSid, authToken);

/**
 * Mask phone number for secure logging
 * Example: +2348100000000 → +234810****000
 * 
 * SECURITY: Prevents PII exposure in logs
 * 
 * @param {string} phone - Phone number in E.164 format
 * @return {string} Masked phone number
 */
function maskPhoneNumber(phone) {
  if (!phone || phone.length < 8) {
    return '***INVALID***';
  }
  
  const countryCode = phone.slice(0, 4); // +234
  const lastDigits = phone.slice(-3); // 000
  const maskedMiddle = '*'.repeat(phone.length - 7); // ****
  
  return `${countryCode}${maskedMiddle}${lastDigits}`;
}

/**
 * Send WhatsApp OTP using Twilio Content API
 * 
 * SECURITY NOTES:
 * - OTP passed as parameter but NEVER logged
 * - Phone numbers masked in all logs
 * - Uses Twilio Content Template for consistent messaging
 * - Returns messageSid for traceability without exposing OTP
 * 
 * @param {string} toPhoneNumber - Recipient phone number (E.164 format)
 * @param {string} otp - 6-digit OTP code (NEVER logged)
 * @return {Promise<Object>} { success: boolean, messageSid: string, error?: string }
 */
async function sendWhatsAppOTP(toPhoneNumber, otp) {
  const maskedPhone = maskPhoneNumber(toPhoneNumber);
  
  try {
    // SECURITY: Log request without exposing OTP
    console.log(`[Twilio] Sending WhatsApp OTP to ${maskedPhone}`);
    
    // Validate OTP format (6 digits)
    if (!/^\d{6}$/.test(otp)) {
      console.error(`[Twilio] Invalid OTP format for ${maskedPhone}`);
      return {
        success: false,
        error: 'INVALID_OTP_FORMAT',
        message: 'OTP must be 6 digits',
      };
    }
    
    // Validate phone number format (E.164)
    if (!/^\+[1-9]\d{1,14}$/.test(toPhoneNumber)) {
      console.error(`[Twilio] Invalid phone format: ${maskedPhone}`);
      return {
        success: false,
        error: 'INVALID_PHONE_FORMAT',
        message: 'Phone number must be in E.164 format',
      };
    }
    
    // Send WhatsApp message using Content Template
    // SECURITY: OTP passed in ContentVariables, not logged
    const message = await client.messages.create({
      from: whatsappNumber,
      to: `whatsapp:${toPhoneNumber}`,
      contentSid: contentSid,
      contentVariables: JSON.stringify({
        '1': otp, // Template variable for OTP
      }),
    });
    
    // SECURITY: Log success without exposing OTP
    console.log(`[Twilio] OTP sent successfully to ${maskedPhone}. MessageSID: ${message.sid}`);
    
    return {
      success: true,
      messageSid: message.sid,
      status: message.status,
    };
    
  } catch (error) {
    // SECURITY: Sanitize error before logging
    // Never expose auth tokens, account details, or OTP in error messages
    console.error(`[Twilio] Failed to send OTP to ${maskedPhone}:`, {
      code: error.code,
      status: error.status,
      message: error.message,
      // NEVER log: authToken, OTP, full phone number
    });
    
    // Return user-friendly error message
    return {
      success: false,
      error: error.code || 'TWILIO_ERROR',
      message: getTwilioErrorMessage(error),
    };
  }
}

/**
 * Send SMS OTP (fallback for WhatsApp)
 * 
 * SECURITY: Same security measures as WhatsApp OTP
 * 
 * @param {string} toPhoneNumber - Recipient phone number (E.164 format)
 * @param {string} otp - 6-digit OTP code (NEVER logged)
 * @return {Promise<Object>} { success: boolean, messageSid: string, error?: string }
 */
async function sendSMSOTP(toPhoneNumber, otp) {
  const maskedPhone = maskPhoneNumber(toPhoneNumber);
  
  try {
    console.log(`[Twilio] Sending SMS OTP to ${maskedPhone}`);
    
    // Validate inputs
    if (!/^\d{6}$/.test(otp)) {
      return {
        success: false,
        error: 'INVALID_OTP_FORMAT',
        message: 'OTP must be 6 digits',
      };
    }
    
    if (!/^\+[1-9]\d{1,14}$/.test(toPhoneNumber)) {
      return {
        success: false,
        error: 'INVALID_PHONE_FORMAT',
        message: 'Phone number must be in E.164 format',
      };
    }
    
    // Send SMS with custom message
    // SECURITY: OTP in message body but NEVER logged
    const message = await client.messages.create({
      from: process.env.TWILIO_MESSAGING_SERVICE_SID || whatsappNumber.replace('whatsapp:', ''),
      to: toPhoneNumber,
      body: `${otp} is your UnitWise verification code. It will expire in 5 minutes. Do not share this code.`,
    });
    
    console.log(`[Twilio] SMS sent successfully to ${maskedPhone}. MessageSID: ${message.sid}`);
    
    return {
      success: true,
      messageSid: message.sid,
      status: message.status,
    };
    
  } catch (error) {
    console.error(`[Twilio] Failed to send SMS to ${maskedPhone}:`, {
      code: error.code,
      status: error.status,
      message: error.message,
    });
    
    return {
      success: false,
      error: error.code || 'TWILIO_ERROR',
      message: getTwilioErrorMessage(error),
    };
  }
}

/**
 * Convert Twilio error codes to user-friendly messages
 * 
 * SECURITY: Sanitizes technical error details
 * 
 * @param {Error} error - Twilio error object
 * @return {string} User-friendly error message
 */
function getTwilioErrorMessage(error) {
  const errorMap = {
    21211: 'Invalid phone number. Please check and try again.',
    21408: 'Phone number not eligible for WhatsApp. Try SMS instead.',
    21610: 'Message blocked by carrier. Contact support.',
    21614: 'Invalid WhatsApp recipient. Ensure number is registered on WhatsApp.',
    30007: 'Message filtering blocked delivery. Contact support.',
    30008: 'Unknown error occurred. Please try again later.',
    21606: 'Phone number is not a mobile number.',
  };
  
  return errorMap[error.code] || 'Unable to send verification code. Please try again later.';
}

/**
 * Verify Twilio webhook signature (for future webhook implementation)
 * 
 * SECURITY: Ensures webhook requests are authentic
 * 
 * @param {string} signature - X-Twilio-Signature header
 * @param {string} url - Full webhook URL
 * @param {Object} params - Request body parameters
 * @return {boolean} True if signature is valid
 */
function validateWebhookSignature(signature, url, params) {
  try {
    return twilio.validateRequest(
      authToken,
      signature,
      url,
      params
    );
  } catch (error) {
    console.error('[Twilio] Webhook signature validation failed:', error.message);
    return false;
  }
}

module.exports = {
  sendWhatsAppOTP,
  sendSMSOTP,
  maskPhoneNumber,
  validateWebhookSignature,
};
