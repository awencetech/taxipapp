const express = require('express');
const router = express.Router();
const {
  getCoupons,
  getCoupon,
  createCoupon,
  updateCoupon,
  deleteCoupon,
  validateCoupon
} = require('../controllers/couponController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.route('/')
  .get(getCoupons)
  .post(protect, authorize('admin'), createCoupon);

router.route('/validate').post(protect, validateCoupon);

router.route('/:id')
  .get(getCoupon)
  .put(protect, authorize('admin'), updateCoupon)
  .delete(protect, authorize('admin'), deleteCoupon);

module.exports = router;
