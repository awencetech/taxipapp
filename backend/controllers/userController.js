const User = require('../models/User');
const Ride = require('../models/Ride');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');

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

// Notification endpoints
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

// Address endpoints
const getAddresses = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    res.status(200).json({ 
      success: true, 
      data: user.addresses 
    });
  } catch (error) {
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const addAddress = async (req, res) => {
  try {
    const { type, label, address, landmark, city, state, pincode, latitude, longitude } = req.body;
    const user = await User.findById(req.user._id);
    
    // If this is the first address, make it default
    const isDefault = user.addresses.length === 0;
    
    user.addresses.push({
      type,
      label,
      address,
      landmark,
      city,
      state,
      pincode,
      latitude: latitude || 0.0,
      longitude: longitude || 0.0,
      isDefault
    });
    
    await user.save();
    res.status(200).json({ 
      success: true, 
      data: user.addresses 
    });
  } catch (error) {
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const updateAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const user = await User.findById(req.user._id);
    
    const addressIndex = user.addresses.findIndex(addr => addr._id.toString() === id);
    if (addressIndex === -1) {
      return res.status(404).json({ 
        success: false, 
        message: 'Address not found' 
      });
    }
    
    // Update the address
    user.addresses[addressIndex] = { 
      ...user.addresses[addressIndex].toObject(), 
      ...updateData 
    };
    
    await user.save();
    res.status(200).json({ 
      success: true, 
      data: user.addresses 
    });
  } catch (error) {
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const deleteAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(req.user._id);
    
    user.addresses = user.addresses.filter(addr => addr._id.toString() !== id);
    
    // If the deleted address was default, set another one as default
    if (user.addresses.length > 0 && !user.addresses.some(addr => addr.isDefault)) {
      user.addresses[0].isDefault = true;
    }
    
    await user.save();
    res.status(200).json({ 
      success: true, 
      data: user.addresses 
    });
  } catch (error) {
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const setDefaultAddress = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(req.user._id);
    
    // Set all addresses to not default first
    user.addresses.forEach(addr => {
      addr.isDefault = addr._id.toString() === id;
    });
    
    await user.save();
    res.status(200).json({ 
      success: true, 
      data: user.addresses 
    });
  } catch (error) {
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

module.exports = { 
  getMe, 
  updateProfile, 
  addFavoriteLocation, 
  getRideHistory, 
  getPaymentHistory,
  getNotifications,
  markNotificationAsRead,
  deleteNotification,
  markAllNotificationsAsRead,
  getAddresses,
  addAddress,
  updateAddress,
  deleteAddress,
  setDefaultAddress
};
