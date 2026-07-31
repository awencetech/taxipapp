// Debug script to verify SMTP env, transporter, and to send a test email with detailed output.
// Usage: node test-email-debug.js recipient@example.com

require('dotenv').config();
const util = require('util');
const EmailService = require('./src/services/email.service');
const logger = require('./utils/logger');

async function run() {
  const to = process.argv[2] || process.env.TEST_EMAIL_TO;
  if (!to) {
    console.error('Usage: node test-email-debug.js recipient@example.com OR set TEST_EMAIL_TO in .env');
    process.exit(1);
  }

  // Print non-sensitive env vars
  console.log('DOTENV loaded:', !!process.env.SMTP_HOST);
  console.log('SMTP_HOST:', process.env.SMTP_HOST);
  console.log('SMTP_PORT:', process.env.SMTP_PORT);
  console.log('SMTP_USER:', process.env.SMTP_USER);
  // DO NOT print SMTP_PASS

  try {
    console.log('\n-- Verifying transporter --');
    await EmailService.verifyTransporter();
    console.log('-- Transporter verified --\n');
  } catch (err) {
    console.error('Transporter verification failed:');
    console.error(util.inspect(err, { depth: null }));
    process.exit(2);
  }

  try {
    console.log('-- Sending test email to %s --', to);
    const info = await EmailService.sendMail(to, 'Taxi Nanban - Test Email', '<p>This is a test email from backend (debug).</p>');
    console.log('Test email sent. messageId=', info && info.messageId);
    process.exit(0);
  } catch (err) {
    console.error('Test email send failed:');
    console.error(util.inspect(err, { depth: null }));
    process.exit(3);
  }
}

run();
