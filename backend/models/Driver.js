const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  vehicle: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vehicle',
    required: false,
  },
  vehicleType: {
    type: String,
    default: 'Car',
  },
  vehicleNumber: {
    type: String,
    default: 'TN 01 AB 1234',
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    enum: ['available', 'busy', 'offline'],
    default: 'offline',
  },
  currentLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      default: [0, 0],
    },
  },
  licenseNumber: {
    type: String,
    required: [true, 'Please provide license number'],
    unique: true,
  },
  documents: [
    {
      name: String,
      url: String,
      status: {
        type: String,
        enum: ['pending', 'approved', 'rejected'],
        default: 'pending',
      },
    },
  ],
  isApproved: {
    type: Boolean,
    default: false,
  },
  totalEarnings: {
    type: Number,
    default: 0,
  },
  ratings: {
    type: Number,
    default: 5,
  },
  numReviews: {
    type: Number,
    default: 0,
  },
}, { timestamps: true });

driverSchema.index({ currentLocation: '2dsphere' });

module.exports = mongoose.model('Driver', driverSchema);
