const express = require('express');
const router = express.Router();
const {
  requestRide,
  acceptRide,
  rejectRide,
  arrived,
  startTrip,
  completeTrip
} = require('../controllers/rideSingularController');
const { protect } = require('../middleware/authMiddleware');

router.use(protect);

router.post('/request', requestRide);
router.post('/accept', acceptRide);
router.post('/reject', rejectRide);
router.post('/arrived', arrived);
router.post('/start', startTrip);
router.post('/complete', completeTrip);

module.exports = router;
