const Vendor = require('../models/Vendor');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const Ride = require('../models/Ride');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

const registerVendor = async (req, res) => {
  try {
    let { name, email, phone, password, companyName } = req.body;

    if (!name || !email || !phone || !password || !companyName) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields',
      });
    }

    email = email.trim().toLowerCase();
    phone = phone.trim();

    const vendorExists = await Vendor.findOne({ $or: [{ email }, { phone }] });
    if (vendorExists) {
      return res.status(400).json({
        success: false,
        message: 'Vendor already exists',
      });
    }

    const vendor = await Vendor.create({
      name,
      email,
      phone,
      password,
      companyName,
    });

    const token = generateToken(vendor._id);

    res.status(201).json({
      success: true,
      message: 'Vendor registered successfully',
      token,
      vendor: {
        _id: vendor._id,
        name: vendor.name,
        email: vendor.email,
        phone: vendor.phone,
        companyName: vendor.companyName,
        totalDrivers: 0,
        totalVehicles: 0,
        createdAt: vendor.createdAt,
      },
    });
  } catch (error) {
    console.error('Vendor Registration Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const loginVendor = async (req, res) => {
  try {
    let { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    email = email.trim().toLowerCase();
    const vendor = await Vendor.findOne({ email }).select('+password');

    if (!vendor) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const isMatch = await vendor.comparePassword(password, vendor.password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const totalDrivers = await Driver.countDocuments();
    const totalVehicles = await Vehicle.countDocuments();

    const token = generateToken(vendor._id);

    res.status(200).json({
      success: true,
      message: 'Vendor logged in successfully',
      token,
      vendor: {
        _id: vendor._id,
        name: vendor.name,
        email: vendor.email,
        phone: vendor.phone,
        companyName: vendor.companyName,
        totalDrivers,
        totalVehicles,
        createdAt: vendor.createdAt,
      },
    });
  } catch (error) {
    console.error('Vendor Login Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getDashboard = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const totalDrivers = await Driver.countDocuments();
    const onlineDrivers = await Driver.countDocuments({ status: 'online' });
    const totalVehicles = await Vehicle.countDocuments();
    const onlineVehicles = totalVehicles;

    const totalRidesToday = await Ride.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow },
    });

    const completedRides = await Ride.countDocuments({
      status: 'completed',
    });

    const cancelledRides = await Ride.countDocuments({
      status: 'cancelled',
    });

    const completedRidesToday = await Ride.find({
      status: 'completed',
      createdAt: { $gte: today, $lt: tomorrow },
    });

    let totalEarnings = 0;
    completedRidesToday.forEach((ride) => {
      totalEarnings += ride.fare || 0;
    });

    const recentTrips = await Ride.find()
      .sort({ createdAt: -1 })
      .limit(10);

    res.status(200).json({
      totalRidesToday,
      totalEarnings,
      activeDrivers: onlineDrivers,
      onlineVehicles,
      completedRides,
      cancelledRides,
      recentTrips,
    });
  } catch (error) {
    console.error('Dashboard Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getDrivers = async (req, res) => {
  try {
    const drivers = await Driver.find().populate('user', 'name email mobile profilePic');
    res.status(200).json(drivers);
  } catch (error) {
    console.error('Get Drivers Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const addDriver = async (req, res) => {
  try {
    const driver = await Driver.create(req.body);
    res.status(201).json(driver);
  } catch (error) {
    console.error('Add Driver Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteDriver = async (req, res) => {
  try {
    await Driver.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Driver deleted' });
  } catch (error) {
    console.error('Delete Driver Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getVehicles = async (req, res) => {
  try {
    const vehicles = await Vehicle.find().populate('driver');
    res.status(200).json(vehicles);
  } catch (error) {
    console.error('Get Vehicles Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const addVehicle = async (req, res) => {
  try {
    const vehicle = await Vehicle.create(req.body);
    res.status(201).json(vehicle);
  } catch (error) {
    console.error('Add Vehicle Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteVehicle = async (req, res) => {
  try {
    await Vehicle.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: 'Vehicle deleted' });
  } catch (error) {
    console.error('Delete Vehicle Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getTrips = async (req, res) => {
  try {
    const trips = await Ride.find().sort({ createdAt: -1 });
    res.status(200).json(trips);
  } catch (error) {
    console.error('Get Trips Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getEarnings = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);

    const monthAgo = new Date(today);
    monthAgo.setMonth(monthAgo.getMonth() - 1);

    const allRides = await Ride.find({ status: 'completed' });
    const todayRides = await Ride.find({
      status: 'completed',
      createdAt: { $gte: today },
    });
    const weekRides = await Ride.find({
      status: 'completed',
      createdAt: { $gte: weekAgo },
    });
    const monthRides = await Ride.find({
      status: 'completed',
      createdAt: { $gte: monthAgo },
    });

    const totalEarnings = allRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const todayEarnings = todayRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const weeklyEarnings = weekRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const monthlyEarnings = monthRides.reduce((sum, r) => sum + (r.fare || 0), 0);

    res.status(200).json({
      totalEarnings,
      todayEarnings,
      weeklyEarnings,
      monthlyEarnings,
      vendorCommission: totalEarnings * 0.2,
      driverCommission: totalEarnings * 0.8,
      walletBalance: totalEarnings * 0.2,
    });
  } catch (error) {
    console.error('Get Earnings Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  registerVendor,
  loginVendor,
  getDashboard,
  getDrivers,
  addDriver,
  deleteDriver,
  getVehicles,
  addVehicle,
  deleteVehicle,
  getTrips,
  getEarnings,
};
