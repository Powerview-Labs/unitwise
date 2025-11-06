const { onRequest } = require('firebase-functions/v2/https');
const admin = require('./admin');
const bcrypt = require('bcrypt');
const { maskPhoneNumber } = require('./utils/twilioClient');

/**
 * Validate OTP format (6 digits)
 */
function isValidOTP(otp) {
  return /^\d{6}$/.test(otp);
}

/**
 * Check if user exists in Firebase Auth by phone number
 */
async function checkUserExists(phone) {
  try {
    const userRecord = await admin.auth().getUserByPhoneNumber(phone);
    return {
      exists: true,
      uid: userRecord.uid,
    };
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return { exists: false };
    }
    throw error;
  }
}

/**
 * Main verifyOtp Cloud Function
 */
exports.verifyOtp = onRequest(
  {
    cors: true,
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      return res.status(405).json({
        success: false,
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only POST requests are allowed',
      });
    }

    try {
      const { sessionId, otp, phone } = req.body;

      // Validate required fields
      if (!sessionId || !otp || !phone) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_REQUIRED_FIELDS',
          message: 'sessionId, otp, and phone are required',
        });
      }

      // Validate OTP format
      if (!isValidOTP(otp)) {
        return res.status(400).json({
          success: false,
          code: 'INVALID_OTP_FORMAT',
          message: 'OTP must be 6 digits',
        });
      }

      const maskedPhone = maskPhoneNumber(phone);
      console.log(`[verifyOtp] Verification attempt for ${maskedPhone}. SessionID: ${sessionId}`);

      // Retrieve OTP session from Firestore
      const db = admin.firestore();
      const sessionRef = db.collection('otp_sessions').doc(sessionId);
      const sessionDoc = await sessionRef.get();

      // Check if session exists
      if (!sessionDoc.exists) {
        console.warn(`[verifyOtp] Session not found for ${maskedPhone}. SessionID: ${sessionId}`);
        return res.status(404).json({
          success: false,
          code: 'SESSION_NOT_FOUND',
          message: 'Invalid or expired session. Please request a new OTP.',
        });
      }

      const sessionData = sessionDoc.data();

      // Verify phone number matches session
      if (sessionData.phone !== phone) {
        console.warn(`[verifyOtp] Phone mismatch for SessionID: ${sessionId}`);
        return res.status(403).json({
          success: false,
          code: 'PHONE_MISMATCH',
          message: 'Phone number does not match the session.',
        });
      }

      // Check if OTP already used
      if (sessionData.used) {
        console.warn(`[verifyOtp] Attempted reuse of OTP for ${maskedPhone}`);
        return res.status(403).json({
          success: false,
          code: 'OTP_ALREADY_USED',
          message: 'This OTP has already been used. Please request a new one.',
        });
      }

      // Check if OTP expired
      const now = new Date();
      const expiresAt = sessionData.expiresAt.toDate();
      if (now > expiresAt) {
        console.warn(`[verifyOtp] Expired OTP for ${maskedPhone}`);
        await sessionRef.delete();
        return res.status(403).json({
          success: false,
          code: 'EXPIRED_OTP',
          message: 'OTP has expired. Please request a new one.',
        });
      }

      // Check attempt limit
      if (sessionData.attempts >= 5) {
        console.warn(`[verifyOtp] Max attempts exceeded for ${maskedPhone}`);
        await sessionRef.delete();
        return res.status(403).json({
          success: false,
          code: 'MAX_ATTEMPTS_EXCEEDED',
          message: 'Too many failed attempts. Please request a new OTP.',
        });
      }

      // Verify OTP using bcrypt (timing-safe comparison)
      const isValidOTPValue = await bcrypt.compare(otp, sessionData.otpHash);

      if (!isValidOTPValue) {
        // Increment attempt counter
        const newAttempts = sessionData.attempts + 1;
        await sessionRef.update({ attempts: newAttempts });

        const attemptsRemaining = 5 - newAttempts;
        console.warn(`[verifyOtp] Invalid OTP for ${maskedPhone}. Attempts: ${newAttempts}/5`);

        return res.status(403).json({
          success: false,
          code: 'INVALID_OTP',
          message: `Incorrect OTP. ${attemptsRemaining} attempt${attemptsRemaining !== 1 ? 's' : ''} remaining.`,
          attemptsRemaining: attemptsRemaining,
        });
      }

      // OTP is valid - proceed with authentication
      console.log(`[verifyOtp] Valid OTP for ${maskedPhone}`);

      // Mark session as used
      await sessionRef.update({ used: true });

      // Delete session after a delay
      setTimeout(async () => {
        try {
          await sessionRef.delete();
        } catch (error) {
          console.error('[verifyOtp] Failed to delete session:', error.message);
        }
      }, 5000);

      // Check if user exists in Firebase Auth
      const userCheck = await checkUserExists(phone);

      if (userCheck.exists) {
        // Existing user - generate custom token for sign-in
        const customToken = await admin.auth().createCustomToken(userCheck.uid);

        console.log(`[verifyOtp] Existing user authenticated: ${maskedPhone}`);

        return res.status(200).json({
          success: true,
          newUser: false,
          uid: userCheck.uid,
          customToken: customToken,
          phone: phone,
          message: 'OTP verified. User authenticated.',
        });

      } else {
        // New user - create Firebase Auth user
        const newUser = await admin.auth().createUser({
          phoneNumber: phone,
          emailVerified: false,
        });

        // Generate custom token for new user
        const customToken = await admin.auth().createCustomToken(newUser.uid);

        console.log(`[verifyOtp] New user created: ${maskedPhone}. UID: ${newUser.uid}`);

        return res.status(200).json({
          success: true,
          newUser: true,
          uid: newUser.uid,
          customToken: customToken,
          phone: phone,
          name: sessionData.name || null,
          email: sessionData.email || null,
          message: 'OTP verified. Please create a password.',
        });
      }

    } catch (error) {
      console.error('[verifyOtp] Unexpected error:', {
        message: error.message,
        code: error.code,
      });

      return res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred. Please try again later.',
      });
    }
  }
);
