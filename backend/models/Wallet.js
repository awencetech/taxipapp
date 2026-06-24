const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  userType: {
    type: String,
    enum: ['User', 'Driver'],
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    // Note: Since ref can be dynamic, but we'll use userId with userType
  },
  balance: {
    type: Number,
    default: 0
  },
  transactions: [
    {
      amount: {
        type: Number,
        required: true
      },
      type: {
        type: String,
        enum: ['credit', 'debit'],
        required: true
      },
      description: String,
      reference: String,
      date: {
        type: Date,
        default: Date.now
      }
    }
  ]
}, { timestamps: true });

walletSchema.index({ userType: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('Wallet', walletSchema);
