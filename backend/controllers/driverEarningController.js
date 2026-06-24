const DriverEarning = require('../models/DriverEarning');
const Driver = require('../models/Driver');

// @desc    Get all driver earnings (admin)
// @route   GET /api/driver-earnings
// @access  Private/Admin
exports.getAllEarnings = async (req, res, next) => {
  try {
    const earnings = await DriverEarning.find().populate('driver ride');
    res.status(200).json({ success: true, data: earnings });
  } catch (error) {
    next(error);
  }
};

// @desc    Get driver's own earnings
// @route   GET /api/driver-earnings/my-earnings
// @access  Private/Driver
exports.getMyEarnings = async (req, res, next) => {
  try {
    const driver = await Driver.findOne({ user: req.user.id });
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }
    const earnings = await DriverEarning.find({ driver: driver._id }).populate('ride');
    const totalEarnings = earnings.reduce((sum, earning) => 
      sum + (earning.type !== 'penalty' ? earning.amount : -earning.amount), 0);
    res.status(200).json({ success: true, data: earnings, totalEarnings });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a new earning record (admin)
// @route   POST /api/driver-earnings
// @access  Private/Admin
exports.createEarning = async (req, res, next) => {
  try {
    const earning = await DriverEarning.create(req.body);
    res.status(201).json({ success: true, data: earning });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single earning record
// @route   GET /api/driver-earnings/:id
// @access  Private
exports.getEarning = async (req, res, next) => {
  try {
    const earning = await DriverEarning.findById(req.params.id).populate('driver ride');
    if (!earning) {
      return res.status(404).json({ success: false, message: 'Earning record not found' });
    }
    res.status(200).json({ success: true, data: earning });
  } catch (error) {
    next(error);
  }
};
