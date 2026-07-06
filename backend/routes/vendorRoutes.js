const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  registerVendor,
  loginVendor,
  sendVendorOTP,
  verifyVendorOTP,
  sendForgotPasswordOTP,
  verifyForgotPasswordOTP,
  resetPassword,
  getDashboard,
  getDrivers,
  getDriverById,
  addDriver,
  deleteDriver,
  approveDriver,
  declineDriver,
  getVehicles,
  addVehicle,
  deleteVehicle,
  getTrips,
  getEarnings,
  getAllVendors,
  approveVendor,
  declineVendor,
} = require('../controllers/vendorController');

router.post('/register', registerVendor);
router.post('/login', loginVendor);
router.post('/send-otp', sendVendorOTP);
router.post('/verify-otp', verifyVendorOTP);
router.post('/forgot-password/send-otp', sendForgotPasswordOTP);
router.post('/forgot-password/verify-otp', verifyForgotPasswordOTP);
router.post('/forgot-password/reset', resetPassword);
router.get('/dashboard', protect, getDashboard);
router.get('/drivers', protect, getDrivers);
router.get('/drivers/:id', protect, getDriverById);
router.post('/drivers', protect, addDriver);
router.delete('/drivers/:id', protect, deleteDriver);
router.put('/drivers/:id/approve', protect, approveDriver);
router.put('/drivers/:id/decline', protect, declineDriver);
router.get('/vehicles', protect, getVehicles);
router.post('/vehicles', protect, addVehicle);
router.delete('/vehicles/:id', protect, deleteVehicle);
router.get('/trips', protect, getTrips);
router.get('/earnings', protect, getEarnings);

// Admin routes for vendor management
router.get('/all', getAllVendors);
router.put('/:id/approve', approveVendor);
router.put('/:id/decline', declineVendor);

module.exports = router;
