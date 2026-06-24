const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
  ticketId: {
    type: String,
    unique: true,
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  ride: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride'
  },
  subject: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Open', 'In Progress', 'Resolved', 'Closed'],
    default: 'Open'
  },
  priority: {
    type: String,
    enum: ['Low', 'Medium', 'High', 'Urgent'],
    default: 'Medium'
  },
  category: {
    type: String,
    enum: ['Ride Issue', 'Driver Complaint', 'Payment Problem', 'Refund Issue', 'Account Problem', 'Safety Issue', 'Other'],
    default: 'Other'
  },
  attachments: [String],
  messages: [
    {
      sender: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      message: {
        type: String,
        required: true
      },
      timestamp: {
        type: Date,
        default: Date.now
      }
    }
  ]
}, { timestamps: true });

supportTicketSchema.index({ user: 1 });
supportTicketSchema.index({ ride: 1 });
supportTicketSchema.index({ status: 1 });

// Pre-save hook to generate ticketId
supportTicketSchema.pre('save', async function (next) {
  if (!this.isNew) return next();
  
  try {
    // Find the last ticket and increment the number
    const lastTicket = await this.constructor.findOne().sort({ createdAt: -1 });
    let nextNumber = 1;
    
    if (lastTicket && lastTicket.ticketId) {
      const match = lastTicket.ticketId.match(/TKT(\d+)/);
      if (match) {
        nextNumber = parseInt(match[1]) + 1;
      }
    }
    
    this.ticketId = `TKT${String(nextNumber).padStart(4, '0')}`;
    next();
  } catch (error) {
    next(error);
  }
});

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
