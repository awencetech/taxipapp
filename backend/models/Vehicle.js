const mongoose = require('mongoose');

const vehicleSchema = new mongoose.Schema({
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
    required: true,
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
    enum: ['mini', 'sedan', 'suv', 'bike'],
    default: 'sedan',
  },
  year: Number,
}, { timestamps: true });

module.exports = mongoose.model('Vehicle', vehicleSchema);
