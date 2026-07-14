const express = require('express');
const router = express.Router();
const { updateDriverProfile, getDriverProfile, updateStatus, updateLocation, getEarnings, registerDriver, getDriverRideHistory, getNotifications, markNotificationAsRead, deleteNotification, markAllNotificationsAsRead, uploadDocument, editDocument, deleteDocument, registerPendingDriver, getDriverStatus } = require('../controllers/driverController');
const { protect, authorize } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

// Public routes
router.post('/register-pending', registerPendingDriver);
router.get('/status', getDriverStatus);

// Protected routes
router.use(protect);

router.get('/profile', getDriverProfile);
router.put('/profile', upload.single('profilePic'), updateDriverProfile); // Add upload middleware for profile pic
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

// Document routes
router.post('/documents', upload.single('document'), uploadDocument);
router.put('/documents/:docId', upload.single('document'), editDocument);
router.delete('/documents/:docId', deleteDocument);

module.exports = router;
