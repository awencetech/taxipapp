const express = require('express');
const router = express.Router();
const {
  getPendingRides,
  updateStatus
} = require('../controllers/driverSingularController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.get('/pending-rides', getPendingRides);
router.patch('/status', updateStatus);

module.exports = router;
