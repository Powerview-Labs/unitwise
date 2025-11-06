/**
 * Shared Firebase Admin Instance
 * Properly exports Firestore and all its utilities
 */

const admin = require('firebase-admin');

// Initialize only once
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || 'unitwise-83a71',
  });
  
  console.log('[Shared Admin] Firebase Admin initialized');
}

// Get Firestore instance
const db = admin.firestore();
db.settings({
  timestampsInSnapshots: true,
  ignoreUndefinedProperties: true,
});

// Export everything we need
module.exports = admin;
