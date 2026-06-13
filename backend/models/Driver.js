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

module.exports = mongoose.model('Driver', driverSchema);
