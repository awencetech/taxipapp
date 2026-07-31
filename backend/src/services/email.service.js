const nodemailer = require('nodemailer');
const fs = require('fs').promises;
const path = require('path');
const validator = require('validator');
const logger = require('../../utils/logger');

const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = Number(process.env.SMTP_PORT) || 587;
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const FROM_EMAIL = process.env.SMTP_FROM_EMAIL || SMTP_USER;
const FROM_NAME = process.env.SMTP_FROM_NAME || 'Taxi Nanban';

// Print non-sensitive SMTP configuration for debugging (do NOT print SMTP_PASS)
logger.info('EmailService initializing - SMTP config: host=%s port=%s user=%s', SMTP_HOST, SMTP_PORT, SMTP_USER);

if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
  logger.warn('SMTP not fully configured. Ensure SMTP_HOST, SMTP_USER and SMTP_PASS are set in .env');
}

// Ensure secure=false for port 587 (STARTTLS)
const secureFlag = SMTP_PORT === 465; // true for 465 (SSL), false for 587 (STARTTLS)

const transporter = nodemailer.createTransport({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: secureFlag,
  auth: { user: SMTP_USER, pass: SMTP_PASS },
  tls: { rejectUnauthorized: false },
  pool: true,
  maxConnections: 5,
  maxMessages: 100,
});

async function verifyTransporter() {
  try {
    logger.info('Verifying SMTP transporter...');
    await transporter.verify();
    logger.info('SMTP transporter verified successfully');
  } catch (err) {
    // Log detailed error for debugging
    logger.error('Failed to verify SMTP transporter: %s', err && err.message ? err.message : err);
    logger.error('verifyTransporter error details: %o', {
      code: err && err.code,
      response: err && err.response,
      responseCode: err && err.responseCode,
      stack: err && err.stack,
    });
    throw err;
  }
}

async function loadTemplate(name, variables = {}) {
  try {
    const tplPath = path.resolve(__dirname, '../../templates', `${name}.html`);
    let html = await fs.readFile(tplPath, 'utf8');
    Object.keys(variables).forEach((k) => {
      const re = new RegExp(`{{\\s*${k}\\s*}}`, 'g');
      html = html.replace(re, variables[k] != null ? String(variables[k]) : '');
    });
    return html;
  } catch (err) {
    logger.error('Error loading template %s: %s', name, err.message || err);
    throw err;
  }
}

function isValidEmail(email) {
  return typeof email === 'string' && validator.isEmail(email);
}

async function sendMail(to, subject, html) {
  if (!isValidEmail(to)) {
    const err = new Error(`Invalid email address: ${to}`);
    logger.warn(err.message);
    throw err;
  }
  const mailOptions = { from: `${FROM_NAME} <${FROM_EMAIL}>`, to, subject, html };
  try {
    logger.info('Sending email to %s subject=%s (secure=%s)', to, subject, secureFlag);
    const info = await transporter.sendMail(mailOptions);
    logger.info('Email sent to %s subject=%s messageId=%s', to, subject, info.messageId);
    return info;
  } catch (err) {
    // Detailed logging for SMTP failures
    logger.error('Failed to send email to %s: %s', to, err && err.message ? err.message : err);
    logger.error('sendMail error details: %o', {
      code: err && err.code,
      response: err && err.response,
      responseCode: err && err.responseCode,
      message: err && err.message,
      stack: err && err.stack,
    });
    throw err;
  }
}

async function sendOTP(to, { otp, name } = {}) {
  const html = await loadTemplate('otp', { otp, name: name || '' });
  const subject = 'Your OTP code';
  return sendMail(to, subject, html);
}

async function sendVerification(to, { name, link } = {}) {
  const html = await loadTemplate('verification', { name: name || '', link: link || '' });
  const subject = 'Verify your email address';
  return sendMail(to, subject, html);
}

async function sendForgotPassword(to, { name, link } = {}) {
  const html = await loadTemplate('forgot-password', { name: name || '', link: link || '' });
  const subject = 'Reset your password';
  return sendMail(to, subject, html);
}

async function sendDriverPasswordResetOtp(to, { otp, name } = {}) {
  const html = await loadTemplate('password-reset-otp', {
    otp: otp || '',
    name: name || 'Driver',
  });
  const subject = 'Taxi Nanban Driver Password Reset OTP';
  return sendMail(to, subject, html);
}

async function sendWelcomeEmail(to, { name } = {}) {
  const html = await loadTemplate('welcome', { name: name || '' });
  const subject = 'Welcome to Taxi Nanban';
  return sendMail(to, subject, html);
}

async function sendDriverApproval(to, { name, status } = {}) {
  const html = await loadTemplate('driver-approved', { name: name || '', status: status || 'approved' });
  const subject = `Driver account ${status}`;
  return sendMail(to, subject, html);
}

async function sendVendorApproval(to, { name, status } = {}) {
  const html = await loadTemplate('vendor-approved', { name: name || '', status: status || 'approved' });
  const subject = `Vendor account ${status}`;
  return sendMail(to, subject, html);
}

async function sendBookingConfirmation(to, { name, bookingId, details } = {}) {
  const html = await loadTemplate('booking', { name: name || '', bookingId: bookingId || '', details: details || '' });
  const subject = 'Your booking confirmation';
  return sendMail(to, subject, html);
}

module.exports = {
  transporter,
  verifyTransporter,
  loadTemplate,
  sendMail,
  sendOTP,
  sendVerification,
  sendForgotPassword,
  sendWelcomeEmail,
  sendDriverApproval,
  sendVendorApproval,
  sendDriverPasswordResetOtp,
  sendBookingConfirmation,
};
