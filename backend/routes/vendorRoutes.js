const express = require('express');
const router = express.Router();
const {
  registerVendor,
  loginVendor,
  sendVendorOTP,
  verifyVendorOTP,
  getDashboard,
  getDrivers,
  addDriver,
  deleteDriver,
  getVehicles,
  addVehicle,
  deleteVehicle,
  getTrips,
  getEarnings,
} = require('../controllers/vendorController');

router.post('/register', registerVendor);
router.post('/login', loginVendor);
router.post('/send-otp', sendVendorOTP);
router.post('/verify-otp', verifyVendorOTP);
router.get('/dashboard', getDashboard);
router.get('/drivers', getDrivers);
router.post('/drivers', addDriver);
router.delete('/drivers/:id', deleteDriver);
router.get('/vehicles', getVehicles);
router.post('/vehicles', addVehicle);
router.delete('/vehicles/:id', deleteVehicle);
router.get('/trips', getTrips);
router.get('/earnings', getEarnings);

module.exports = router;
