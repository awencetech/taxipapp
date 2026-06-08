const express = require('express');
const router = express.Router();
const { getMe, updateProfile, addFavoriteLocation, getRideHistory, getPaymentHistory } = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/me', getMe);
router.put('/profile', updateProfile);
router.post('/favorite-locations', addFavoriteLocation);
router.get('/rides', getRideHistory);
router.get('/payments', getPaymentHistory);

module.exports = router;
