const express = require('express');
const router = express.Router();
const {
  estimateFare,
  createRide,
  cancelRide,
  updateRideStatus,
  getRide,
  getDriverRides,
  getUserRides,
  getDriverHistory,
  getDriverCurrentRide,
  driverAcceptRide,
  driverRejectRide,
  driverArrived,
  driverStartTrip,
  driverCompleteTrip
} = require('../controllers/rideController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.post('/estimate', estimateFare);
router.post('/create', createRide);
router.get('/driver/my-rides', getDriverRides);
router.get('/user/my-rides', getUserRides);
router.get('/:id', getRide);
router.put('/:id/status', updateRideStatus);
router.put('/:rideId/cancel', cancelRide);

// Driver specific routes
router.get('/driver/history', getDriverHistory);
router.get('/driver/current-ride', getDriverCurrentRide);
router.post('/driver/accept', driverAcceptRide);
router.post('/driver/reject', driverRejectRide);
router.post('/driver/arrived', driverArrived);
router.post('/driver/start-trip', driverStartTrip);
router.post('/driver/complete-trip', driverCompleteTrip);

module.exports = router;
