/**
 * UNITWISE CLOUD FUNCTIONS - MAIN INDEX
 */

const admin = require('./admin'); // Use shared admin instance
const { onRequest } = require('firebase-functions/v2/https');

console.log('[Firebase Admin] Using shared instance');
console.log('[Environment]', process.env.APP_ENV || 'development');

// Export Cloud Functions
const { sendOtp } = require('./sendOtp');
const { verifyOtp } = require('./verifyOtp');
const { createUserProfile, sendWelcomeEmailOnCreate } = require('./createUserProfile');
const { resetPassword } = require('./resetPassword');

exports.sendOtp = sendOtp;
exports.verifyOtp = verifyOtp;
exports.createUserProfile = createUserProfile;
exports.resetPassword = resetPassword;
exports.sendWelcomeEmailOnCreate = sendWelcomeEmailOnCreate;

// Health Check Function
exports.healthCheck = onRequest(
  {
    cors: true,
    region: 'us-central1',
    timeoutSeconds: 10,
    memory: '128MiB',
  },
  async (req, res) => {
    return res.status(200).json({
      status: 'ok',
      service: 'unitwise-cloud-functions',
      module: 'authentication',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      environment: process.env.APP_ENV || 'development',
      firestore: 'connected',
    });
  }
);

console.log('[Cloud Functions] Loaded successfully ✓');
