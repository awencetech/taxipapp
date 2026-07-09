const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const validator = require('validator');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide your name'],
    trim: true,
  },
  email: {
    type: String,
    required: function() { return !this.googleId && !this.firebaseUid; }, // Required only if not social/phone login
    unique: true,
    sparse: true, // Allows multiple nulls for email
    lowercase: true,
    trim: true,
    validate: {
      validator: function(v) {
        if (!v) return true; // Skip validation if empty (for social/phone login)
        return validator.isEmail(v);
      },
      message: 'Please provide a valid email'
    },
  },
  mobile: {
    type: String,
    required: function() { return !this.googleId; }, // Required only if not social login
    unique: true,
    sparse: true, // Allows multiple nulls if field is missing
    trim: true,
    validate: {
      validator: function(v) {
        if (!v) return true; // Skip validation if empty (for social login)
        return /^\d{10}$/.test(v);
      },
      message: props => `${props.value} is not a valid 10-digit mobile number!`
    }
  },
  password: {
    type: String,
    required: function() { return !this.googleId && !this.firebaseUid; }, // Required only if not social/phone login
    minlength: 6,
    select: false,
  },
  role: {
    type: String,
    enum: ['user', 'driver', 'admin'],
    default: 'user',
  },
  profilePic: {
    type: String,
    default: 'default-profile.png',
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  addresses: [
    {
      type: {
        type: String,
        enum: ['home', 'work', 'other'],
        default: 'other'
      },
      label: String,
      address: String,
      landmark: String,
      city: String,
      state: String,
      pincode: String,
      latitude: { type: Number, default: 0.0 },
      longitude: { type: Number, default: 0.0 },
      isDefault: { type: Boolean, default: false }
    }
  ],
  favoriteLocations: [
    {
      name: String,
      address: String,
      location: {
        type: {
          type: String,
          enum: ['Point'],
          default: 'Point',
        },
        coordinates: [Number], // [longitude, latitude]
      },
    },
  ],
  googleId: String,
  firebaseUid: String,
  fcmToken: String,
  ratings: {
    type: Number,
    default: 5,
  },
  numReviews: {
    type: Number,
    default: 0,
  },
  totalRides: {
    type: Number,
    default: 0,
  },
  rewards: {
    type: Number,
    default: 0,
  },
  membershipStatus: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'],
    default: 'Bronze',
  },
  resetPasswordOTP: String,
  resetPasswordExpires: Date,
}, { timestamps: true });

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.index({ mobile: 1 }, { unique: true, sparse: true });

userSchema.methods.comparePassword = async function (candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

module.exports = mongoose.model('User', userSchema);
