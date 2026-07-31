const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const validator = require('validator');

const driverSchema = new mongoose.Schema({
  name: {
    type: String,
    required: false,
    trim: true,
  },
  lastName: {
    type: String,
    required: false,
    trim: true,
  },
  email: {
    type: String,
    required: false,
    sparse: true, // Allows multiple nulls for email
    lowercase: true,
    trim: true,
    validate: {
      validator: function(v) {
        if (!v) return true; // Skip validation if empty
        return validator.isEmail(v);
      },
      message: 'Please provide a valid email'
    },
  },
  mobile: {
    type: String,
    required: false,
    unique: true,
    sparse: true,
    trim: true,
    validate: {
      validator: function(v) {
        if (!v) return true; // Skip validation if empty
        return /^\d{10}$/.test(v);
      },
      message: props => `${props.value} is not a valid 10-digit mobile number!`
    }
  },
  password: {
    type: String,
    required: false,
    minlength: 6,
    select: false,
  },
  role: {
    type: String,
    enum: ['driver'],
    default: 'driver',
  },
  profilePic: {
    type: String,
    default: 'default-profile.png',
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  googleId: String,
  firebaseUid: String,
  fcmToken: String,
  driverId: {
    type: String,
    unique: true,
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
  isAvailable: {
    type: Boolean,
    default: false,
  },
  rideStatus: {
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
  lastSeen: {
    type: Date,
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
    required: false,
    unique: true,
    sparse: true,
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
  documentsVerified: {
    type: Boolean,
    default: false,
  },
  // Approval workflow fields
  approvalStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  accountStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
    default: null,
  },
  approvedAt: {
    type: Date,
    default: null,
  },
  rejectionReason: {
    type: String,
    default: null,
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
  resetOtp: {
    type: String,
    select: false,
  },
  resetOtpExpiry: {
    type: Date,
    select: false,
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
}, { timestamps: true, strictPopulate: false });

driverSchema.index({ currentLocation: '2dsphere' });
driverSchema.index({ firebaseUid: 1 }, { sparse: true, unique: true });
driverSchema.index({ googleId: 1 }, { sparse: true, unique: true });
driverSchema.index({ email: 1 }, { sparse: true, unique: true });

// Auto-generate driverId before validation
driverSchema.pre('validate', async function (next) {
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

// Hash password before saving
driverSchema.pre('save', async function (next) {
  if (this.isModified('password')) {
    this.password = await bcrypt.hash(this.password, 12);
  }
  next();
});

driverSchema.methods.comparePassword = async function (candidatePassword, driverPassword) {
  return await bcrypt.compare(candidatePassword, driverPassword);
};

module.exports = mongoose.model('Driver', driverSchema);
