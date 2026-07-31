// Simple test script to verify SMTP transporter and send a test email.
// Usage: node test-email.js recipient@example.com

require('dotenv').config();
const EmailService = require('./src/services/email.service');
const logger = require('./utils/logger');

async function run() {
  const to = process.argv[2] || process.env.TEST_EMAIL_TO;
  if (!to) {
    console.error('Usage: node test-email.js recipient@example.com OR set TEST_EMAIL_TO in .env');
    process.exit(1);
  }

  try {
    console.log('Verifying SMTP transporter...');
    await EmailService.verifyTransporter();
    console.log('Transporter verified. Sending test email to', to);

    const info = await EmailService.sendMail(to, 'Test email from Taxi Nanban', '<p>This is a test email from Taxi Nanban backend.</p>');
    console.log('Test email sent:', info.messageId);
    process.exit(0);
  } catch (err) {
    logger.error('Test email failed: %o', err);
    console.error('Test email failed:', err && err.message ? err.message : err);
    process.exit(2);
  }
}

run();
