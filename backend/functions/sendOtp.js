const { onRequest } = require('firebase-functions/v2/https');
const admin = require('./admin');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { sendWhatsAppOTP, sendSMSOTP, maskPhoneNumber } = require('./utils/twilioClient');

function generateSecureOTP() {
  const otp = crypto.randomInt(100000, 1000000);
  return otp.toString();
}

async function checkRateLimit(phone) {
  const db = admin.firestore();
  const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
  
  try {
    const recentSessions = await db.collection('otp_sessions')
      .where('phone', '==', phone)
      .where('createdAt', '>', fifteenMinutesAgo)
      .get();
    
    const sessionCount = recentSessions.size;
    
    if (sessionCount >= 3) {
      const oldestSession = recentSessions.docs[0];
      const oldestTime = oldestSession.data().createdAt.toDate().getTime();
      const waitMillis = (oldestTime + 15 * 60 * 1000) - Date.now();
      const waitMinutes = Math.ceil(waitMillis / 60000);
      
      return {
        allowed: false,
        waitMinutes: waitMinutes,
      };
    }
    
    return { allowed: true };
    
  } catch (error) {
    console.error('[sendOtp] Rate limit check failed:', error.message);
    return { allowed: true };
  }
}

function isValidPhoneNumber(phone) {
  const e164Regex = /^\+[1-9]\d{1,14}$/;
  return e164Regex.test(phone);
}

exports.sendOtp = onRequest(
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
      const { phone, name, email, source } = req.body;
      
      if (!phone) {
        return res.status(400).json({
          success: false,
          code: 'MISSING_PHONE',
          message: 'Phone number is required',
        });
      }
      
      if (!isValidPhoneNumber(phone)) {
        return res.status(400).json({
          success: false,
          code: 'INVALID_PHONE_FORMAT',
          message: 'Phone number must be in E.164 format (e.g., +2348100000000)',
        });
      }
      
      const maskedPhone = maskPhoneNumber(phone);
      console.log(`[sendOtp] OTP request for ${maskedPhone}`);
      
      const rateLimitCheck = await checkRateLimit(phone);
      if (!rateLimitCheck.allowed) {
        console.warn(`[sendOtp] Rate limit exceeded for ${maskedPhone}`);
        return res.status(429).json({
          success: false,
          code: 'RATE_LIMIT_EXCEEDED',
          message: `Too many OTP requests. Please try again in ${rateLimitCheck.waitMinutes} minutes.`,
          retryAfter: rateLimitCheck.waitMinutes * 60,
        });
      }
      
      const otp = generateSecureOTP();
      console.log(`[sendOtp] Generated OTP for ${maskedPhone}`);
      console.log(`[sendOtp] TEST MODE - OTP: ${otp}`);
      
      const saltRounds = parseInt(process.env.BCRYPT_SALT_ROUNDS || '10');
      const otpHash = await bcrypt.hash(otp, saltRounds);
      
      const db = admin.firestore();
      const sessionRef = db.collection('otp_sessions').doc();
      const sessionId = sessionRef.id;
      
      const now = new Date();
      const expiresAt = new Date(now.getTime() + 5 * 60 * 1000);
      
      const sessionData = {
        phone: phone,
        otpHash: otpHash,
        createdAt: now,
        expiresAt: expiresAt,
        attempts: 0,
        source: source || 'whatsapp',
        used: false,
        name: name || null,
        email: email || null,
      };
      
      let twilioResult;
      if (source === 'sms') {
        twilioResult = await sendSMSOTP(phone, otp);
      } else {
        twilioResult = await sendWhatsAppOTP(phone, otp);
      }
      
      if (!twilioResult.success) {
        console.error(`[sendOtp] Twilio send failed for ${maskedPhone}:`, twilioResult.error);
        return res.status(500).json({
          success: false,
          code: twilioResult.error,
          message: twilioResult.message || 'Failed to send OTP. Please try again.',
        });
      }
      
      sessionData.messageSid = twilioResult.messageSid;
      await sessionRef.set(sessionData);
      
      console.log(`[sendOtp] OTP session created for ${maskedPhone}. SessionID: ${sessionId}`);
      
      return res.status(200).json({
        success: true,
        sessionId: sessionId,
        messageSid: twilioResult.messageSid,
        message: `OTP sent via ${source || 'WhatsApp'}`,
        expiresIn: 300,
        testOtp: otp,
      });
      
    } catch (error) {
      console.error('[sendOtp] Unexpected error:', {
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
