const SupportTicket = require('../models/SupportTicket');
const User = require('../models/User');

// @desc    Create a new support ticket
// @route   POST /api/v1/support-tickets
// @access  Private
exports.createTicket = async (req, res, next) => {
  try {
    const { category, subject, description, ride, priority } = req.body;

    if (!subject || !description) {
      return res.status(400).json({
        success: false,
        message: 'Please provide subject and description'
      });
    }

    const ticket = await SupportTicket.create({
      user: req.user._id,
      subject,
      description,
      category,
      ride,
      priority
    });

    res.status(201).json({
      success: true,
      data: ticket
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all support tickets (admin)
// @route   GET /api/v1/support-tickets
// @access  Private/Admin
exports.getTickets = async (req, res, next) => {
  try {
    const tickets = await SupportTicket.find()
      .populate('user', 'name email')
      .populate('ride');

    res.status(200).json({
      success: true,
      data: tickets
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's own support tickets
// @route   GET /api/v1/support-tickets/my-tickets
// @access  Private
exports.getMyTickets = async (req, res, next) => {
  try {
    const tickets = await SupportTicket.find({ user: req.user._id }).populate('ride');

    res.status(200).json({
      success: true,
      data: tickets
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single support ticket
// @route   GET /api/v1/support-tickets/:id
// @access  Private
exports.getTicket = async (req, res, next) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id)
      .populate('user')
      .populate('ride');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check if user is owner or admin
    if (ticket.user._id.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    res.status(200).json({
      success: true,
      data: ticket
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update support ticket
// @route   PUT /api/v1/support-tickets/:id
// @access  Private
exports.updateTicket = async (req, res, next) => {
  try {
    let ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Check if user is owner or admin
    if (ticket.user.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized'
      });
    }

    ticket = await SupportTicket.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    res.status(200).json({
      success: true,
      data: ticket
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add message to support ticket
// @route   POST /api/v1/support-tickets/:id/messages
// @access  Private
exports.addMessage = async (req, res, next) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    ticket.messages.push({
      sender: req.user._id,
      message: req.body.message
    });

    await ticket.save();

    res.status(200).json({
      success: true,
      data: ticket
    });
  } catch (error) {
    next(error);
  }
};
