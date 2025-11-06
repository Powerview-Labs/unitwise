const { onRequest } = require('firebase-functions/v2/https');
const admin = require('./admin');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { sendWhatsAppOTP, sendSMSOTP, maskPhoneNumber } = require('./utils/twilioClient');

function generateSecureOTP() {
  const otp = crypto.randomInt(100000, 1000000);
  return otp.toString();
}

function validatePassword(password) {
  const minLength = parseInt(process.env.PASSWORD_MIN_LENGTH || '6');
  
  if (!password || password.length < minLength) {
    return {
      valid: false,
      message: `Password must be at least ${minLength} characters long`,
    };
  }
  
  return { valid: true };
}

async function checkResetRateLimit(phone) {
  const db = admin.firestore();
  const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
  
  try {
    const recentResets = await db.collection('password_reset_sessions')
      .where('phone', '==', phone)
      .where('createdAt', '>', fifteenMinutesAgo)
      .get();
    
    if (recentResets.size >= 3) {
      const oldestReset = recentResets.docs[0];
      const oldestTime = oldestReset.data().createdAt.toDate().getTime();
      const waitMillis = (oldestTime + 15 * 60 * 1000) - Date.now();
      const waitMinutes = Math.ceil(waitMillis / 60000);
      
      return {
        allowed: false,
        waitMinutes: waitMinutes,
      };
    }
    
    return { allowed: true };
    
  } catch (error) {
    console.error('[resetPassword] Rate limit check failed:', error.message);
    return { allowed: true };
  }
}

async function handleRequestOTP(req, res) {
  const { phone } = req.body;
  
  if (!phone || !/^\+[1-9]\d{1,14}$/.test(phone)) {
    return res.status(400).json({
      success: false,
      code: 'INVALID_PHONE_FORMAT',
      message: 'Phone number is required and must be in E.164 format',
    });
  }
  
  const maskedPhone = maskPhoneNumber(phone);
  console.log(`[resetPassword] OTP request for password reset: ${maskedPhone}`);
  
  const rateLimitCheck = await checkResetRateLimit(phone);
  if (!rateLimitCheck.allowed) {
    console.warn(`[resetPassword] Rate limit exceeded for ${maskedPhone}`);
    return res.status(429).json({
      success: false,
      code: 'RATE_LIMIT_EXCEEDED',
      message: `Too many password reset requests. Try again in ${rateLimitCheck.waitMinutes} minutes.`,
      retryAfter: rateLimitCheck.waitMinutes * 60,
    });
  }
  
  try {
    await admin.auth().getUserByPhoneNumber(phone);
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.warn(`[resetPassword] User not found: ${maskedPhone}`);
      return res.status(200).json({
        success: true,
        message: 'If an account with this phone number exists, an OTP has been sent.',
      });
    }
    throw error;
  }
  
  const otp = generateSecureOTP();
  const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS || '10');
  const otpHash = await bcrypt.hash(otp, saltRounds);
  
  const db = admin.firestore();
  const sessionRef = db.collection('password_reset_sessions').doc();
  const sessionId = sessionRef.id;
  
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 5 * 60 * 1000);
  
  const sessionData = {
    phone: phone,
    otpHash: otpHash,
    createdAt: now,
    expiresAt: expiresAt,
    attempts: 0,
    used: false,
  };
  
  const twilioResult = await sendWhatsAppOTP(phone, otp);
  
  if (!twilioResult.success) {
    console.error(`[resetPassword] Failed to send OTP to ${maskedPhone}`);
    return res.status(500).json({
      success: false,
      code: twilioResult.error,
      message: twilioResult.message || 'Failed to send OTP',
    });
  }
  
  sessionData.messageSid = twilioResult.messageSid;
  await sessionRef.set(sessionData);
  
  console.log(`[resetPassword] OTP sent for password reset: ${maskedPhone}`);
  console.log(`[resetPassword] TEST MODE - OTP: ${otp}`);
  
  return res.status(200).json({
    success: true,
    sessionId: sessionId,
    messageSid: twilioResult.messageSid,
    message: 'OTP sent to your phone',
    expiresIn: 300,
    testOtp: otp,
  });
}

async function handleResetPassword(req, res) {
  const { sessionId, otp, phone, newPassword } = req.body;
  
  if (!sessionId || !otp || !phone || !newPassword) {
    return res.status(400).json({
      success: false,
      code: 'MISSING_REQUIRED_FIELDS',
      message: 'sessionId, otp, phone, and newPassword are required',
    });
  }
  
  const maskedPhone = maskPhoneNumber(phone);
  
  const passwordValidation = validatePassword(newPassword);
  if (!passwordValidation.valid) {
    return res.status(400).json({
      success: false,
      code: 'WEAK_PASSWORD',
      message: passwordValidation.message,
    });
  }
  
  console.log(`[resetPassword] Verifying OTP for password reset: ${maskedPhone}`);
  
  const db = admin.firestore();
  const sessionRef = db.collection('password_reset_sessions').doc(sessionId);
  const sessionDoc = await sessionRef.get();
  
  if (!sessionDoc.exists) {
    console.warn(`[resetPassword] Session not found: ${sessionId}`);
    return res.status(404).json({
      success: false,
      code: 'SESSION_NOT_FOUND',
      message: 'Invalid or expired session',
    });
  }
  
  const sessionData = sessionDoc.data();
  
  if (sessionData.phone !== phone) {
    console.warn(`[resetPassword] Phone mismatch for session ${sessionId}`);
    return res.status(403).json({
      success: false,
      code: 'PHONE_MISMATCH',
      message: 'Phone number does not match the session',
    });
  }
  
  if (sessionData.used) {
    return res.status(403).json({
      success: false,
      code: 'OTP_ALREADY_USED',
      message: 'This OTP has already been used',
    });
  }
  
  const now = new Date();
  const expiresAt = sessionData.expiresAt.toDate();
  if (now > expiresAt) {
    await sessionRef.delete();
    return res.status(403).json({
      success: false,
      code: 'EXPIRED_OTP',
      message: 'OTP has expired',
    });
  }
  
  if (sessionData.attempts >= 5) {
    await sessionRef.delete();
    return res.status(403).json({
      success: false,
      code: 'MAX_ATTEMPTS_EXCEEDED',
      message: 'Too many failed attempts',
    });
  }
  
  const isValidOTP = await bcrypt.compare(otp, sessionData.otpHash);
  
  if (!isValidOTP) {
    const newAttempts = sessionData.attempts + 1;
    await sessionRef.update({ attempts: newAttempts });
    
    return res.status(403).json({
      success: false,
      code: 'INVALID_OTP',
      message: `Incorrect OTP. ${5 - newAttempts} attempts remaining`,
      attemptsRemaining: 5 - newAttempts,
    });
  }
  
  try {
    const userRecord = await admin.auth().getUserByPhoneNumber(phone);
    
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });
    
    await sessionRef.update({ used: true });
    setTimeout(async () => {
      try {
        await sessionRef.delete();
      } catch (error) {
        console.error('[resetPassword] Failed to delete session:', error.message);
      }
    }, 5000);
    
    console.log(`[resetPassword] Password reset successfully for ${maskedPhone}`);
    
    return res.status(200).json({
      success: true,
      message: 'Password reset successfully',
    });
    
  } catch (error) {
    console.error(`[resetPassword] Error updating password:`, error.message);
    
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({
        success: false,
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }
    
    throw error;
  }
}

exports.resetPassword = onRequest(
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
      const { action } = req.body;
      
      if (action === 'request_otp') {
        return await handleRequestOTP(req, res);
      } else if (action === 'reset_password') {
        return await handleResetPassword(req, res);
      } else {
        return res.status(400).json({
          success: false,
          code: 'INVALID_ACTION',
          message: 'action must be "request_otp" or "reset_password"',
        });
      }
      
    } catch (error) {
      console.error('[resetPassword] Unexpected error:', {
        message: error.message,
        code: error.code,
      });
      
      return res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      });
    }
  }
);
