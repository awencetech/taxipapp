const express = require('express');
const router = express.Router();
const { register, login, forgotPassword, verifyOTP, resetPassword, googleLogin, completeProfile, changePassword, firebasePhoneAuth } = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: John Doe
 *               email:
 *                 type: string
 *                 example: john@example.com
 *               password:
 *                 type: string
 *                 example: password123
 *               mobile:
 *                 type: string
 *                 example: 9876543210
 *               role:
 *                 type: string
 *                 example: user
 */
router.post('/register', register);

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login with email and password
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 example: john@example.com
 *               password:
 *                 type: string
 *                 example: password123
 */
router.post('/login', login);

router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOTP);
router.post('/reset-password', resetPassword);
router.post('/google-login', googleLogin);
router.post('/complete-profile', completeProfile);

// Protected route for changing password
router.put('/change-password', protect, changePassword);

/**
 * @swagger
 * /auth/firebase-phone:
 *   post:
 *     summary: Authenticate with Firebase Phone Auth
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               idToken:
 *                 type: string
 *                 description: Firebase ID Token from phone auth
 *               role:
 *                 type: string
 *                 description: User role (user, driver, vendor)
 *                 enum: [user, driver, vendor]
 *               name:
 *                 type: string
 *                 description: Name (required for new user registration)
 */
router.post('/firebase-phone', firebasePhoneAuth);

module.exports = router;
