const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    default: null,
  },
  pickupLocation: {
    address: String,
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: [Number],
  },
  dropLocation: {
    address: String,
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: [Number],
  },
  vehicleType: {
    type: String,
    default: 'standard',
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'arrived', 'started', 'completed', 'cancelled'],
    default: 'pending',
  },
  fare: {
    type: Number,
    required: true,
  },
  distance: {
    type: Number, // in km
  },
  duration: {
    type: Number, // in minutes
  },
  paymentMethod: {
    type: String,
    enum: ['cash', 'card', 'wallet', 'upi'],
    default: 'cash',
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'completed', 'failed'],
    default: 'pending',
  },
  otp: {
    type: String,
  },
  cancellationReason: {
    type: String,
  },
  startTime: Date,
  endTime: Date,
}, { timestamps: true });

rideSchema.index({ pickupLocation: '2dsphere' });
rideSchema.index({ dropLocation: '2dsphere' });

module.exports = mongoose.model('Ride', rideSchema);
