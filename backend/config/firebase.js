const admin = require('firebase-admin');
const path = require('path');

try {
  const serviceAccount = require('./firebase-service-account.json');

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('🔥 Firebase Admin Connected');
} catch (error) {
  console.warn('⚠️  Firebase Admin initialization failed:', error.message);
}

module.exports = admin;