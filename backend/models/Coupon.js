const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true
  },
  description: String,
  discountType: {
    type: String,
    enum: ['percentage', 'fixed'],
    required: true
  },
  discountValue: {
    type: Number,
    required: true
  },
  maxDiscountAmount: {
    type: Number
  },
  minOrderValue: {
    type: Number,
    default: 0
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  usageLimit: {
    type: Number,
    default: 1
  },
  usageCount: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  applicableUserTypes: [{
    type: String,
    enum: ['user', 'driver'],
    default: 'user'
  }],
  applicableVehicleTypes: [{
    type: String,
    enum: ['mini', 'sedan', 'suv', 'bike']
  }]
}, { timestamps: true });

couponSchema.index({ code: 1 });
couponSchema.index({ isActive: 1 });
couponSchema.index({ startDate: 1, endDate: 1 });

module.exports = mongoose.model('Coupon', couponSchema);
