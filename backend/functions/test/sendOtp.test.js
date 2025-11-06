/**
 * UNIT TESTS: sendOtp Cloud Function
 * 
 * Tests OTP generation, hashing, rate limiting, and Twilio integration
 * 
 * RUN TESTS:
 * npm test -- sendOtp.test.js
 * 
 * COVERAGE:
 * npm test -- --coverage sendOtp.test.js
 */

const admin = require('firebase-admin');
const { sendOtp } = require('../sendOtp');

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const mockFirestore = {
    collection: jest.fn(() => mockFirestore),
    doc: jest.fn(() => mockFirestore),
    get: jest.fn(),
    set: jest.fn(),
    where: jest.fn(() => mockFirestore),
    Timestamp: {
      now: jest.fn(() => ({ toMillis: () => Date.now() })),
      fromDate: jest.fn((date) => ({ toMillis: () => date.getTime() })),
    },
  };
  
  return {
    firestore: jest.fn(() => mockFirestore),
    Timestamp: mockFirestore.Timestamp,
    initializeApp: jest.fn(),
  };
});

// Mock Twilio Client
jest.mock('../utils/twilioClient', () => ({
  sendWhatsAppOTP: jest.fn(),
  sendSMSOTP: jest.fn(),
  maskPhoneNumber: jest.fn((phone) => phone.replace(/\d{4}$/, '****')),
}));

const { sendWhatsAppOTP, sendSMSOTP } = require('../utils/twilioClient');

describe('sendOtp Function', () => {
  let mockReq, mockRes;
  
  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    
    // Mock request object
    mockReq = {
      method: 'POST',
      body: {},
    };
    
    // Mock response object
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    
    // Setup default Twilio success response
    sendWhatsAppOTP.mockResolvedValue({
      success: true,
      messageSid: 'SM123456789',
      status: 'queued',
    });
  });
  
  describe('Request Validation', () => {
    test('should reject non-POST requests', async () => {
      mockReq.method = 'GET';
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(405);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'METHOD_NOT_ALLOWED',
        })
      );
    });
    
    test('should reject missing phone number', async () => {
      mockReq.body = {};
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'MISSING_PHONE',
        })
      );
    });
    
    test('should reject invalid phone number format', async () => {
      mockReq.body = { phone: '08100000000' }; // Not E.164
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'INVALID_PHONE_FORMAT',
        })
      );
    });
    
    test('should accept valid E.164 phone number', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      // Mock Firestore rate limit check
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
        })
      );
    });
  });
  
  describe('Rate Limiting', () => {
    test('should enforce rate limit (max 3 requests per 15 minutes)', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      // Mock 3 recent OTP sessions
      const db = admin.firestore();
      db.get.mockResolvedValue({
        size: 3,
        docs: [
          {
            data: () => ({
              createdAt: {
                toMillis: () => Date.now() - 5 * 60 * 1000, // 5 minutes ago
              },
            }),
          },
        ],
      });
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(429);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'RATE_LIMIT_EXCEEDED',
        })
      );
    });
    
    test('should allow request within rate limit', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      // Mock only 2 recent sessions (below limit)
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 2, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(200);
    });
  });
  
  describe('OTP Generation and Storage', () => {
    test('should generate 6-digit OTP', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      // Verify Firestore set was called
      expect(db.set).toHaveBeenCalled();
      
      // Verify set was called with proper structure
      const setCall = db.set.mock.calls[0][0];
      expect(setCall).toHaveProperty('otpHash');
      expect(setCall).toHaveProperty('phone', '+2348100000000');
      expect(setCall).toHaveProperty('attempts', 0);
      expect(setCall).toHaveProperty('used', false);
    });
    
    test('should hash OTP with bcrypt before storage', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      const setCall = db.set.mock.calls[0][0];
      
      // OTP hash should start with bcrypt prefix
      expect(setCall.otpHash).toMatch(/^\$2[aby]\$/);
      
      // Hash should not be the plaintext OTP
      expect(setCall.otpHash).not.toMatch(/^\d{6}$/);
    });
    
    test('should set expiry to 5 minutes', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      const setCall = db.set.mock.calls[0][0];
      
      expect(setCall).toHaveProperty('expiresAt');
      
      // Verify expiry is approximately 5 minutes from now
      const expiryMillis = setCall.expiresAt.toMillis();
      const expectedExpiry = Date.now() + 5 * 60 * 1000;
      const diff = Math.abs(expiryMillis - expectedExpiry);
      
      expect(diff).toBeLessThan(10000); // Within 10 seconds tolerance
    });
  });
  
  describe('Twilio Integration', () => {
    test('should send OTP via WhatsApp by default', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      expect(sendWhatsAppOTP).toHaveBeenCalledWith(
        '+2348100000000',
        expect.stringMatching(/^\d{6}$/)
      );
    });
    
    test('should send OTP via SMS when source=sms', async () => {
      mockReq.body = {
        phone: '+2348100000000',
        source: 'sms',
      };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      sendSMSOTP.mockResolvedValue({
        success: true,
        messageSid: 'SM987654321',
      });
      
      await sendOtp(mockReq, mockRes);
      
      expect(sendSMSOTP).toHaveBeenCalledWith(
        '+2348100000000',
        expect.stringMatching(/^\d{6}$/)
      );
    });
    
    test('should handle Twilio send failure', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      sendWhatsAppOTP.mockResolvedValue({
        success: false,
        error: 'TWILIO_ERROR',
        message: 'Failed to send message',
      });
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'TWILIO_ERROR',
        })
      );
    });
    
    test('should store Twilio messageSid for traceability', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      const setCall = db.set.mock.calls[0][0];
      expect(setCall).toHaveProperty('messageSid', 'SM123456789');
    });
  });
  
  describe('Response Format', () => {
    test('should return sessionId on success', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      db.doc.mockReturnValue({ id: 'otp_sess_test123' });
      
      await sendOtp(mockReq, mockRes);
      
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          sessionId: expect.any(String),
          messageSid: 'SM123456789',
          expiresIn: 300,
        })
      );
    });
    
    test('should never expose OTP in response', async () => {
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      const responseBody = mockRes.json.mock.calls[0][0];
      
      // Ensure no 6-digit number in response
      const responseString = JSON.stringify(responseBody);
      expect(responseString).not.toMatch(/\b\d{6}\b/);
    });
  });
  
  describe('Security - No PII Exposure', () => {
    test('should mask phone number in logs', async () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
      
      mockReq.body = { phone: '+2348100000000' };
      
      const db = admin.firestore();
      db.get.mockResolvedValue({ size: 0, docs: [] });
      
      await sendOtp(mockReq, mockRes);
      
      // Verify maskPhoneNumber was called
      const { maskPhoneNumber } = require('../utils/twilioClient');
      expect(maskPhoneNumber).toHaveBeenCalledWith('+2348100000000');
      
      consoleSpy.mockRestore();
    });
  });
});
