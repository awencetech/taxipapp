const User = require('../models/User');
const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const Payment = require('../models/Payment');
const Settings = require('../models/Settings');

const getAllUsers = async (req, res) => {
  try {
    const users = await User.find({ role: 'user' });
    res.status(200).json({ success: true, results: users.length, data: { users } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getAllDrivers = async (req, res) => {
  try {
    const drivers = await Driver.find().populate('user vehicle');
    res.status(200).json({ success: true, results: drivers.length, data: { drivers } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const approveDriver = async (req, res) => {
  try {
    const driver = await Driver.findByIdAndUpdate(
      req.params.id,
      { isApproved: true },
      { new: true }
    );
    res.status(200).json({ success: true, data: { driver } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: 'user' });
    const totalDrivers = await Driver.countDocuments();
    const totalRides = await Ride.countDocuments();
    const completedRides = await Ride.countDocuments({ status: 'completed' });
    
    const revenue = await Ride.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$fare' } } },
    ]);

    res.status(200).json({
      success: true,
      data: {
        totalUsers,
        totalDrivers,
        totalRides,
        completedRides,
        totalRevenue: revenue.length > 0 ? revenue[0].total : 0,
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getAllRides = async (req, res) => {
  try {
    const rides = await Ride.find().populate('user driver');
    res.status(200).json({ success: true, results: rides.length, data: { rides } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getAllPayments = async (req, res) => {
  try {
    const payments = await Payment.find().populate('user ride');
    
    // Summary earnings
    const earningsSummary = await Payment.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.status(200).json({ 
      success: true, 
      results: payments.length, 
      data: { 
        payments,
        totalEarnings: earningsSummary.length > 0 ? earningsSummary[0].total : 0
      } 
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getSettings = async (req, res) => {
  try {
    let settings = await Settings.findOne();
    if (!settings) {
      // Create default settings if not exists
      settings = await Settings.create({
        adminName: 'Admin',
        adminEmail: 'admin@taxinanban.com',
        adminPhone: '1234567890'
      });
    }
    res.status(200).json({ success: true, data: { settings } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const updateSettings = async (req, res) => {
  try {
    let settings = await Settings.findOne();
    if (!settings) {
      settings = await Settings.create(req.body);
    } else {
      settings = await Settings.findByIdAndUpdate(settings._id, req.body, {
        new: true,
        runValidators: true
      });
    }
    res.status(200).json({ success: true, data: { settings } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = { getAllUsers, getAllDrivers, approveDriver, getStats, getAllRides, getAllPayments, getSettings, updateSettings };
