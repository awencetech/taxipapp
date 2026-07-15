const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const validator = require('validator');

const vendorSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide your name'],
    trim: true,
  },
  email: {
    type: String,
    required: [true, 'Please provide your email'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: [validator.isEmail, 'Please provide a valid email'],
  },
  phone: {
    type: String,
    required: [true, 'Please provide your phone number'],
    unique: true,
    trim: true,
    validate: {
      validator: function(v) {
        return /^\d{10}$/.test(v);
      },
      message: props => `${props.value} is not a valid 10-digit mobile number!`
    }
  },
  password: {
    type: String,
    required: [true, 'Please provide a password'],
    minlength: 6,
    select: false,
  },
  googleId: {
    type: String,
    sparse: true,
    unique: true,
  },
  firebaseUid: {
    type: String,
    sparse: true,
    unique: true,
  },
  companyName: {
    type: String,
    required: [true, 'Please provide company name'],
  },
  profilePicture: {
    type: String,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  role: {
    type: String,
    enum: ['main_vendor', 'sub_vendor'],
    default: 'sub_vendor',
  },
  approvalStatus: {
    type: String,
    enum: ['pending', 'approved', 'declined'],
    default: 'pending',
  },
  isApproved: {
    type: Boolean,
    default: false,
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
  },
  approvedAt: {
    type: Date,
  },
  declinedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
  },
  declinedAt: {
    type: Date,
  },
  fcmToken: String,
}, { timestamps: true });

vendorSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

vendorSchema.methods.comparePassword = async function (candidatePassword, vendorPassword) {
  return await bcrypt.compare(candidatePassword, vendorPassword);
};

module.exports = mongoose.model('Vendor', vendorSchema);
