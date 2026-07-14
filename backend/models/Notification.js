const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  driver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Driver',
  },
  vendor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Vendor',
  },
  title: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['ride', 'payment', 'system', 'promo', 'approval'],
    default: 'system',
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  data: {
    type: Object, // Extra data for specific notification types
  },
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
