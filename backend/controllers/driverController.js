const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const Notification = require('../models/Notification');

const updateDriverProfile = async (req, res) => {
  try {
    console.log('updateDriverProfile - req.body:', req.body);
    console.log('updateDriverProfile - req.file:', req.file);
    
    const { name, mobile, vehicleType, vehicleNumber, address, bankName, accountHolderName, accountNumber, ifscCode, branchName, bankAccounts } = req.body;
    
    // Update User model
    const userUpdate = {};
    if (name) userUpdate.name = name;
    if (mobile) userUpdate.mobile = mobile;
    
    // Handle profile picture upload
    if (req.file) {
      // Construct the full URL for the uploaded file
      const protocol = req.protocol;
      const host = req.get('host');
      const profilePicUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
      userUpdate.profilePic = profilePicUrl;
      console.log('Profile pic URL:', profilePicUrl);
    }
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      userUpdate,
      { new: true, runValidators: true }
    );

    // Update Driver model
    const driverUpdate = {};
    if (vehicleType) driverUpdate.vehicleType = vehicleType;
    if (vehicleNumber) driverUpdate.vehicleNumber = vehicleNumber;
    if (address !== undefined) driverUpdate.address = address;
    if (bankName !== undefined) driverUpdate.bankName = bankName;
    if (accountHolderName !== undefined) driverUpdate.accountHolderName = accountHolderName;
    if (accountNumber !== undefined) driverUpdate.accountNumber = accountNumber;
    if (ifscCode !== undefined) driverUpdate.ifscCode = ifscCode;
    if (branchName !== undefined) driverUpdate.branchName = branchName;
    if (bankAccounts !== undefined) {
      if (Array.isArray(bankAccounts) && bankAccounts.length <= 3) {
        driverUpdate.bankAccounts = bankAccounts;
      }
    }
    
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

    // Backward compatibility: if old single fields exist and bankAccounts is empty, migrate to bankAccounts
    if (driver && (!driver.bankAccounts || driver.bankAccounts.length === 0)) {
      if (driver.bankName && driver.accountNumber) {
        driver.bankAccounts = [{
          bankName: driver.bankName,
          accountHolderName: driver.accountHolderName,
          accountNumber: driver.accountNumber,
          ifscCode: driver.ifscCode,
          branchName: driver.branchName
        }];
        await driver.save();
      }
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
          address: driver?.address || '',
          // For backward compatibility
          bankName: driver?.bankName || '',
          accountHolderName: driver?.accountHolderName || '',
          accountNumber: driver?.accountNumber || '',
          ifscCode: driver?.ifscCode || '',
          branchName: driver?.branchName || '',
          // New: Multiple bank accounts
          bankAccounts: driver?.bankAccounts || [],
          // Documents
          documents: driver?.documents || []
        },
      },
    });
  } catch (error) {
    console.error('updateDriverProfile error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const uploadDocument = async (req, res) => {
  try {
    console.log('uploadDocument - req.body:', req.body);
    console.log('uploadDocument - req.file:', req.file);
    
    const { title, category, expiryDate } = req.body;
    
    let documentUrl = '';
    if (req.file) {
      const protocol = req.protocol;
      const host = req.get('host');
      documentUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
    }

    let driver = await Driver.findOne({ user: req.user._id });
    if (!driver) {
      driver = await Driver.create({
        user: req.user._id,
        licenseNumber: 'TEMP-LICENSE-123'
      });
    }

    const newDocument = {
      title,
      category,
      url: documentUrl,
      status: 'Pending',
      uploadedAt: new Date(),
      expiryDate: expiryDate ? new Date(expiryDate) : undefined
    };

    driver.documents.push(newDocument);
    await driver.save();

    res.status(200).json({
      success: true,
      data: {
        document: newDocument,
        documents: driver.documents
      }
    });
  } catch (error) {
    console.error('uploadDocument error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const editDocument = async (req, res) => {
  try {
    console.log('editDocument - req.params:', req.params);
    console.log('editDocument - req.body:', req.body);
    console.log('editDocument - req.file:', req.file);
    
    const { docId } = req.params;
    const { title, category, expiryDate, status } = req.body;

    let documentUrl;
    if (req.file) {
      const protocol = req.protocol;
      const host = req.get('host');
      documentUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
    }

    const driver = await Driver.findOne({ user: req.user._id });
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }

    const docIndex = driver.documents.findIndex(doc => doc._id.toString() === docId);
    if (docIndex === -1) {
      return res.status(404).json({ success: false, message: 'Document not found' });
    }

    // Update the document
    if (title !== undefined) driver.documents[docIndex].title = title;
    if (category !== undefined) driver.documents[docIndex].category = category;
    if (documentUrl !== undefined) driver.documents[docIndex].url = documentUrl;
    if (expiryDate !== undefined) driver.documents[docIndex].expiryDate = expiryDate ? new Date(expiryDate) : undefined;
    if (status !== undefined) driver.documents[docIndex].status = status;

    await driver.save();

    res.status(200).json({
      success: true,
      data: {
        document: driver.documents[docIndex],
        documents: driver.documents
      }
    });
  } catch (error) {
    console.error('editDocument error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const deleteDocument = async (req, res) => {
  try {
    const { docId } = req.params;

    const driver = await Driver.findOne({ user: req.user._id });
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }

    const docIndex = driver.documents.findIndex(doc => doc._id.toString() === docId);
    if (docIndex === -1) {
      return res.status(404).json({ success: false, message: 'Document not found' });
    }

    driver.documents.splice(docIndex, 1);
    await driver.save();

    res.status(200).json({
      success: true,
      message: 'Document deleted successfully',
      data: {
        documents: driver.documents
      }
    });
  } catch (error) {
    console.error('deleteDocument error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const getDriverProfile = async (req, res) => {
    try {
      let driver = await Driver.findOne({ user: req.user._id });
      
      if (!driver) {
        console.log('Driver not found, creating new driver for user:', req.user._id);
        const uniqueTempLicense = `TEMP-LICENSE-${Date.now()}`;
        driver = await Driver.create({
          user: req.user._id,
          licenseNumber: uniqueTempLicense,
          vehicleType: 'Car',
          vehicleNumber: 'TN 01 AB 1234',
          address: '',
          bankName: '',
          accountHolderName: '',
          accountNumber: '',
          ifscCode: '',
          branchName: '',
        });
        console.log('New driver created:', driver._id);
      }
      
      const user = await User.findById(req.user._id);

      if (driver && (!driver.bankAccounts || driver.bankAccounts.length === 0)) {
        if (driver.bankName && driver.accountNumber) {
          driver.bankAccounts = [{
            bankName: driver.bankName,
            accountHolderName: driver.accountHolderName,
            accountNumber: driver.accountNumber,
            ifscCode: driver.ifscCode,
            branchName: driver.branchName
          }];
          await driver.save();
        }
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
            address: driver?.address || '',
            bankName: driver?.bankName || '',
            accountHolderName: driver?.accountHolderName || '',
            accountNumber: driver?.accountNumber || '',
            ifscCode: driver?.ifscCode || '',
            branchName: driver?.branchName || '',
            bankAccounts: driver?.bankAccounts || [],
            documents: driver?.documents || []
          },
        },
      });
    } catch (error) {
      console.error('getDriverProfile error:', error);
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
    const { licenseNumber, vehicleType, vehicleNumber, address, bankName, accountHolderName, accountNumber, ifscCode, branchName } = req.body;
    
    let driver = await Driver.findOne({ user: req.user._id });
    
    if (driver) {
      driver.licenseNumber = licenseNumber || driver.licenseNumber;
      driver.vehicleType = vehicleType || driver.vehicleType;
      driver.vehicleNumber = vehicleNumber || driver.vehicleNumber;
      if (address !== undefined) driver.address = address;
      if (bankName !== undefined) driver.bankName = bankName;
      if (accountHolderName !== undefined) driver.accountHolderName = accountHolderName;
      if (accountNumber !== undefined) driver.accountNumber = accountNumber;
      if (ifscCode !== undefined) driver.ifscCode = ifscCode;
      if (branchName !== undefined) driver.branchName = branchName;
      await driver.save();
    } else {
      driver = await Driver.create({
        user: req.user._id,
        licenseNumber: licenseNumber || 'TEMP-LICENSE-123',
        vehicleType: vehicleType || 'Car',
        vehicleNumber: vehicleNumber || 'TN 01 AB 1234',
        address: address || '',
        bankName: bankName || '',
        accountHolderName: accountHolderName || '',
        accountNumber: accountNumber || '',
        ifscCode: ifscCode || '',
        branchName: branchName || '',
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
    const driver = await Driver.findOne({ user: req.user._id });
    
    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }

    const rides = await Ride.find({ driver: driver._id })
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

module.exports = { updateDriverProfile, getDriverProfile, updateStatus, updateLocation, getEarnings, registerDriver, getDriverRideHistory, getNotifications, markNotificationAsRead, deleteNotification, markAllNotificationsAsRead, uploadDocument, editDocument, deleteDocument };