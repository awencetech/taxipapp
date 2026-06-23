const express = require('express');
const router = express.Router();
const { 
  getMe, 
  updateProfile, 
  addFavoriteLocation, 
  getRideHistory, 
  getPaymentHistory,
  getNotifications,
  markNotificationAsRead,
  deleteNotification,
  markAllNotificationsAsRead,
  getAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/me', getMe);
router.put('/profile', updateProfile);
router.post('/favorite-locations', addFavoriteLocation);
router.get('/rides', getRideHistory);
router.get('/payments', getPaymentHistory);

// Notification routes
router.get('/notifications', getNotifications);
router.put('/notifications/:id/read', markNotificationAsRead);
router.delete('/notifications/:id', deleteNotification);
router.put('/notifications/mark-all-read', markAllNotificationsAsRead);

// Address routes
router.get('/addresses', getAddresses);
router.post('/addresses', addAddress);
router.put('/addresses/:id', updateAddress);
router.delete('/addresses/:id', deleteAddress);
router.put('/addresses/:id/default', setDefaultAddress);

module.exports = router;
