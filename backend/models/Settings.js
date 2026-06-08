const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  baseFare: {
    type: Number,
    default: 50,
  },
  pricePerKm: {
    type: Number,
    default: 15,
  },
  adminEmail: {
    type: String,
    required: true,
  },
  adminPhone: {
    type: String,
    required: true,
  },
  adminName: {
    type: String,
    required: true,
  }
}, { timestamps: true });

module.exports = mongoose.model('Settings', settingsSchema);
