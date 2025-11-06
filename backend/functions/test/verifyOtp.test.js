/**
 * UNIT TESTS: verifyOtp Cloud Function
 * 
 * Tests OTP verification, attempt limiting, expiry, and Firebase Auth integration
 * 
 * RUN TESTS:
 * npm test -- verifyOtp.test.js
 */

const admin = require('firebase-admin');
const bcrypt = require('bcrypt');
const { verifyOtp } = require('../verifyOtp');

// Mock Firebase Admin
jest.mock('firebase-admin', () => {
  const mockAuth = {
    getUserByPhoneNumber: jest.fn(),
    createUser: jest.fn(),
    createCustomToken: jest.fn(),
  };
  
  const mockFirestore = {
    collection: jest.fn(() => mockFirestore),
    doc: jest.fn(() => mockFirestore),
    get: jest.fn(),
    set: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
    Timestamp: {
      now: jest.fn(() => ({ toMillis: () => Date.now() })),
    },
  };
  
  return {
    auth: jest.fn(() => mockAuth),
    firestore: jest.fn(() => mockFirestore),
    Timestamp: mockFirestore.Timestamp,
    initializeApp: jest.fn(),
  };
});

// Mock utilities
jest.mock('../utils/twilioClient', () => ({
  maskPhoneNumber: jest.fn((phone) => phone.replace(/\d{4}$/, '****')),
}));

describe('verifyOtp Function', () => {
  let mockReq, mockRes, mockAuth, mockDb;
  const testOTP = '123456';
  let testOTPHash;
  
  beforeAll(async () => {
    // Generate test OTP hash
    testOTPHash = await bcrypt.hash(testOTP, 10);
  });
  
  beforeEach(() => {
    jest.clearAllMocks();
    
    mockReq = {
      method: 'POST',
      body: {},
    };
    
    mockRes = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    
    mockAuth = admin.auth();
    mockDb = admin.firestore();
  });
  
  describe('Request Validation', () => {
    test('should reject non-POST requests', async () => {
      mockReq.method = 'GET';
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(405);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'METHOD_NOT_ALLOWED',
        })
      );
    });
    
    test('should reject missing required fields', async () => {
      mockReq.body = { sessionId: 'test123' }; // Missing otp and phone
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'MISSING_REQUIRED_FIELDS',
        })
      );
    });
    
    test('should reject invalid OTP format', async () => {
      mockReq.body = {
        sessionId: 'test123',
        otp: '12345', // Only 5 digits
        phone: '+2348100000000',
      };
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(400);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'INVALID_OTP_FORMAT',
        })
      );
    });
  });
  
  describe('Session Validation', () => {
    test('should reject non-existent session', async () => {
      mockReq.body = {
        sessionId: 'invalid_session',
        otp: '123456',
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({ exists: false });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(404);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'SESSION_NOT_FOUND',
        })
      );
    });
    
    test('should reject phone number mismatch', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: '123456',
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348111111111', // Different phone
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'PHONE_MISMATCH',
        })
      );
    });
    
    test('should reject already used OTP', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: '123456',
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: true, // Already used
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'OTP_ALREADY_USED',
        })
      );
    });
    
    test('should reject expired OTP', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: '123456',
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() - 1000 }, // Expired
        }),
      });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'EXPIRED_OTP',
        })
      );
      
      // Should delete expired session
      expect(mockDb.delete).toHaveBeenCalled();
    });
  });
  
  describe('Attempt Limiting', () => {
    test('should reject when max attempts exceeded', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: '123456',
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 5, // Max attempts
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'MAX_ATTEMPTS_EXCEEDED',
        })
      );
      
      // Should delete session after max attempts
      expect(mockDb.delete).toHaveBeenCalled();
    });
    
    test('should increment attempts on invalid OTP', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: '999999', // Wrong OTP
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 2,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(403);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          code: 'INVALID_OTP',
          attemptsRemaining: 2, // 5 - 3 = 2
        })
      );
      
      // Should update attempts counter
      expect(mockDb.update).toHaveBeenCalledWith({ attempts: 3 });
    });
  });
  
  describe('OTP Verification (Timing-Safe)', () => {
    test('should verify correct OTP with bcrypt.compare', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP, // Correct OTP
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      // Mock new user
      mockAuth.getUserByPhoneNumber.mockRejectedValue({ code: 'auth/user-not-found' });
      mockAuth.createUser.mockResolvedValue({ uid: 'new_user_123' });
      mockAuth.createCustomToken.mockResolvedValue('custom_token_abc');
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockRes.status).toHaveBeenCalledWith(200);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          newUser: true,
          uid: 'new_user_123',
          customToken: 'custom_token_abc',
        })
      );
    });
    
    test('should use timing-safe comparison (bcrypt)', async () => {
      // This test verifies that bcrypt.compare is used
      // Bcrypt automatically uses timing-safe comparison
      
      const bcryptSpy = jest.spyOn(bcrypt, 'compare');
      
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      mockAuth.getUserByPhoneNumber.mockRejectedValue({ code: 'auth/user-not-found' });
      mockAuth.createUser.mockResolvedValue({ uid: 'new_user_123' });
      mockAuth.createCustomToken.mockResolvedValue('custom_token_abc');
      
      await verifyOtp(mockReq, mockRes);
      
      // Verify bcrypt.compare was called (timing-safe)
      expect(bcryptSpy).toHaveBeenCalledWith(testOTP, testOTPHash);
      
      bcryptSpy.mockRestore();
    });
  });
  
  describe('User Authentication', () => {
    test('should create new user when not exists', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
          name: 'John Doe',
          email: 'john@example.com',
        }),
      });
      
      // Mock new user
      mockAuth.getUserByPhoneNumber.mockRejectedValue({ code: 'auth/user-not-found' });
      mockAuth.createUser.mockResolvedValue({ uid: 'new_user_123' });
      mockAuth.createCustomToken.mockResolvedValue('custom_token_abc');
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockAuth.createUser).toHaveBeenCalledWith({
        phoneNumber: '+2348100000000',
        emailVerified: false,
      });
      
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          newUser: true,
          uid: 'new_user_123',
          name: 'John Doe',
          email: 'john@example.com',
        })
      );
    });
    
    test('should authenticate existing user', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      // Mock existing user
      mockAuth.getUserByPhoneNumber.mockResolvedValue({ uid: 'existing_user_456' });
      mockAuth.createCustomToken.mockResolvedValue('custom_token_xyz');
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockAuth.createUser).not.toHaveBeenCalled();
      
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          newUser: false,
          uid: 'existing_user_456',
          customToken: 'custom_token_xyz',
        })
      );
    });
    
    test('should generate custom token for authentication', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      mockAuth.getUserByPhoneNumber.mockResolvedValue({ uid: 'user_789' });
      mockAuth.createCustomToken.mockResolvedValue('firebase_token_123');
      
      await verifyOtp(mockReq, mockRes);
      
      expect(mockAuth.createCustomToken).toHaveBeenCalledWith('user_789');
      
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          customToken: 'firebase_token_123',
        })
      );
    });
  });
  
  describe('Session Cleanup', () => {
    test('should mark session as used after successful verification', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      mockAuth.getUserByPhoneNumber.mockResolvedValue({ uid: 'user_123' });
      mockAuth.createCustomToken.mockResolvedValue('token_123');
      
      await verifyOtp(mockReq, mockRes);
      
      // Should update session to mark as used
      expect(mockDb.update).toHaveBeenCalledWith({ used: true });
    });
  });
  
  describe('Security - No OTP Exposure', () => {
    test('should never expose OTP in response', async () => {
      mockReq.body = {
        sessionId: 'test_session',
        otp: testOTP,
        phone: '+2348100000000',
      };
      
      mockDb.get.mockResolvedValue({
        exists: true,
        data: () => ({
          phone: '+2348100000000',
          otpHash: testOTPHash,
          attempts: 0,
          used: false,
          expiresAt: { toMillis: () => Date.now() + 5 * 60 * 1000 },
        }),
      });
      
      mockAuth.getUserByPhoneNumber.mockResolvedValue({ uid: 'user_123' });
      mockAuth.createCustomToken.mockResolvedValue('token_123');
      
      await verifyOtp(mockReq, mockRes);
      
      const responseBody = mockRes.json.mock.calls[0][0];
      const responseString = JSON.stringify(responseBody);
      
      // Should not contain any 6-digit number (OTP)
      expect(responseString).not.toMatch(/\b\d{6}\b/);
    });
  });
});
