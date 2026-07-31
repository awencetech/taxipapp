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
  rideId: {
    type: String,
  },
  userId: {
    type: String,
  },
  vendorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
    default: null,
  },
  driverId: {
    type: String,
  },
  rejectedDrivers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
  }],
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
    enum: ['searching', 'accepted', 'driver_arriving', 'arrived', 'trip_started', 'completed', 'cancelled'],
    default: 'searching',
  },
  acceptedTime: {
    type: Date,
    default: null,
  },
  arrivedTime: {
    type: Date,
    default: null,
  },
  startedTime: {
    type: Date,
    default: null,
  },
  completedTime: {
    type: Date,
    default: null,
  },
  cancelledTime: {
    type: Date,
    default: null,
  },
  otpVerified: {
    type: Boolean,
    default: false,
  },
  driverLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: [Number],
  },
  route: [
    {
      latitude: Number,
      longitude: Number,
      timestamp: Date,
    },
  ],
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
rideSchema.index({ status: 1 });
rideSchema.index({ user: 1 });
rideSchema.index({ driver: 1 });

module.exports = mongoose.model('Ride', rideSchema);
