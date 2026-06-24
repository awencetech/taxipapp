const express = require('express');
const router = express.Router();
const {
  getAllEarnings,
  getMyEarnings,
  createEarning,
  getEarning
} = require('../controllers/driverEarningController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect);

router.route('/')
  .get(authorize('admin'), getAllEarnings)
  .post(authorize('admin'), createEarning);

router.route('/my-earnings').get(getMyEarnings);
router.route('/:id').get(getEarning);

module.exports = router;
