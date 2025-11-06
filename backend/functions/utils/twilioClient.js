/**
 * TWILIO CLIENT - SMS MODE (Production Ready)
 * 
 * This version uses SMS for OTP delivery.
 * WhatsApp support can be added later without changing the interface.
 */

const twilio = require('twilio');

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

// Initialize Twilio client
let client = null;
if (accountSid && authToken) {
  client = twilio(accountSid, authToken);
  console.log('[Twilio] SMS client initialized successfully');
  console.log('[Twilio] From number:', fromPhoneNumber ? 'Configured' : 'MISSING');
} else {
  console.log('[Twilio] Running in TEST MODE - no credentials provided');
  console.log('[Twilio] Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN in .env');
}

/**
 * Mask phone number for secure logging
 */
function maskPhoneNumber(phone) {
  if (!phone || phone.length < 8) {
    return '***INVALID***';
  }
  const countryCode = phone.slice(0, 4);
  const lastDigits = phone.slice(-3);
  const maskedMiddle = '*'.repeat(phone.length - 7);
  return `${countryCode}${maskedMiddle}${lastDigits}`;
}

/**
 * Send OTP via WhatsApp
 * Currently redirects to SMS - will be implemented when WhatsApp is set up
 */
async function sendWhatsAppOTP(toPhoneNumber, otp) {
  console.log('[Twilio] WhatsApp not yet configured, using SMS');
  return await sendSMSOTP(toPhoneNumber, otp);
}

/**
 * Send OTP via SMS
 */
async function sendSMSOTP(toPhoneNumber, otp) {
  const maskedPhone = maskPhoneNumber(toPhoneNumber);
  
  // TEST MODE - no actual SMS sent
  if (!client || !fromPhoneNumber) {
    console.log(`[Twilio] TEST MODE - Would send SMS to ${maskedPhone}`);
    console.log(`[Twilio] TEST MODE - OTP: ${otp}`);
    console.log(`[Twilio] TEST MODE - Configure credentials in .env to send real SMS`);
    
    return {
      success: true,
      messageSid: `SM_TEST_${Date.now()}`,
      status: 'queued',
      channel: 'sms-test',
    };
  }
  
  // PRODUCTION MODE - send real SMS
  try {
    console.log(`[Twilio] Sending SMS OTP to ${maskedPhone}`);
    
    const message = await client.messages.create({
      to: toPhoneNumber,
      from: fromPhoneNumber,
      body: `${otp} is your UnitWise verification code. Valid for 5 minutes. Do not share this code with anyone.`,
    });
    
    console.log(`[Twilio] ✓ SMS sent successfully to ${maskedPhone}`);
    console.log(`[Twilio] Message SID: ${message.sid}`);
    console.log(`[Twilio] Status: ${message.status}`);
    
    return {
      success: true,
      messageSid: message.sid,
      status: message.status,
      channel: 'sms',
    };
    
  } catch (error) {
    console.error(`[Twilio] ✗ Failed to send SMS to ${maskedPhone}`);
    console.error(`[Twilio] Error code: ${error.code}`);
    console.error(`[Twilio] Error message: ${error.message}`);
    
    // User-friendly error messages
    const errorMessages = {
      21211: 'Invalid phone number format. Please check and try again.',
      21408: 'Permission denied for this phone number.',
      21610: 'Message blocked by carrier. Number may be on do-not-contact list.',
      21614: 'This is not a valid mobile number.',
      21608: 'This phone number is not SMS-capable.',
      30007: 'Message filtered as spam. Contact support.',
    };
    
    return {
      success: false,
      error: error.code || 'TWILIO_ERROR',
      message: errorMessages[error.code] || 'Failed to send verification code. Please try again.',
      channel: 'sms',
    };
  }
}

/**
 * Validate Twilio webhook signature (for future webhook support)
 */
function validateWebhookSignature(signature, url, params) {
  if (!client) {
    console.log('[Twilio] Webhook validation skipped - TEST MODE');
    return true;
  }
  
  try {
    return twilio.validateRequest(authToken, signature, url, params);
  } catch (error) {
    console.error('[Twilio] Webhook validation failed:', error.message);
    return false;
  }
}

module.exports = {
  sendWhatsAppOTP,
  sendSMSOTP,
  maskPhoneNumber,
  validateWebhookSignature,
};
