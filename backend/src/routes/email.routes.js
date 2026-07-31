const express = require('express');
const router = express.Router();
const EmailController = require('../controllers/email.controller');
const { createRateLimiter } = require('../middleware/rateLimiter');
const emailApiKey = require('../middleware/emailAuth');

// Apply a strict rate limiter for OTP/forgot emails to prevent abuse
const strictLimiter = createRateLimiter({ windowMs: 60 * 1000, max: 5, message: 'Too many email requests, try again later.' });

// Send OTP to email
router.post('/send-otp', strictLimiter, EmailController.sendOtp);

// Send email verification link
router.post('/send-verification', strictLimiter, EmailController.sendVerification);

// Forgot password email
router.post('/forgot-password', strictLimiter, EmailController.sendForgotPassword || EmailController.sendVerification);

// Generic send endpoint. Protected by API key and a relaxed limiter.
const relaxedLimiter = createRateLimiter({ windowMs: 60 * 1000, max: 30 });
router.post('/send', emailApiKey, relaxedLimiter, EmailController.sendGeneric);

module.exports = router;
