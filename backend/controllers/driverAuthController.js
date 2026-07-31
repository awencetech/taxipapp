const Driver = require('../models/Driver');
const crypto = require('crypto');
const EmailService = require('../src/services/email.service');

const generateOtp = () => {
  return crypto.randomInt(100000, 1000000).toString().padStart(6, '0');
};

const validateEmail = (email) => {
  return typeof email === 'string' && email.trim().length > 0;
};

const validatePassword = (password) => {
  if (typeof password !== 'string' || password.length < 8) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  if (!/[!@#\$&*~^%()_+\-=\[\]{};:'"\\|,.<>\/?]/.test(password)) return false;
  return true;
};

const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!validateEmail(email)) {
      return res.status(400).json({ success: false, message: 'Please provide a valid email address' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const driver = await Driver.findOne({ email: normalizedEmail });

    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }

    const otp = generateOtp();
    driver.resetOtp = otp;
    driver.resetOtpExpiry = Date.now() + 10 * 60 * 1000;
    await driver.save({ validateBeforeSave: false });

    try {
      await EmailService.sendDriverPasswordResetOtp(driver.email, {
        otp,
        name: driver.name || 'Driver',
      });

      return res.status(200).json({ success: true, message: 'OTP sent successfully' });
    } catch (emailError) {
      driver.resetOtp = undefined;
      driver.resetOtpExpiry = undefined;
      await driver.save({ validateBeforeSave: false });

      const safeMessage = emailError && emailError.message ? String(emailError.message) : 'Email send failed';
      let clientMessage = safeMessage;
      if (/EAUTH|Authentication failed/i.test(safeMessage)) {
        clientMessage = 'SMTP authentication failed. Please check SMTP credentials.';
      } else if (/ENOTFOUND|ECONNREFUSED|ETIMEDOUT/i.test(safeMessage)) {
        clientMessage = 'Unable to connect to email service. Please try again later.';
      }

      console.error('Driver forgotPassword email error:', emailError);
      return res.status(500).json({
        success: false,
        message: `OTP could not be sent. ${clientMessage}`,
      });
    }
  } catch (error) {
    console.error('Driver forgotPassword error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!validateEmail(email) || !otp) {
      return res.status(400).json({ success: false, message: 'Please provide email and OTP' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const driver = await Driver.findOne({
      email: normalizedEmail,
      resetOtp: otp,
      resetOtpExpiry: { $gt: Date.now() },
    });

    if (!driver) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    return res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } catch (error) {
    console.error('Driver verifyOtp error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

const resetPassword = async (req, res) => {
  try {
    console.log('Driver resetPassword request body:', req.body);
    const { email, otp, password } = req.body;
    if (!validateEmail(email) || !otp || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email, OTP and new password' });
    }

    if (!validatePassword(password)) {
      return res.status(400).json({
        success: false,
        message:
          'Password must be at least 8 characters and include uppercase, lowercase, number, and special character',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const driver = await Driver.findOne({
      email: normalizedEmail,
      resetOtp: otp,
      resetOtpExpiry: { $gt: Date.now() },
    });

    if (!driver) {
      console.error('Driver resetPassword failed: driver not found for email', normalizedEmail);
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    console.log('Driver Found for reset password:', driver.email);
    console.log('OTP Verified for driver reset password');

    driver.password = password;
    driver.resetOtp = null;
    driver.resetOtpExpiry = null;
    await driver.save({ validateBeforeSave: false });

    console.log('Driver Saved Successfully after password reset');
    return res.status(200).json({ success: true, message: 'Password reset successfully' });
  } catch (error) {
    console.error('Driver resetPassword error:', error);
    return res.status(500).json({ success: false, message: error.message || 'Server error' });
  }
};

module.exports = {
  forgotPassword,
  verifyOtp,
  resetPassword,
};
