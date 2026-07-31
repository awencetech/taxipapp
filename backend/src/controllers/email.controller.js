const logger = require('../../utils/logger');
const EmailService = require('../services/email.service');
const validator = require('validator');

/**
 * Send OTP to a user/driver/vendor.
 * Expects { email, otp, name }
 */
async function sendOtp(req, res, next) {
  try {
    const { email, otp, name } = req.body;
    if (!email || !validator.isEmail(email)) {
      return res.status(400).json({ message: 'Invalid email' });
    }
    if (!otp) return res.status(400).json({ message: 'OTP is required' });

    const info = await EmailService.sendOTP(email, { otp, name });
    return res.status(200).json({ message: 'OTP sent', info: info.messageId });
  } catch (err) {
    logger.error('sendOtp error: %s', err.message || err);
    return next(err);
  }
}

/**
 * Send verification email.
 * Expects { email, link, name }
 */
async function sendVerification(req, res, next) {
  try {
    const { email, link, name } = req.body;
    if (!email || !validator.isEmail(email)) {
      return res.status(400).json({ message: 'Invalid email' });
    }
    if (!link) return res.status(400).json({ message: 'Verification link is required' });

    const info = await EmailService.sendVerification(email, { name, link });
    return res.status(200).json({ message: 'Verification email sent', info: info.messageId });
  } catch (err) {
    logger.error('sendVerification error: %s', err.message || err);
    return next(err);
  }
}

/**
 * Send forgot password email.
 * Expects { email, link, name }
 */
async function forgotPassword(req, res, next) {
  try {
    const { email, link, name } = req.body;
    if (!email || !validator.isEmail(email)) {
      return res.status(400).json({ message: 'Invalid email' });
    }
    if (!link) return res.status(400).json({ message: 'Reset link is required' });

    const info = await EmailService.sendForgotPassword(email, { name, link });
    return res.status(200).json({ message: 'Forgot password email sent', info: info.messageId });
  } catch (err) {
    logger.error('forgotPassword error: %s', err.message || err);
    return next(err);
  }
}

/**
 * Generic send endpoint. Accepts { to, subject, template, variables }
 */
async function sendGeneric(req, res, next) {
  try {
    const { to, subject, template, variables } = req.body;
    if (!to || !validator.isEmail(to)) {
      return res.status(400).json({ message: 'Invalid recipient email' });
    }
    if (!subject) return res.status(400).json({ message: 'Subject is required' });
    if (!template) return res.status(400).json({ message: 'Template is required' });

    const html = await EmailService.loadTemplate(template, variables || {});
    const info = await EmailService.sendMail(to, subject, html);
    return res.status(200).json({ message: 'Email sent', info: info.messageId });
  } catch (err) {
    logger.error('sendGeneric error: %s', err.message || err);
    return next(err);
  }
}

module.exports = {
  sendOtp,
  sendVerification,
  forgotPassword,
  sendGeneric,
};
