const Coupon = require('../models/Coupon');

// @desc    Get all coupons
// @route   GET /api/coupons
// @access  Public/Admin
exports.getCoupons = async (req, res, next) => {
  try {
    const coupons = await Coupon.find({ isActive: true, endDate: { $gte: new Date() } });
    res.status(200).json({ success: true, data: coupons });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single coupon
// @route   GET /api/coupons/:id
// @access  Public
exports.getCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    res.status(200).json({ success: true, data: coupon });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a coupon
// @route   POST /api/coupons
// @access  Private/Admin
exports.createCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.create(req.body);
    res.status(201).json({ success: true, data: coupon });
  } catch (error) {
    next(error);
  }
};

// @desc    Update a coupon
// @route   PUT /api/coupons/:id
// @access  Private/Admin
exports.updateCoupon = async (req, res, next) => {
  try {
    let coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    coupon = await Coupon.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    res.status(200).json({ success: true, data: coupon });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a coupon
// @route   DELETE /api/coupons/:id
// @access  Private/Admin
exports.deleteCoupon = async (req, res, next) => {
  try {
    const coupon = await Coupon.findById(req.params.id);
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    await Coupon.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Coupon deleted successfully' });
  } catch (error) {
    next(error);
  }
};

// @desc    Validate a coupon
// @route   POST /api/coupons/validate
// @access  Private
exports.validateCoupon = async (req, res, next) => {
  try {
    const { code, orderValue, userType, vehicleType } = req.body;
    const coupon = await Coupon.findOne({ code: code.toUpperCase(), isActive: true });
    
    if (!coupon) {
      return res.status(404).json({ success: false, message: 'Coupon not found' });
    }
    
    // Check if coupon is expired
    if (new Date() > coupon.endDate || new Date() < coupon.startDate) {
      return res.status(400).json({ success: false, message: 'Coupon is expired or not yet valid' });
    }
    
    // Check usage limit
    if (coupon.usageCount >= coupon.usageLimit) {
      return res.status(400).json({ success: false, message: 'Coupon usage limit reached' });
    }
    
    // Check minimum order value
    if (orderValue < coupon.minOrderValue) {
      return res.status(400).json({ success: false, message: `Minimum order value of ₹${coupon.minOrderValue} required` });
    }
    
    // Check applicable user type
    if (coupon.applicableUserTypes.length > 0 && !coupon.applicableUserTypes.includes(userType)) {
      return res.status(400).json({ success: false, message: 'Coupon not applicable for this user type' });
    }
    
    // Check applicable vehicle type
    if (coupon.applicableVehicleTypes.length > 0 && !coupon.applicableVehicleTypes.includes(vehicleType)) {
      return res.status(400).json({ success: false, message: 'Coupon not applicable for this vehicle type' });
    }
    
    // Calculate discount
    let discountAmount;
    if (coupon.discountType === 'percentage') {
      discountAmount = (coupon.discountValue / 100) * orderValue;
      if (coupon.maxDiscountAmount && discountAmount > coupon.maxDiscountAmount) {
        discountAmount = coupon.maxDiscountAmount;
      }
    } else {
      discountAmount = coupon.discountValue;
      if (discountAmount > orderValue) {
        discountAmount = orderValue;
      }
    }
    
    res.status(200).json({ 
      success: true, 
      valid: true, 
      discountAmount,
      coupon 
    });
    
  } catch (error) {
    next(error);
  }
};
