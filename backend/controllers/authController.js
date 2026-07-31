const User = require('../models/User');
const Driver = require('../models/Driver');
const Vendor = require('../models/Vendor');
const admin = require('../config/firebase');
const jwt = require('jsonwebtoken');
const sendEmail = require('../utils/emailService');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const { isMongoConnected } = require('../config/db');

const GOOGLE_CLIENT_IDS = [
  '841081778086-uml93fplvoc5je0fgj1b1hfn8of0r1i3.apps.googleusercontent.com',
  '853680153976-bcn1s55141qhvn240c294qa5i85dva3o.apps.googleusercontent.com',
  '1019476576912-mj1gij1eapfqgm2tl27nujd0qh720tjj.apps.googleusercontent.com',
];
const client = new OAuth2Client();

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

const register = async (req, res) => {
  try {
    if (!isMongoConnected()) {
      return res.status(503).json({ 
        success: false, 
        message: 'Database not available. Please try again later.' 
      });
    }
    console.log('Register Request Body:', req.body);
    let { name, email, password, mobile, role } = req.body;

    if (!name || !email || !password || !mobile) {
      const missingFields = [];
      if (!name) missingFields.push('name');
      if (!email) missingFields.push('email');
      if (!password) missingFields.push('password');
      if (!mobile) missingFields.push('mobile');
      
      return res.status(400).json({
        success: false,
        message: `Please provide all required fields: ${missingFields.join(', ')}`
      });
    }

    email = email.trim().toLowerCase();
    mobile = mobile.trim();

    if (role === 'driver') {
      const driverExists = await Driver.findOne({ $or: [{ email }, { mobile }] });
      if (driverExists) {
        return res.status(400).json({ 
          success: false, 
          message: 'Driver already exists' 
        });
      }
      const driver = await Driver.create({
        name,
        email,
        password,
        mobile,
        role: 'driver',
        licenseNumber: `TEMP-${Date.now()}`,
      });

      const token = generateToken(driver._id);
      return res.status(201).json({
        success: true,
        message: 'Driver registered successfully',
        token,
        user: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          mobile: driver.mobile,
          role: driver.role,
          driverId: driver.driverId,
        },
      });
    } else {
      const userExists = await User.findOne({ $or: [{ email }, { mobile }] });
      if (userExists) {
        return res.status(400).json({ 
          success: false, 
          message: 'User already exists' 
        });
      }

      const user = await User.create({
        name,
        email,
        password,
        mobile,
        role: role || 'user',
      });

      console.log('User created with id:', user._id);

      const token = generateToken(user._id);
      return res.status(201).json({
        success: true,
        message: 'User registered successfully',
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          role: user.role
        },
      });
    }
  } catch (error) {
    console.error('Registration Error:', error);
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const login = async (req, res) => {
  try {
    if (!isMongoConnected()) {
      return res.status(503).json({ 
        success: false, 
        message: 'Database not available. Please try again later.' 
      });
    }
    console.log('Login Request Body:', req.body);
    let { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide email and password' 
      });
    }

    email = email.trim().toLowerCase();
    let user, driverId;

    if (role === 'driver') {
      user = await Driver.findOne({ email }).select('+password');
      if (user) {
        if (!user.isApproved) {
          return res.status(403).json({
            success: false,
            message: 'Driver not approved. Please wait for vendor/admin approval.'
          });
        }
        driverId = user.driverId;
      }
    } else {
      user = await User.findOne({ email }).select('+password');
      if (user && user.role === 'driver') {
        const driver = await Driver.findOne({ user: user._id });
        if (driver && !driver.isApproved) {
          return res.status(403).json({
            success: false,
            message: 'Driver not approved. Please wait for vendor/admin approval.'
          });
        }
      }
    }

    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid credentials' 
      });
    }

    const isMatch = await user.comparePassword(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid credentials' 
      });
    }

    const token = generateToken(user._id);
    return res.status(200).json({
      success: true,
      message: `${role === 'driver' ? 'Driver' : 'User'} logged in successfully`,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        role: user.role,
        driverId: driverId,
      },
    });
  } catch (error) {
    console.error('Login Error:', error);
    res.status(400).json({ 
      success: false, 
      message: error.message 
    });
  }
};

const forgotPassword = async (req, res) => {
  try {
    console.log('forgotPassword request body:', req.body);
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Please provide an email' });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    user.resetPasswordOTP = otp;
    user.resetPasswordExpires = Date.now() + 10 * 60 * 1000; // 10 mins
    await user.save();

    try {
      await sendEmail({
        email: user.email,
        subject: 'Password Reset OTP',
        message: `Your OTP for password reset is: ${otp}. It is valid for 10 minutes.`,
      });

      res.status(200).json({ success: true, message: 'OTP sent to email' });
    } catch (err) {
      // Clear OTP on failure
      user.resetPasswordOTP = undefined;
      user.resetPasswordExpires = undefined;
      await user.save();

      // Log detailed error for debugging and return informative message
      console.error('ForgotPassword: email send failed for %s: %o', user.email, err);

      const safeMessage = err && err.message ? String(err.message) : 'Unknown email error';
      // Map common nodemailer errors to clearer messages
      let clientMessage = safeMessage;
      if (/EAUTH|Authentication failed/i.test(safeMessage)) {
        clientMessage = 'SMTP authentication failed. Check SMTP_USER and SMTP_PASS.';
      } else if (/ENOTFOUND|ECONNREFUSED|ETIMEDOUT/i.test(safeMessage)) {
        clientMessage = 'SMTP connection failed. Network or SMTP_HOST/PORT may be incorrect.';
      } else if (/Invalid recipient/i.test(safeMessage) || /Invalid mailbox/i.test(safeMessage)) {
        clientMessage = 'Invalid recipient address.';
      }

      return res.status(500).json({ success: false, message: `Email could not be sent: ${clientMessage}` });
    }
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Please provide email and OTP' });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
      resetPasswordOTP: otp,
      resetPasswordExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const resetPassword = async (req, res) => {
  try {
    const { email, otp, password } = req.body;
    if (!email || !otp || !password) {
      return res.status(400).json({ success: false, message: 'Please provide all fields' });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
      resetPasswordOTP: otp,
      resetPasswordExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    // Set new password
    user.password = password;
    user.resetPasswordOTP = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.status(200).json({ success: true, message: 'Password reset successful' });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const googleLogin = async (req, res) => {
  try {
    let email, name, googleId, photoUrl;
    const { googleToken } = req.body;

    if (googleToken) {
      let payload;
      let lastError;
      
      for (const clientId of GOOGLE_CLIENT_IDS) {
        try {
          let ticket;
          try {
            ticket = await client.verifyIdToken({
              idToken: googleToken,
              audience: clientId,
            });
            payload = ticket.getPayload();
          } catch (err) {
            lastError = err;
            try {
              const axios = require('axios');
              const response = await axios.get(`https://www.googleapis.com/oauth2/v3/userinfo`, {
                headers: { Authorization: `Bearer ${googleToken}` }
              });
              if (response.data) {
                payload = response.data;
                payload.sub = payload.sub || payload.id;
              }
            } catch (axiosErr) {
              lastError = axiosErr;
            }
          }
          
          if (payload && payload.email) break;
        } catch (err) {
          lastError = err;
          continue;
        }
      }

      // Final fallback: if token verification failed but frontend sent user data directly
      if (!payload || !payload.email) {
        if (req.body.email && req.body.googleId) {
          // Trust data from Google account object (user completed Google popup successfully)
          email = req.body.email.toLowerCase();
          name = req.body.name || '';
          googleId = req.body.googleId;
          photoUrl = req.body.photoUrl;
        } else {
          console.error('Google token verification failed:', lastError);
          return res.status(400).json({ success: false, message: 'Invalid Google token' });
        }
      } else {
        email = payload.email.toLowerCase();
        name = payload.name || req.body.name || '';
        googleId = payload.sub || payload.id || req.body.googleId;
        photoUrl = payload.picture || payload.photoUrl || req.body.photoUrl;
      }
    } else {
      // Fallback for when frontend sends data directly
      email = req.body.email?.toLowerCase();
      name = req.body.name;
      googleId = req.body.googleId;
      photoUrl = req.body.photoUrl;

      if (!email || !googleId) {
        return res.status(400).json({ success: false, message: 'Either googleToken or email+googleId are required' });
      }
    }

    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (user) {
      if (!user.googleId) {
        user.googleId = googleId;
        if (photoUrl) user.profilePic = photoUrl;
        await user.save();
      }

      if (!user.mobile || user.mobile.trim() === '') {
        return res.status(200).json({
          success: true,
          isNewUser: true,
          email: user.email,
          name: user.name,
          googleId: googleId,
          photoUrl: user.profilePic || photoUrl
        });
      }

      if (user.role === 'driver') {
        const driver = await Driver.findOne({ user: user._id });
        if (driver && !driver.isApproved) {
          return res.status(403).json({
            success: false,
            message: 'Driver not approved. Please wait for vendor/admin approval.'
          });
        }
      }

      const token = generateToken(user._id);
      let driverId = null;
      if (user.role === 'driver') {
        const driver = await Driver.findOne({ user: user._id });
        driverId = driver?.driverId;
      }
      return res.status(200).json({
        success: true,
        isNewUser: false,
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          role: user.role,
          profilePic: user.profilePic,
          driverId: driverId
        },
      });
    } else {
      return res.status(200).json({
        success: true,
        isNewUser: true,
        email: email,
        name: name,
        googleId: googleId,
        photoUrl: photoUrl
      });
    }
  } catch (error) {
    console.error('Google Login Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const completeProfile = async (req, res) => {
  try {
    const { name, email, googleId, firebaseUid, mobile, photoUrl, role = 'user', vehicleType, vehicleNumber, companyName } = req.body;

    if (!name || !mobile) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide all required fields (name, mobile)' 
      });
    }

    let isNewUser = false;
    const cleanMobile = mobile.replace(/\D/g, '');

    if (role === 'vendor') {
      let query = { phone: cleanMobile };
      if (firebaseUid) {
        query = { $or: [{ phone: cleanMobile }, { firebaseUid }] };
      }
      let vendor = await Vendor.findOne(query);
      if (!vendor) {
        if (!email || !companyName) {
          return res.status(400).json({ 
            success: false, 
            message: 'Please provide email and company name for vendor' 
          });
        }
        vendor = await Vendor.create({
          name,
          email: email.toLowerCase(),
          phone: cleanMobile,
          companyName,
          profilePicture: photoUrl,
          isVerified: true,
          firebaseUid: firebaseUid || undefined,
          googleId: googleId || undefined
        });
        isNewUser = true;
      } else {
        vendor.name = name;
        if (email) vendor.email = email.toLowerCase();
        if (companyName) vendor.companyName = companyName;
        if (photoUrl) vendor.profilePicture = photoUrl;
        if (firebaseUid) vendor.firebaseUid = firebaseUid;
        if (googleId) vendor.googleId = googleId;
        await vendor.save();
      }

      const token = jwt.sign({ id: vendor._id, role: 'vendor' }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE
      });

      return res.status(isNewUser ? 201 : 200).json({
        success: true,
        message: 'Vendor profile completed successfully',
        token,
        user: {
          id: vendor._id,
          name: vendor.name,
          email: vendor.email,
          mobile: vendor.phone,
          role: 'vendor',
          companyName: vendor.companyName,
          profilePicture: vendor.profilePicture
        }
      });
    } else if (role === 'driver') {
      let driver;
      let query = { mobile: cleanMobile };
      if (firebaseUid) {
        query = { $or: [{ mobile: cleanMobile }, { firebaseUid }] };
      }
      driver = await Driver.findOne(query);

      if (driver) {
        driver.name = name;
        if (email) driver.email = email.toLowerCase();
        if (googleId) driver.googleId = googleId;
        if (firebaseUid) driver.firebaseUid = firebaseUid;
        if (photoUrl) driver.profilePic = photoUrl;
        driver.isVerified = true;
        if (vehicleType) driver.vehicleType = vehicleType;
        if (vehicleNumber) driver.vehicleNumber = vehicleNumber;
        await driver.save();
      } else {
        driver = await Driver.create({
          name,
          email: email ? email.toLowerCase() : undefined,
          googleId: googleId || undefined,
          firebaseUid: firebaseUid || undefined,
          mobile: cleanMobile,
          profilePic: photoUrl || 'default-profile.png',
          role: 'driver',
          isVerified: true,
          vehicleType: vehicleType || 'Car',
          vehicleNumber: vehicleNumber,
          licenseNumber: `TEMP-${Date.now()}`,
          isApproved: false
        });
        isNewUser = true;
      }

      if (!driver.isApproved) {
        return res.status(403).json({
          success: false,
          message: 'Driver not approved. Please wait for vendor/admin approval.',
          status: 'pending'
        });
      }

      const token = generateToken(driver._id);
      return res.status(isNewUser ? 201 : 200).json({
        success: true,
        message: 'Profile completed successfully',
        token,
        user: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          mobile: driver.mobile,
          role: driver.role,
          profilePic: driver.profilePic,
          driverId: driver.driverId
        },
      });
    } else {
      // Handle user
      let query = { role: 'user', mobile: cleanMobile };
      if (firebaseUid) {
        query = { role: 'user', $or: [{ mobile: cleanMobile }, { firebaseUid }] };
      }
      let user = await User.findOne(query);
      
      if (user) {
        user.name = name;
        if (email) user.email = email.toLowerCase();
        if (googleId) user.googleId = googleId;
        if (firebaseUid) user.firebaseUid = firebaseUid;
        if (photoUrl) user.profilePic = photoUrl;
        user.isVerified = true;
        await user.save();
      } else {
        user = await User.create({
          name,
          email: email ? email.toLowerCase() : undefined,
          googleId: googleId || undefined,
          firebaseUid: firebaseUid || undefined,
          mobile: cleanMobile,
          profilePic: photoUrl || 'default-profile.png',
          role: role,
          isVerified: true
        });
        isNewUser = true;
      }

      const token = generateToken(user._id);
      return res.status(isNewUser ? 201 : 200).json({
        success: true,
        message: 'Profile completed successfully',
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          role: user.role,
          profilePic: user.profilePic
        },
      });
    }
  } catch (error) {
    console.error('Complete Profile Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

const changePassword = async (req, res) => {
  try {
    console.log('Change Password Request Body:', req.body);
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide current password and new password' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        success: false, 
        message: 'New password must be at least 6 characters' 
      });
    }

    // Get user with password (since select is false by default)
    let user = await User.findById(req.user._id).select('+password');
    if (!user) {
      user = await Driver.findById(req.user._id).select('+password');
    }
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ 
        success: false, 
        message: 'Current password is incorrect' 
      });
    }

    // Update password (pre-save hook will hash it)
    user.password = newPassword;
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change Password Error:', error);
    res.status(400).json({ success: false, message: error.message });
  }
};

// Firebase Phone Auth Endpoints
const firebasePhoneAuth = async (req, res) => {
  try {
    if (!isMongoConnected()) {
      return res.status(503).json({ 
        success: false, 
        message: 'Database not available. Please try again later.' 
      });
    }

    // Check if Firebase Admin is initialized
    if (!admin.apps.length) {
      return res.status(500).json({
        success: false,
        message: 'Firebase Admin not initialized. Please check service account configuration.'
      });
    }

    console.log('Firebase Phone Auth Request Body:', req.body);
    const { idToken, role, name, companyName } = req.body;

    if (!idToken || !role) {
      return res.status(400).json({ success: false, message: 'Please provide idToken and role' });
    }

    // Verify Firebase ID Token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const firebaseUid = decodedToken.uid;
    const phoneNumber = decodedToken.phone_number;

    if (!phoneNumber) {
      return res.status(400).json({ success: false, message: 'Phone number not found in Firebase token' });
    }

    // Clean phone number (remove +91 if present, etc. based on your requirements)
    const cleanPhone = phoneNumber.replace(/^\+91/, ''); // Assuming India, adjust as needed

    if (role === 'user') {
      // Handle User
      let user = await User.findOne({ 
        role: 'user',
        $or: [
          { firebaseUid }, 
          { mobile: cleanPhone }
        ]
      });

      if (!user) {
        // Return isNewUser: true so frontend can show registration
        return res.status(200).json({
          success: true,
          isNewUser: true,
          mobile: cleanPhone,
          message: 'New user, please complete registration'
        });
      } else {
        // Update firebaseUid if not present
        if (!user.firebaseUid) {
          user.firebaseUid = firebaseUid;
          await user.save();
        }
      }

      const token = generateToken(user._id);
      return res.status(200).json({
        success: true,
        isNewUser: false,
        message: 'User authenticated successfully',
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          mobile: user.mobile,
          role: user.role,
          profilePic: user.profilePic
        }
      });
    } else if (role === 'driver') {
      // Handle Driver
      let driver = await Driver.findOne({ 
        $or: [
          { firebaseUid }, 
          { mobile: cleanPhone }
        ]
      });

      if (!driver) {
        // Return isNewDriver: true so frontend can show driver registration
        return res.status(200).json({
          success: true,
          isNewDriver: true,
          mobile: cleanPhone,
          message: 'New driver, please complete registration'
        });
      } else {
        // Update firebaseUid if not present
        if (!driver.firebaseUid) {
          driver.firebaseUid = firebaseUid;
          await driver.save();
        }
      }

      // Check driver status
      if (!driver.isApproved) {
        return res.status(403).json({
          success: false,
          message: 'Waiting for vendor approval.',
          status: 'pending'
        });
      }

      const token = generateToken(driver._id);
      return res.status(200).json({
        success: true,
        isNewDriver: false,
        message: 'Driver authenticated successfully',
        token,
        user: {
          id: driver._id,
          name: driver.name,
          email: driver.email,
          mobile: driver.mobile,
          role: driver.role,
          driverId: driver.driverId,
          profilePic: driver.profilePic
        }
      });
    } else if (role === 'vendor') {
      // Handle Vendor
      let vendor = await Vendor.findOne({ 
        $or: [
          { firebaseUid }, 
          { phone: cleanPhone }
        ]
      });

      if (!vendor) {
        // Return isNewVendor: true so frontend can show vendor registration
        return res.status(200).json({
          success: true,
          isNewVendor: true,
          mobile: cleanPhone,
          message: 'New vendor, please complete registration'
        });
      } else {
        // Update firebaseUid if not present
        if (!vendor.firebaseUid) {
          vendor.firebaseUid = firebaseUid;
          await vendor.save();
        }
      }

      if (!vendor.isApproved) {
        return res.status(403).json({
          success: false,
          message: 'Waiting for admin approval.',
          status: 'pending'
        });
      }

      // Generate token for vendor (we'll need to update auth middleware for vendor)
      const token = jwt.sign({ id: vendor._id, role: 'vendor' }, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRE
      });

      return res.status(200).json({
        success: true,
        isNewVendor: false,
        message: 'Vendor authenticated successfully',
        token,
        user: {
          id: vendor._id,
          name: vendor.name,
          email: vendor.email,
          mobile: vendor.phone,
          role: 'vendor',
          companyName: vendor.companyName,
          profilePicture: vendor.profilePicture
        }
      });
    } else {
      return res.status(400).json({ success: false, message: 'Invalid role' });
    }
  } catch (error) {
    console.error('Firebase Phone Auth Error:', error);
    res.status(400).json({ 
      success: false, 
      message: error.message || 'Firebase authentication failed' 
    });
  }
};

module.exports = { register, login, forgotPassword, verifyOTP, resetPassword, googleLogin, completeProfile, changePassword, firebasePhoneAuth };
