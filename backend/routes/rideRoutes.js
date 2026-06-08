const express = require('express');
const router = express.Router();
const { estimateFare, createRide, updateRideStatus, getRide, getDriverRides } = require('../controllers/rideController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.post('/estimate', estimateFare);
router.post('/create', createRide);
router.get('/driver/my-rides', getDriverRides);
router.get('/:id', getRide);
router.put('/:id/status', updateRideStatus);

module.exports = router;
