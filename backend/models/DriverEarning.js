const mongoose = require('mongoose');

const driverEarningSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true
  },
  ride: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride',
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  type: {
    type: String,
    enum: ['ride_earning', 'bonus', 'incentive', 'penalty', 'refund'],
    default: 'ride_earning'
  },
  description: String,
  date: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['pending', 'credited', 'withdrawn'],
    default: 'pending'
  }
}, { timestamps: true });

driverEarningSchema.index({ driver: 1 });
driverEarningSchema.index({ ride: 1 });
driverEarningSchema.index({ date: 1 });

module.exports = mongoose.model('DriverEarning', driverEarningSchema);
