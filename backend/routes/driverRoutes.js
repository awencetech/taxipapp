const express = require('express');
const router = express.Router();
const { updateDriverProfile, getDriverProfile, updateStatus, updateLocation, getEarnings, registerDriver, getDriverRideHistory, getNotifications, markNotificationAsRead, deleteNotification, markAllNotificationsAsRead } = require('../controllers/driverController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/profile', getDriverProfile);
router.put('/profile', updateDriverProfile);
router.post('/register', registerDriver);
router.put('/status', updateStatus);
router.put('/location', updateLocation);
router.get('/earnings', getEarnings);
router.get('/rides', getDriverRideHistory);

// Notification routes
router.get('/notifications', getNotifications);
router.put('/notifications/:id/read', markNotificationAsRead);
router.delete('/notifications/:id', deleteNotification);
router.put('/notifications/mark-all-read', markAllNotificationsAsRead);

module.exports = router;
