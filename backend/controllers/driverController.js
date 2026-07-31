const Driver = require('../models/Driver');
const Ride = require('../models/Ride');
const Vehicle = require('../models/Vehicle');
const User = require('../models/User');
const Notification = require('../models/Notification');
const jwt = require('jsonwebtoken');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

// Google Login for Drivers
const googleLogin = async (req, res) => {
  try {
    const { email, googleUid, name, photo, idToken, accessToken } = req.body;

    console.log('Google Login Request:', { email, googleUid });

    // Find driver by googleId first, then email
    let driver = await Driver.findOne({ googleId: googleUid });
    if (!driver && email) {
      driver = await Driver.findOne({ email });
    }

    if (!driver) {
      // Auto-create a new pending driver
      console.log('Driver not found, creating pending driver for:', email);
      driver = await Driver.create({
        name: name || email.split('@')[0],
        email: email,
        googleId: googleUid,
        profilePic: photo,
        status: 'pending',
        approvalStatus: 'pending',
        accountStatus: 'pending',
        isApproved: false,
      });

      // Create notification for driver
      await Notification.create({
        driver: driver._id,
        title: 'Registration Submitted',
        message: 'Your driver registration has been submitted successfully. Waiting for vendor approval.',
        type: 'approval',
        data: { driverId: driver.driverId },
      });

      // Notify vendors
      const Vendor = require('../models/Vendor');
      const vendors = await Vendor.find();
      for (let vendor of vendors) {
        await Notification.create({
          vendor: vendor._id,
          title: 'New Driver Registration',
          message: `New driver ${driver.name} has registered for approval.`,
          type: 'approval',
          data: { driverId: driver._id },
        });
      }
    }

    // If driver exists, update googleId if not present
    if (!driver.googleId && googleUid) {
      driver.googleId = googleUid;
      await driver.save();
    }

    // Determine approval status
    let approvalStatus;
    if (driver.status === 'approved' || driver.approvalStatus === 'approved' || driver.isApproved === true) {
      approvalStatus = 'APPROVED';
    } else if (driver.status === 'rejected' || driver.approvalStatus === 'rejected') {
      approvalStatus = 'REJECTED';
    } else {
      approvalStatus = 'PENDING';
    }

    console.log('Driver approval status:', approvalStatus);

    if (approvalStatus === 'APPROVED') {
      const token = generateToken(driver._id);
      return res.status(200).json({
        success: true,
        driver,
        approvalStatus,
        token,
      });
    } else {
      return res.status(200).json({
        success: false,
        status: approvalStatus,
        rejectionReason: driver.rejectionReason,
        googleData: {
          email: email,
          googleId: googleUid,
          name: name,
          photo: photo
        }
      });
    }
  } catch (error) {
    console.error('Google Login Error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
};

const registerPendingDriver = async (req, res) => {
  try {
    const { name, lastName, email, mobile, vehicleType, vehicleNumber, firebaseUid, googleId, countryCode, photoURL, loginMethod } = req.body;
    let driver = null;

    if (firebaseUid) {
      driver = await Driver.findOne({ firebaseUid });
    } else if (googleId) {
      driver = await Driver.findOne({ googleId });
    } else if (email) {
      driver = await Driver.findOne({ email });
    } else if (mobile) {
      driver = await Driver.findOne({ mobile });
    }

    if (driver) {
      driver.name = name || driver.name;
      driver.lastName = lastName || driver.lastName;
      driver.email = email || driver.email;
      driver.vehicleType = vehicleType || driver.vehicleType;
      driver.vehicleNumber = vehicleNumber || driver.vehicleNumber;
      if (googleId) driver.googleId = googleId;
      if (photoURL) driver.profilePic = photoURL;
      driver.status = 'pending';
      driver.approvalStatus = 'pending';
      driver.accountStatus = 'pending';
      driver.isApproved = false;
      driver.rejectionReason = null;
      await driver.save();
    } else {
      driver = await Driver.create({
        name,
        lastName,
        email,
        mobile,
        firebaseUid,
        googleId,
        profilePic: photoURL || 'default-profile.png',
        vehicleType,
        vehicleNumber,
        status: 'pending',
        approvalStatus: 'pending',
        accountStatus: 'pending',
        isApproved: false,
      });
    }

    // Create a notification for the driver
    await Notification.create({
      driver: driver._id,
      title: 'Registration Submitted',
      message: 'Your driver registration has been submitted successfully. Waiting for vendor approval.',
      type: 'approval',
      data: { driverId: driver.driverId },
    });

    // Get all vendors and send them notification
    const Vendor = require('../models/Vendor');
    const vendors = await Vendor.find();
    for (let vendor of vendors) {
      await Notification.create({
        vendor: vendor._id,
        title: 'New Driver Registration',
        message: `New driver ${name} has registered for approval.`,
        type: 'approval',
        data: { driverId: driver._id },
      });
    }

    res.status(200).json({
      success: true,
      data: { driver },
    });
  } catch (error) {
    console.error('Register Pending Driver Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getDriverStatus = async (req, res) => {
  try {
    let driver;
    if (req.user?.role === 'driver' && req.user?.driverId) {
      driver = await Driver.findById(req.user._id);
    } else if (req.params?.driverId) {
      driver = await Driver.findOne({ driverId: req.params.driverId });
    } else {
      const { firebaseUid, googleId, mobile } = req.query;
      if (firebaseUid) {
        driver = await Driver.findOne({ firebaseUid });
      } else if (googleId) {
        driver = await Driver.findOne({ googleId });
      } else if (mobile) {
        driver = await Driver.findOne({ mobile });
      }
    }

    if (!driver) {
      return res.status(404).json({ success: false, message: 'Driver not found' });
    }

    // Determine the correct approval status checking all relevant fields
    let approvalStatus;
    if (driver.status === 'approved' || driver.approvalStatus === 'approved' || driver.isApproved === true) {
      approvalStatus = 'APPROVED';
    } else if (driver.status === 'rejected' || driver.approvalStatus === 'rejected') {
      approvalStatus = 'REJECTED';
    } else {
      approvalStatus = 'PENDING';
    }

    res.status(200).json({
      success: true,
      data: {
        driver: driver,
        approvalStatus: approvalStatus,
        rejectionReason: driver.rejectionReason,
      },
    });
  } catch (error) {
    console.error('Get Driver Status Error:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const updateDriverProfile = async (req, res) => {
  try {
    console.log('updateDriverProfile - req.body:', req.body);
    console.log('updateDriverProfile - req.file:', req.file);
    
    const { name, mobile, vehicleType, vehicleNumber, address, bankName, accountHolderName, accountNumber, ifscCode, branchName, bankAccounts } = req.body;
    
    // Check if req.user is a Driver or User
    let driver, user;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
      user = driver;
    } else {
      // Old user-linked Driver
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
      
      user = await User.findByIdAndUpdate(
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
      
      driver = await Driver.findOne({ user: req.user._id });
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
          driverId: driver?.driverId || '',
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

    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
      if (!driver) {
        driver = await Driver.create({
          user: req.user._id,
          licenseNumber: 'TEMP-LICENSE-123'
        });
      }
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

    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
    }
    
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

    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
    }
    
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
      let driver, user;
      if (req.user.role === 'driver' && req.user.driverId) {
        // New standalone Driver
        driver = await Driver.findById(req.user._id);
        user = driver;
      } else {
        // Old user-linked Driver
        driver = await Driver.findOne({ user: req.user._id });
      
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
        
        user = await User.findById(req.user._id);
      }
      
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

      // Calculate driver stats from rides
      const rides = await Ride.find({ driver: driver._id });
      
      // Total trips: all rides
      const totalTrips = rides.length;
      
      // Completed trips count
      const completedTrips = rides.filter(r => r.status === 'completed').length;
      
      // Acceptance rate: (accepted rides) / (total received requests). We'll assume all rides are requests.
      // Let's define acceptance rate as (rides not cancelled by driver) / total rides.
      // Or, if we have accepted status:
      const acceptedRides = rides.filter(r => r.status !== 'cancelled' || r.cancellationReason !== 'Driver cancelled');
      const acceptanceRate = totalTrips > 0 ? Math.round((acceptedRides.length / totalTrips) * 100) : 100;
      
      // On-time percentage: Let's assume 95% as default, or calculate if we have timestamps
      const onTimePercentage = 96;
      
      // Member since
      const memberSince = driver.createdAt || new Date();

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
          driverId: driver?.driverId || '',
          bankName: driver?.bankName || '',
          accountHolderName: driver?.accountHolderName || '',
          accountNumber: driver?.accountNumber || '',
          ifscCode: driver?.ifscCode || '',
          branchName: driver?.branchName || '',
          bankAccounts: driver?.bankAccounts || [],
          documents: driver?.documents || [],
          // Stats
          totalTrips: totalTrips,
          completedTrips: completedTrips,
          acceptanceRate: acceptanceRate,
          onTimePercentage: onTimePercentage,
          memberSince: memberSince
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
    const normalizedStatus = status || (isOnline ? 'available' : 'offline');
    const updatePayload = {
      isOnline,
      isAvailable: Boolean(isOnline),
      status: normalizedStatus,
      lastSeen: new Date(),
    };

    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findByIdAndUpdate(
        req.user._id,
        updatePayload,
        { new: true }
      );
    } else {
      // Old user-linked Driver
      driver = await Driver.findOneAndUpdate(
        { user: req.user._id },
        updatePayload,
        { new: true }
      );
    }
    
    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const updateLocation = async (req, res) => {
  try {
    const { coordinates } = req.body; // [lng, lat]
    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findByIdAndUpdate(
        req.user._id,
        { currentLocation: { coordinates } },
        { new: true }
      );
    } else {
      // Old user-linked Driver
      driver = await Driver.findOneAndUpdate(
        { user: req.user._id },
        { currentLocation: { coordinates } },
        { new: true }
      );
    }
    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getEarnings = async (req, res) => {
  try {
    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
    }
    
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
    
    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
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
        // Ensure driver is in pending state after registration
        driver.isApproved = false;
        driver.approvalStatus = 'pending';
        driver.status = 'pending';
        driver.accountStatus = 'pending';
        await driver.save();
      }
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
      
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
        // Ensure driver is in pending state after registration
        driver.isApproved = false;
        driver.approvalStatus = 'pending';
        driver.status = 'pending';
        driver.accountStatus = 'pending';
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
          isApproved: false,
          approvalStatus: 'pending',
          status: 'pending',
          accountStatus: 'pending',
        });
      }
    }

    res.status(200).json({ status: 'success', data: { driver } });
  } catch (error) {
    res.status(400).json({ status: 'error', message: error.message });
  }
};

const getDriverRideHistory = async (req, res) => {
  // Trigger nodemon
  try {
    let driver;
    if (req.user.role === 'driver' && req.user.driverId) {
      // New standalone Driver
      driver = await Driver.findById(req.user._id);
    } else {
      // Old user-linked Driver
      driver = await Driver.findOne({ user: req.user._id });
    }
    
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
    let notifications = [];
    if (req.user?.role === 'driver') {
      notifications = await Notification.find({
        $or: [
          { driver: req.user._id },
          { user: req.user._id },
        ],
      }).sort('-createdAt');
    } else {
      notifications = await Notification.find({ user: req.user._id })
        .sort('-createdAt');
    }
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
    if (req.user?.role === 'driver') {
      await Notification.updateMany(
        {
          $or: [
            { driver: req.user._id },
            { user: req.user._id },
          ],
          isRead: false,
        },
        { isRead: true }
      );
    } else {
      await Notification.updateMany({ user: req.user._id, isRead: false }, { isRead: true });
    }
    res.status(200).json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = { 
  updateDriverProfile, 
  getDriverProfile, 
  updateStatus, 
  updateLocation, 
  getEarnings, 
  registerDriver, 
  getDriverRideHistory, 
  getNotifications, 
  markNotificationAsRead, 
  deleteNotification, 
  markAllNotificationsAsRead, 
  uploadDocument, 
  editDocument, 
  deleteDocument,
  registerPendingDriver,
  getDriverStatus,
  googleLogin
};
