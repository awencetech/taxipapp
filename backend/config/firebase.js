const admin = require('firebase-admin');
const path = require('path');

try {
  let serviceAccount;
  
  // Try to load from environment variable first
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    } catch (parseError) {
      console.error('⚠️  Failed to parse FIREBASE_SERVICE_ACCOUNT environment variable:', parseError.message);
    }
  }
  
  // If no env var, try loading from file
  if (!serviceAccount) {
    try {
      serviceAccount = require('./firebase-service-account.json');
    } catch (fileError) {
      console.warn('⚠️  Firebase service account file not found at ./config/firebase-service-account.json');
    }
  }
  
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('🔥 Firebase Admin Connected');
  } else {
    console.warn('⚠️  Firebase Admin NOT initialized: No service account found');
  }
} catch (error) {
  console.error('⚠️  Firebase Admin initialization failed:', error.message);
}

module.exports = admin;