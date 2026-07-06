const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: false,
  },
  model: {
    type: String,
    required: true,
  },
  plateNumber: {
    type: String,
    required: true,
    unique: true,
  },
  color: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['mini', 'sedan', 'suv', 'bike', 'auto'],
    default: 'sedan',
  },
  year: Number,
  brand: String,
  rcNumber: String,
  insuranceExpiry: Date,
  pollutionExpiry: Date,
  status: {
    type: String,
    enum: ['active', 'inactive', 'maintenance'],
    default: 'active',
  },
}, { timestamps: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);
