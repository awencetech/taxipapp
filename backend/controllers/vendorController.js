const Vendor = require('../models/Vendor');
const Driver = require('../models/Driver');
const Vehicle = require('../models/Vehicle');
const Ride = require('../models/Ride');
const User = require('../models/User');
const Notification = require('../models/Notification');
const jwt = require('jsonwebtoken');
const { getCache, setCache, deleteCache } = require('../utils/cache');
const sendEmail = require('../utils/emailService');

// In-memory OTP store (fallback for when Redis is not available)
const otpStore = new Map();

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendVendorOTP = async (req, res) => {
  try {
    let { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Please provide phone number',
      });
    }

    phone = phone.trim();
    const vendor = await Vendor.findOne({ phone });

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found with this phone number',
      });
    }

    const otp = generateOTP();
    const otpKey = `vendor_otp:${phone}`;
    const ttl = 300; // 5 minutes

    // Store OTP in cache/ memory
    try {
      await setCache(otpKey, otp, ttl);
    } catch (e) {
      otpStore.set(otpKey, { otp, expires: Date.now() + ttl * 1000 });
    }

    // For testing purposes, we'll return OTP in response (remove in production!)
    // In production, integrate with SMS service here
    console.log(`OTP for ${phone} is ${otp}`);

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      otp: process.env.NODE_ENV === 'production' ? undefined : otp,
    });
  } catch (error) {
    console.error('Send OTP Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const verifyVendorOTP = async (req, res) => {
  try {
    let { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Please provide phone number and OTP',
      });
    }

    phone = phone.trim();
    const otpKey = `vendor_otp:${phone}`;
    let storedOTP = null;

    // Check cache first, then in-memory
    storedOTP = await getCache(otpKey);
    if (!storedOTP) {
      const inMemory = otpStore.get(otpKey);
      if (inMemory && inMemory.expires > Date.now()) {
        storedOTP = inMemory.otp;
      }
    }

    if (!storedOTP || storedOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    const vendor = await Vendor.findOne({ phone });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    // Clear OTP from storage
    try {
      await deleteCache(otpKey);
    } catch (e) {}
    otpStore.delete(otpKey);

    const totalDrivers = await Driver.countDocuments();
    const totalVehicles = await Vehicle.countDocuments();
    const token = generateToken(vendor._id);

    res.status(200).json({
      success: true,
      message: 'Vendor logged in successfully via OTP',
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
    console.error('Verify OTP Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const registerVendor = async (req, res) => {
  try {
    let { name, email, phone, password, companyName, googleId } = req.body;

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
      googleId: googleId || undefined,
      role: 'sub_vendor',
      approvalStatus: 'pending',
      isApproved: false,
    });

    const token = generateToken(vendor._id);

    res.status(201).json({
      success: true,
      message: 'Vendor registered successfully, waiting for approval',
      token,
      vendor: {
        _id: vendor._id,
        name: vendor.name,
        email: vendor.email,
        phone: vendor.phone,
        companyName: vendor.companyName,
        role: vendor.role,
        approvalStatus: vendor.approvalStatus,
        isApproved: vendor.isApproved,
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
    let { email, phone, password, googleId } = req.body;

    // Check if we have valid credentials
    if ((!email && !phone) || (!password && !googleId)) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email/phone and password or Google ID',
      });
    }

    const query = {};
    if (email) {
      query.email = email.trim().toLowerCase();
    }
    if (phone) {
      query.phone = phone.trim();
    }

    const vendor = await Vendor.findOne(query).select('+password');

    if (!vendor) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Main vendor can always log in
    if (vendor.role !== 'main_vendor') {
      // Check if vendor is approved
      if (vendor.approvalStatus === 'declined') {
        return res.status(403).json({
          success: false,
          message: 'Your registration has been declined. Please contact support.',
          approvalStatus: 'declined',
        });
      }
      if (vendor.approvalStatus === 'pending' || !vendor.isApproved) {
        return res.status(403).json({
          success: false,
          message: 'Your account is pending approval. Please wait for the main vendor to approve.',
          approvalStatus: 'pending',
        });
      }
    }

    // Verify credentials
    if (password) {
      const isMatch = await vendor.comparePassword(password, vendor.password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
        });
      }
    } else if (googleId) {
      // Google login - check if googleId matches or if user exists with this email
      if (vendor.googleId && vendor.googleId !== googleId) {
        return res.status(401).json({
          success: false,
          message: 'Invalid Google credentials',
        });
      }
      // Set googleId if not set
      if (!vendor.googleId) {
        vendor.googleId = googleId;
        await vendor.save();
      }
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
        role: vendor.role,
        approvalStatus: vendor.approvalStatus,
        isApproved: vendor.isApproved,
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

const getPendingDrivers = async (req, res) => {
  try {
    const pendingDrivers = await Driver.find({ status: 'pending' });
    res.status(200).json({
      success: true,
      data: { drivers: pendingDrivers },
    });
  } catch (error) {
    console.error('Get Pending Drivers Error:', error);
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
    const onlineDrivers = await Driver.countDocuments({ rideStatus: 'online' });
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

    const pendingDrivers = await Driver.countDocuments({ status: 'pending' });
    const approvedDrivers = await Driver.countDocuments({ status: 'approved' });
    const rejectedDrivers = await Driver.countDocuments({ status: 'rejected' });
    const todayRegistrations = await Driver.countDocuments({
      createdAt: { $gte: today, $lt: tomorrow },
    });

    res.status(200).json({
      totalRidesToday,
      totalEarnings,
      activeDrivers: onlineDrivers,
      onlineVehicles,
      completedRides,
      cancelledRides,
      recentTrips,
      pendingDrivers,
      approvedDrivers,
      rejectedDrivers,
      todayRegistrations,
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
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    let query = { vendor: req.user?._id };
    
    // Also get drivers without vendor (unassigned, pending approval)
    const allDrivers = await Driver.find();
    
    // Process each driver with today's data
    const processedDrivers = await Promise.all(allDrivers.map(async (driver) => {
      const driverObj = driver.toObject();
      
      // Get today's trips and earnings
      const todayRides = await Ride.find({
        driver: driver._id,
        status: 'completed',
        createdAt: { $gte: today, $lt: tomorrow }
      });
      
      const todayTrips = todayRides.length;
      const todayEarnings = todayRides.reduce((sum, ride) => sum + (ride.fare || 0), 0);
      
      // Handle both old and new drivers
      let name, email, mobile, profilePic;
      if (driverObj.user) {
        name = driverObj.user.name;
        email = driverObj.user.email;
        mobile = driverObj.user.mobile;
        profilePic = driverObj.user.profilePic;
      } else {
        name = driverObj.name;
        email = driverObj.email;
        mobile = driverObj.mobile;
        profilePic = driverObj.profilePic;
      }
      
      return {
        ...driverObj,
        name,
        email,
        mobile,
        profilePic,
        todayTrips,
        todayEarnings
      };
    }));
    
    // Sort by today's earnings descending (highest first)
    processedDrivers.sort((a, b) => b.todayEarnings - a.todayEarnings);
    
    res.status(200).json(processedDrivers);
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
    const User = require('../models/User');
    const {
      name, email, mobile, password,
      licenseNumber, vehicleType, vehicleNumber,
      address,
    } = req.body;

    if (!name || !email || !mobile || !licenseNumber) {
      return res.status(400).json({
        success: false,
        message: 'name, email, mobile and licenseNumber are required',
      });
    }

    // Check duplicate email
    const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }

    // Check duplicate license
    const existingDriver = await Driver.findOne({ licenseNumber });
    if (existingDriver) {
      return res.status(400).json({ success: false, message: 'License number already registered' });
    }

    // Create user
    const user = await User.create({
      name,
      email: email.toLowerCase().trim(),
      mobile,
      password: password || Math.random().toString(36).slice(-8) + 'A1!',
      role: 'driver',
      isVerified: true,
    });

    // Create driver (auto-approved by vendor)
    const driver = await Driver.create({
      user: user._id,
      vendor: req.user?._id,
      licenseNumber,
      vehicleType: vehicleType || 'Car',
      vehicleNumber: vehicleNumber || '',
      address: address || '',
      isApproved: true,
    });

    const populatedDriver = await Driver.findById(driver._id)
      .populate('user', 'name email mobile profilePic');

    res.status(201).json(populatedDriver);
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

const approveDriver = async (req, res) => {
  try {
    let driver = await Driver.findByIdAndUpdate(
      req.params.id,
      { 
        isApproved: true, 
        vendor: req.user?._id, 
        status: 'approved', 
        accountStatus: 'approved',
        approvedBy: req.user?._id,
        approvedAt: new Date(),
        rejectionReason: null,
      },
      { new: true }
    );
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // Send notification to driver
    await Notification.create({
      driver: driver._id,
      title: 'Account Approved',
      message: 'Congratulations! Your driver account has been approved. You can now start accepting rides.',
      type: 'approval',
      data: { approvedBy: req.user?._id },
    });

    // Process driver for consistent response
    const driverObj = driver.toObject();
    let name, email, mobile, profilePic;
    if (driverObj.user) {
      name = driverObj.user.name;
      email = driverObj.user.email;
      mobile = driverObj.user.mobile;
      profilePic = driverObj.user.profilePic;
    } else {
      name = driverObj.name;
      email = driverObj.email;
      mobile = driverObj.mobile;
      profilePic = driverObj.profilePic;
    }
    
    const processedDriver = { ...driverObj, name, email, mobile, profilePic };
    res.status(200).json({ success: true, data: { driver: processedDriver } });
  } catch (error) {
    console.error('Approve Driver Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const rejectDriver = async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason) {
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required',
      });
    }

    let driver = await Driver.findByIdAndUpdate(
      req.params.id,
      { 
        isApproved: false, 
        status: 'rejected', 
        accountStatus: 'rejected',
        rejectionReason: rejectionReason,
      },
      { new: true }
    );
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // Send notification to driver
    await Notification.create({
      driver: driver._id,
      title: 'Account Rejected',
      message: `Your driver account has been rejected. Reason: ${rejectionReason}`,
      type: 'approval',
      data: { rejectionReason: rejectionReason },
    });

    // Process driver for consistent response
    const driverObj = driver.toObject();
    let name, email, mobile, profilePic;
    if (driverObj.user) {
      name = driverObj.user.name;
      email = driverObj.user.email;
      mobile = driverObj.user.mobile;
      profilePic = driverObj.user.profilePic;
    } else {
      name = driverObj.name;
      email = driverObj.email;
      mobile = driverObj.mobile;
      profilePic = driverObj.profilePic;
    }
    
    const processedDriver = { ...driverObj, name, email, mobile, profilePic };
    res.status(200).json({ success: true, data: { driver: processedDriver } });
  } catch (error) {
    console.error('Reject Driver Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getVehicles = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const { search, status, vehicleType, driverStatus, sortBy, page = 1, limit = 20 } = req.query;
    
    // Build query
    const query = {};
    
    // Status filter
    if (status && status !== 'all') {
      query.status = status;
    }
    
    // Vehicle type filter
    if (vehicleType && vehicleType !== 'all') {
      query.type = vehicleType;
    }

    let vehicles = await Vehicle.find(query)
      .populate({
        path: 'driver',
        populate: {
          path: 'user',
          select: 'name mobile profilePic'
        }
      });

    // Search
    if (search) {
      const searchLower = search.toLowerCase();
      vehicles = vehicles.filter(vehicle => {
        const matchesPlate = vehicle.plateNumber.toLowerCase().includes(searchLower);
        const matchesType = vehicle.type.toLowerCase().includes(searchLower);
        const matchesModel = vehicle.model.toLowerCase().includes(searchLower);
        
        if (vehicle.driver) {
          const matchesDriverName = vehicle.driver.user?.name?.toLowerCase().includes(searchLower);
          const matchesDriverId = vehicle.driver.driverId?.toLowerCase().includes(searchLower);
          const matchesDriverPhone = vehicle.driver.user?.mobile?.includes(searchLower);
          return matchesPlate || matchesType || matchesModel || matchesDriverName || matchesDriverId || matchesDriverPhone;
        }
        
        return matchesPlate || matchesType || matchesModel;
      });
    }

    // Sort
    if (sortBy === 'newest') {
      vehicles.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    } else if (sortBy === 'oldest') {
      vehicles.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    }

    // Process each vehicle with additional data
    const processedVehicles = await Promise.all(vehicles.map(async (vehicle) => {
      const vehicleObj = vehicle.toObject();
      
      // Get today's trips and earnings for this vehicle's driver
      let todayTrips = 0;
      let todayEarnings = 0;
      let lastRide = null;
      
      if (vehicle.driver) {
        const todayRides = await Ride.find({
          driver: vehicle.driver._id,
          status: 'completed',
          createdAt: { $gte: today, $lt: tomorrow }
        });
        
        todayTrips = todayRides.length;
        todayEarnings = todayRides.reduce((sum, ride) => sum + (ride.fare || 0), 0);
        
        // Get last ride
        const lastRideDoc = await Ride.findOne({
          driver: vehicle.driver._id
        }).sort({ createdAt: -1 });
        
        if (lastRideDoc) {
          lastRide = lastRideDoc.createdAt;
        }
      }
      
      // Driver status
      let driverStatus = 'offline';
      if (vehicle.driver) {
        if (vehicle.driver.isBusy) {
          driverStatus = 'on-trip';
        } else if (vehicle.driver.isOnline) {
          driverStatus = 'online';
        }
      }
      
      return {
        ...vehicleObj,
        driverName: vehicle.driver?.user?.name || 'Unassigned',
        driverId: vehicle.driver?.driverId || null,
        driverPhone: vehicle.driver?.user?.mobile || null,
        driverAvatar: vehicle.driver?.user?.profilePic || null,
        driverStatus,
        todayTrips,
        todayEarnings,
        lastRide,
        vehicleStatus: vehicle.status
      };
    }));

    // Driver status filter
    if (driverStatus && driverStatus !== 'all') {
      const processedVehiclesFiltered = processedVehicles.filter(v => v.driverStatus === driverStatus);
      res.status(200).json(processedVehiclesFiltered);
    } else {
      res.status(200).json(processedVehicles);
    }
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
    const { driver, model, plateNumber, color, type, year, brand, rcNumber, insuranceExpiry, pollutionExpiry, status } = req.body;
    const vehicle = await Vehicle.create({
      driver,
      model,
      plateNumber,
      color,
      type,
      year,
      brand,
      rcNumber,
      insuranceExpiry,
      pollutionExpiry,
      status,
    });
    
    const populatedVehicle = await Vehicle.findById(vehicle._id)
      .populate({
        path: 'driver',
        populate: {
          path: 'user',
          select: 'name mobile profilePic'
        }
      });
      
    res.status(201).json(populatedVehicle);
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
    const trips = await Ride.find()
      .populate('user', 'name email mobile profilePic')
      .sort({ createdAt: -1 });
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

    const allRides = await Ride.find({ status: 'completed' })
      .populate('user', 'name')
      .populate({
        path: 'driver',
        populate: { path: 'user', select: 'name' }
      })
      .sort({ createdAt: -1 });

    const todayRides = allRides.filter(r => r.createdAt >= today);
    const weekRides = allRides.filter(r => r.createdAt >= weekAgo);
    const monthRides = allRides.filter(r => r.createdAt >= monthAgo);

    const totalEarnings = allRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const todayEarnings = todayRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const weeklyEarnings = weekRides.reduce((sum, r) => sum + (r.fare || 0), 0);
    const monthlyEarnings = monthRides.reduce((sum, r) => sum + (r.fare || 0), 0);

    // Dynamic stats for payment management
    let pendingPayments = 0;
    let settledPayments = 0;
    
    allRides.forEach(ride => {
      if (ride.paymentStatus === 'completed') {
        settledPayments += ride.fare || 0;
      } else {
        pendingPayments += ride.fare || 0;
      }
    });

    const recentTransactions = allRides.map(ride => ({
      id: ride.rideId || ride._id.toString(),
      date: ride.createdAt.toISOString().split('T')[0],
      driver: ride.driver && ride.driver.user ? ride.driver.user.name : 'Unknown Driver',
      user: ride.user ? ride.user.name : 'Unknown User',
      type: 'Earning',
      amount: ride.fare || 0,
      status: ride.paymentStatus === 'completed' ? 'Settled' : 'Pending',
    }));

    res.status(200).json({
      totalEarnings,
      todayEarnings,
      weeklyEarnings,
      monthlyEarnings,
      vendorCommission: totalEarnings * 0.2,
      driverCommission: totalEarnings * 0.8,
      walletBalance: totalEarnings * 0.2,
      pendingPayments,
      settledPayments,
      driverPayouts: totalEarnings * 0.8,
      transactions: recentTransactions.slice(0, 50),
    });
  } catch (error) {
    console.error('Get Earnings Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const sendForgotPasswordOTP = async (req, res) => {
  try {
    let { contact } = req.body;

    if (!contact) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email or phone number',
      });
    }

    contact = contact.trim();

    // Find vendor by email or phone
    const query = contact.includes('@') 
      ? { email: contact.toLowerCase() } 
      : { phone: contact };

    const vendor = await Vendor.findOne(query);

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    const otp = generateOTP();
    const otpKey = `vendor_forgot_otp:${contact}`;
    const ttl = 300; // 5 minutes

    // Store OTP in cache/ memory
    try {
      await setCache(otpKey, otp, ttl);
    } catch (e) {
      otpStore.set(otpKey, { otp, expires: Date.now() + ttl * 1000 });
    }

    // If contact is email, send OTP via email
    if (contact.includes('@')) {
      try {
        await sendEmail({
          email: vendor.email,
          subject: 'Password Reset OTP - Taxi Nanban',
          message: `Hello ${vendor.name},\n\nYour OTP for password reset is: ${otp}\n\nThis OTP is valid for 5 minutes.\n\nIf you didn't request this, please ignore this email.\n\nBest regards,\nTaxi Nanban Team`,
        });
        console.log(`Forgot password OTP sent to email ${vendor.email}: ${otp}`);
      } catch (emailError) {
        console.error('Email sending error:', emailError);
        // If email fails, still proceed (for testing)
      }
    } else {
      // TODO: Add SMS service integration here for phone numbers
      console.log(`Forgot password OTP for phone ${contact} is ${otp}`);
    }

    res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      otp: process.env.NODE_ENV === 'production' ? undefined : otp,
    });
  } catch (error) {
    console.error('Send Forgot Password OTP Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const verifyForgotPasswordOTP = async (req, res) => {
  try {
    let { contact, otp } = req.body;

    if (!contact || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Please provide contact and OTP',
      });
    }

    contact = contact.trim();
    const otpKey = `vendor_forgot_otp:${contact}`;
    let storedOTP = null;

    // Check cache first, then in-memory
    storedOTP = await getCache(otpKey);
    if (!storedOTP) {
      const inMemory = otpStore.get(otpKey);
      if (inMemory && inMemory.expires > Date.now()) {
        storedOTP = inMemory.otp;
      }
    }

    if (!storedOTP || storedOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    // Find vendor to make sure they exist
    const query = contact.includes('@') 
      ? { email: contact.toLowerCase() } 
      : { phone: contact };

    const vendor = await Vendor.findOne(query);
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully',
    });
  } catch (error) {
    console.error('Verify Forgot Password OTP Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const resetPassword = async (req, res) => {
  try {
    let { contact, otp, newPassword } = req.body;

    if (!contact || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Please provide contact, OTP, and new password',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long',
      });
    }

    contact = contact.trim();
    const otpKey = `vendor_forgot_otp:${contact}`;
    let storedOTP = null;

    // Check cache first, then in-memory
    storedOTP = await getCache(otpKey);
    if (!storedOTP) {
      const inMemory = otpStore.get(otpKey);
      if (inMemory && inMemory.expires > Date.now()) {
        storedOTP = inMemory.otp;
      }
    }

    if (!storedOTP || storedOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
      });
    }

    // Find vendor
    const query = contact.includes('@') 
      ? { email: contact.toLowerCase() } 
      : { phone: contact };

    const vendor = await Vendor.findOne(query);
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    // Update password
    vendor.password = newPassword;
    await vendor.save();

    // Clear OTP from storage
    try {
      await deleteCache(otpKey);
    } catch (e) {}
    otpStore.delete(otpKey);

    res.status(200).json({
      success: true,
      message: 'Password reset successfully',
    });
  } catch (error) {
    console.error('Reset Password Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getAllVendors = async (req, res) => {
  try {
    const { search, status } = req.query;
    
    let query = {};
    
    // Status filter
    if (status && status !== 'all') {
      query.approvalStatus = status;
    }
    
    // Search filter
    if (search) {
      const searchLower = search.toLowerCase();
      query.$or = [
        { name: { $regex: searchLower, $options: 'i' } },
        { email: { $regex: searchLower, $options: 'i' } },
        { companyName: { $regex: searchLower, $options: 'i' } },
        { phone: { $regex: searchLower, $options: 'i' } },
      ];
    }
    
    const vendors = await Vendor.find(query).sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      vendors,
    });
  } catch (error) {
    console.error('Get All Vendors Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getDriverById = async (req, res) => {
  try {
    const driver = await Driver.findById(req.params.id);

    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // Process driver for consistent response
    const driverObj = driver.toObject();
    let name, email, mobile, profilePic;
    if (driverObj.user) {
      name = driverObj.user.name;
      email = driverObj.user.email;
      mobile = driverObj.user.mobile;
      profilePic = driverObj.user.profilePic;
    } else {
      name = driverObj.name;
      email = driverObj.email;
      mobile = driverObj.mobile;
      profilePic = driverObj.profilePic;
    }
    const processedDriver = { ...driverObj, name, email, mobile, profilePic };

    // Get active ride for this driver
    const activeRide = await Ride.findOne({
      driver: driver._id,
      status: {
        $in: ['accepted', 'driver_arriving', 'arrived', 'trip_started'],
      },
    }).populate('user', 'name mobile');

    res.status(200).json({
      driver: processedDriver,
      activeRide,
    });
  } catch (error) {
    console.error('Get Driver By ID Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const approveVendor = async (req, res) => {
  try {
    const { id } = req.params;
    const vendor = await Vendor.findByIdAndUpdate(
      id,
      { 
        isApproved: true, 
        approvalStatus: 'approved',
        approvedBy: req.user?._id,
        approvedAt: new Date(),
      },
      { new: true }
    );

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Vendor approved successfully',
      vendor,
    });
  } catch (error) {
    console.error('Approve Vendor Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const declineVendor = async (req, res) => {
  try {
    const { id } = req.params;
    const vendor = await Vendor.findByIdAndUpdate(
      id,
      { 
        isApproved: false, 
        approvalStatus: 'declined',
        declinedBy: req.user?._id,
        declinedAt: new Date(),
      },
      { new: true }
    );

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Vendor declined',
      vendor,
    });
  } catch (error) {
    console.error('Decline Vendor Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteVendor = async (req, res) => {
  try {
    const { id } = req.params;

    // Find the vendor first
    const vendor = await Vendor.findById(id);
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: 'Vendor not found',
      });
    }

    // Find all drivers assigned to this vendor
    const assignedDrivers = await Driver.find({ vendor: id });
    const numAssignedDrivers = assignedDrivers.length;

    // If there are assigned drivers, unassign them
    if (numAssignedDrivers > 0) {
      await Driver.updateMany(
        { vendor: id },
        { 
          $set: { 
            vendor: null, 
            vendorStatus: 'Unassigned' 
          } 
        }
      );
    }

    // TODO: Handle fleet relationships (if any) once fleet model is defined

    // Delete the vendor
    await Vendor.findByIdAndDelete(id);

    // Log the deletion
    console.log(`Vendor deleted: ID=${vendor._id}, Name=${vendor.name}, Deleted by=${req.user?._id || 'unknown'}, Time=${new Date().toISOString()}`);

    res.status(200).json({
      success: true,
      message: 'Vendor deleted successfully',
      numDriversUnassigned: numAssignedDrivers,
    });
  } catch (error) {
    console.error('Delete Vendor Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getVendorNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ vendor: req.user._id })
      .sort('-createdAt');
    const unreadCount = notifications.filter(n => !n.isRead).length;
    res.status(200).json({ success: true, data: { notifications, unreadCount } });
  } catch (error) {
    console.error('Get Vendor Notifications Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const suspendDriver = async (req, res) => {
  try {
    let driver = await Driver.findByIdAndUpdate(
      req.params.id,
      { 
        accountStatus: 'suspended', 
        status: 'suspended',
        isOnline: false,
        isBusy: false
      },
      { new: true }
    );
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // Send notification
    await Notification.create({
      driver: driver._id,
      title: 'Account Suspended',
      message: 'Your driver account has been suspended by the vendor.',
      type: 'status',
    });

    res.status(200).json({ success: true, data: { driver } });
  } catch (error) {
    console.error('Suspend Driver Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const activateDriver = async (req, res) => {
  try {
    let driver = await Driver.findByIdAndUpdate(
      req.params.id,
      { 
        accountStatus: 'approved', 
        status: 'approved',
        isApproved: true
      },
      { new: true }
    );
    
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // Send notification
    await Notification.create({
      driver: driver._id,
      title: 'Account Activated',
      message: 'Your driver account has been activated. You can now start accepting rides.',
      type: 'status',
    });

    res.status(200).json({ success: true, data: { driver } });
  } catch (error) {
    console.error('Activate Driver Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const updateDriver = async (req, res) => {
  try {
    const driverId = req.params.id;
    const updateData = req.body;

    // Remove sensitive fields
    delete updateData._id;
    delete updateData.__v;

    let driver = await Driver.findById(driverId);
    if (!driver) {
      return res.status(404).json({
        success: false,
        message: 'Driver not found',
      });
    }

    // If driver has linked user, update user fields
    if (driver.user) {
      const userUpdate = {};
      if (updateData.name) userUpdate.name = updateData.name;
      if (updateData.email) userUpdate.email = updateData.email;
      if (updateData.mobile) userUpdate.mobile = updateData.mobile;
      if (updateData.profilePic) userUpdate.profilePic = updateData.profilePic;
      
      if (Object.keys(userUpdate).length > 0) {
        await User.findByIdAndUpdate(driver.user, userUpdate);
      }
    }

    // Update driver fields
    driver = await Driver.findByIdAndUpdate(driverId, updateData, { new: true });
    
    res.status(200).json({ success: true, data: { driver } });
  } catch (error) {
    console.error('Update Driver Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = {
  registerVendor,
  loginVendor,
  sendVendorOTP,
  verifyVendorOTP,
  sendForgotPasswordOTP,
  verifyForgotPasswordOTP,
  resetPassword,
  getDashboard,
  getDrivers,
  getDriverById,
  addDriver,
  deleteDriver,
  approveDriver,
  rejectDriver,
  suspendDriver,
  activateDriver,
  updateDriver,
  getVehicles,
  addVehicle,
  deleteVehicle,
  getTrips,
  getEarnings,
  getAllVendors,
  approveVendor,
  declineVendor,
  deleteVendor,
  getPendingDrivers,
  getVendorNotifications,
};
