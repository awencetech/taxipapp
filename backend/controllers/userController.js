const User = require('../models/User');
const Ride = require('../models/Ride');
const Payment = require('../models/Payment');

const getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.status(200).json({ success: true, data: { user } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { name, email, mobile } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, email, mobile },
      { new: true, runValidators: true }
    );
    res.status(200).json({ success: true, data: { user } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const addFavoriteLocation = async (req, res) => {
  try {
    const { name, address, coordinates } = req.body;
    const user = await User.findById(req.user._id);
    
    user.favoriteLocations.push({
      name,
      address,
      location: { coordinates },
    });
    
    await user.save();
    res.status(200).json({ success: true, data: { user } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getRideHistory = async (req, res) => {
  try {
    const rides = await Ride.find({ user: req.user._id })
      .populate('driver')
      .sort('-createdAt');
    res.status(200).json({ success: true, results: rides.length, data: { rides } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getPaymentHistory = async (req, res) => {
  try {
    const payments = await Payment.find({ user: req.user._id })
      .populate('ride')
      .sort('-createdAt');
    res.status(200).json({ success: true, results: payments.length, data: { payments } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = { getMe, updateProfile, addFavoriteLocation, getRideHistory, getPaymentHistory };
