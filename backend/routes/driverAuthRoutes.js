const express = require('express');
const router = express.Router();
const { createRateLimiter } = require('../src/middleware/rateLimiter');
const { forgotPassword, verifyOtp, resetPassword } = require('../controllers/driverAuthController');

const forgotLimiter = createRateLimiter({
  windowMs: 60 * 1000,
  max: 5,
  message: 'Too many requests for forgot password, try again later.',
});

router.post('/forgot-password', forgotLimiter, forgotPassword);
router.post('/verify-otp', verifyOtp);
router.post('/reset-password', resetPassword);

module.exports = router;
