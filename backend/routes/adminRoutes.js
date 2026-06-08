const express = require('express');
const router = express.Router();
const { getAllUsers, getAllDrivers, approveDriver, getStats, getAllRides, getAllPayments, getSettings, updateSettings } = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('admin'));

router.get('/users', getAllUsers);
router.get('/drivers', getAllDrivers);
router.put('/drivers/:id/approve', approveDriver);
router.get('/stats', getStats);
router.get('/rides', getAllRides);
router.get('/payments', getAllPayments);
router.get('/settings', getSettings);
router.put('/settings', updateSettings);

module.exports = router;
