const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const Notification = require('../models/Notification');

const updateDriverProfile = async (req, res) => {
  try {
    const { name, mobile, profilePic, vehicleType, vehicleNumber } = req.body;
    
    // Update User model
    const userUpdate = {};
    if (name) userUpdate.name = name;
    if (mobile) userUpdate.mobile = mobile;
    if (profilePic) userUpdate.profilePic = profilePic;
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      userUpdate,
      { new: true, runValidators: true }
    );

    // Update Driver model
    const driverUpdate = {};
    if (vehicleType) driverUpdate.vehicleType = vehicleType;
    if (vehicleNumber) driverUpdate.vehicleNumber = vehicleNumber;
    
    let driver = await Driver.findOne({ user: req.user._id });
    if (!driver) {
      driver = await Driver.create({
        user: req.user._id,
        ...driverUpdate,
        licenseNumber: 'TEMP-LICENSE-123'
      });
    } else {
      driver = await Driver.findOneAndUpdate(
        { user: req.user._id },
        driverUpdate,
        { new: true }
      );
    }

    res.status(200).json({
      success: true,
      data: {
        user: {
          _id: user._id,
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          profilePic: user.profilePic,
          isOnline: driver?.isOnline || false,
          vehicleType: driver?.vehicleType || 'Car',
          vehicleNumber: driver?.vehicleNumber || 'TN 01 AB 1234',
          ratings: driver?.ratings || 5.0,
        },
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getDriverProfile = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });
    const user = await User.findById(req.user._id);

    res.status(200).json({
      success: true,
      data: {
        user: {
          _id: user._id,
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          profilePic: user.profilePic,
          isOnline: driver?.isOnline || false,
          vehicleType: driver?.vehicleType || 'Car',
          vehicleNumber: driver?.vehicleNumber || 'TN 01 AB 1234',
          ratings: driver?.ratings || 5.0,
        },
      },
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const updateStatus = async (req, res) => {
  try {
    const { isOnline, status } = req.body;
    const driver = await Driver.findOneAndUpdate(
      { user: req.user._id },
      { isOnline, status },
      { new: true }
    );
    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const updateLocation = async (req, res) => {
  try {
    const { coordinates } = req.body; // [lng, lat]
    const driver = await Driver.findOneAndUpdate(
      { user: req.user._id },
      { currentLocation: { coordinates } },
      { new: true }
    );
    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getEarnings = async (req, res) => {
  try {
    const driver = await Driver.findOne({ user: req.user._id });
    res.status(200).json({
      status: 'success',
      data: {
        totalEarnings: driver?.totalEarnings || 0,
        ratings: driver?.ratings || 5.0,
        numReviews: driver?.numReviews || 0,
      },
    });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const registerDriver = async (req, res) => {
  try {
    const { licenseNumber, vehicleType, vehicleNumber } = req.body;
    
    let driver = await Driver.findOne({ user: req.user._id });
    
    if (driver) {
      driver.licenseNumber = licenseNumber || driver.licenseNumber;
      driver.vehicleType = vehicleType || driver.vehicleType;
      driver.vehicleNumber = vehicleNumber || driver.vehicleNumber;
      await driver.save();
    } else {
      driver = await Driver.create({
        user: req.user._id,
        licenseNumber: licenseNumber || 'TEMP-LICENSE-123',
        vehicleType: vehicleType || 'Car',
        vehicleNumber: vehicleNumber || 'TN 01 AB 1234',
      });
    }

    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getDriverRideHistory = async (req, res) => {
  // Trigger nodemon
  try {
    // For testing, return all rides without requiring driver record
    const rides = await Ride.find()
      .populate('user')
      .sort('-createdAt');
    
    res.status(200).json({ success: true, results: rides.length, data: { rides } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ user: req.user._id })
      .sort('-createdAt');
    const unreadCount = notifications.filter(n => !n.isRead).length;
    res.status(200).json({ success: true, data: { notifications, unreadCount } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const markNotificationAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const notification = await Notification.findByIdAndUpdate(
      id,
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.status(200).json({ success: true, data: { notification } });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    await Notification.findByIdAndDelete(id);
    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const markAllNotificationsAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    res.status(200).json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = { updateDriverProfile, getDriverProfile, updateStatus, updateLocation, getEarnings, registerDriver, getDriverRideHistory, getNotifications, markNotificationAsRead, deleteNotification, markAllNotificationsAsRead };
