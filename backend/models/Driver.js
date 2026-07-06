const mongoose = require('mongoose');

const driverSchema = new mongoose.Schema({
  driverId: {
    type: String,
    unique: true,
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  vendor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
    required: false,
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
  isBusy: {
    type: Boolean,
    default: false,
  },
  currentRide: {
    type: String,
    default: null,
  },
  currentLatitude: {
    type: Number,
    default: 0.0,
  },
  currentLongitude: {
    type: Number,
    default: 0.0,
  },
  socketId: {
    type: String,
    default: null,
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
      title: {
        type: String,
        required: true,
      },
      category: {
        type: String,
        enum: ['vehicle', 'personal'],
        default: 'vehicle',
      },
      url: {
        type: String,
        default: '',
      },
      status: {
        type: String,
        enum: ['Verified', 'Pending', 'Rejected', 'Expiring Soon'],
        default: 'Pending',
      },
      uploadedAt: {
        type: Date,
        default: Date.now,
      },
      expiryDate: {
        type: Date,
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
  // New fields for address and bank details
  address: {
    type: String,
    default: '',
  },
  // Backward compatibility for old single bank account
  bankName: {
    type: String,
    default: '',
  },
  accountHolderName: {
    type: String,
    default: '',
  },
  accountNumber: {
    type: String,
    default: '',
  },
  ifscCode: {
    type: String,
    default: '',
  },
  branchName: {
    type: String,
    default: '',
  },
  // New: Multiple bank accounts (max 3)
  bankAccounts: [
    {
      bankName: {
        type: String,
        required: true,
      },
      accountHolderName: {
        type: String,
        required: true,
      },
      accountNumber: {
        type: String,
        required: true,
      },
      ifscCode: {
        type: String,
        required: true,
      },
      branchName: {
        type: String,
        default: '',
      },
    },
  ],
}, { timestamps: true });

driverSchema.index({ currentLocation: '2dsphere' });

// Auto-generate driverId before saving
driverSchema.pre('save', async function (next) {
  if (this.isNew) {
    const lastDriver = await mongoose.model('Driver').findOne().sort({ driverId: -1 }).exec();
    let nextId = 1;
    if (lastDriver && lastDriver.driverId) {
      const lastNum = parseInt(lastDriver.driverId.replace('DRV', ''), 10);
      nextId = lastNum + 1;
    }
    this.driverId = `DRV${String(nextId).padStart(6, '0')}`;
  }
  next();
});

module.exports = mongoose.model('Driver', driverSchema);
