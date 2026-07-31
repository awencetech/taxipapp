const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Vendor = require('../models/Vendor');

const protect = async (req, res, next) => {
  let token;
  console.log('=== Auth Middleware Debug ===');
  console.log('Request Headers:', JSON.stringify(req.headers, null, 2));
  console.log('JWT_SECRET present:', !!process.env.JWT_SECRET);

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      console.log('Extracted token:', token);
      
      if (!token) {
        console.log('No token provided');
        return res.status(401).json({
          success: false,
          message: 'Not authorized, no token provided',
        });
      }

      console.log('Verifying token with JWT_SECRET');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log('Token decoded:', decoded);
      
      // First check if it's a user
      let user = await User.findById(decoded.id);
      // If not a user, check if it's a driver
      if (!user) {
        user = await Driver.findById(decoded.id);
      }
      // If not a driver, check if it's a vendor
      if (!user) {
        user = await Vendor.findById(decoded.id);
      }
      
      console.log('Found user/driver/vendor:', user);
      
      if (!user) {
        console.log('User or driver or vendor not found for decoded id');
        return res.status(401).json({
          success: false,
          message: 'The user/driver/vendor belonging to this token no longer exists.',
        });
      }
      
      // Check if user is a vendor and validate their approval status
      if (user.constructor.modelName === 'Vendor') {
        // Re-fetch vendor to get the latest approval status (in case it changed)
        const latestVendor = await Vendor.findById(decoded.id);
        if (!latestVendor) {
          return res.status(401).json({
            success: false,
            message: 'The user/driver/vendor belonging to this token no longer exists.',
          });
        }
        
        // Main vendor is always allowed
        if (latestVendor.role !== 'main_vendor') {
          if (latestVendor.approvalStatus === 'pending') {
            return res.status(403).json({
              success: false,
              message: 'Pending Approval',
              approvalStatus: 'pending',
            });
          }
          if (latestVendor.approvalStatus === 'declined') {
            return res.status(403).json({
              success: false,
              message: 'Registration Declined',
              approvalStatus: 'declined',
            });
          }
        }
        
        // Update req.user with latest vendor data
        user = latestVendor;
      }
      
      req.user = user; // Set req.user to either User, Driver, or Vendor
      console.log('=== Auth Middleware: Success, calling next() ===');
      next();
    } catch (error) {
      console.error('=== Auth Middleware: JWT Verification Error ===');
      console.error('Error message:', error.message);
      console.error('Error stack:', error.stack);
      return res.status(401).json({
        success: false,
        message: 'Not authorized, token failed or expired',
      });
    }
  } else {
    console.log('No authorization header with Bearer token');
    return res.status(401).json({
      success: false,
      message: 'You are not logged in! Please log in to get access.',
    });
  }
};

const protectOptional = async (req, res, next) => {
  if (!req.headers.authorization || !req.headers.authorization.startsWith('Bearer')) {
    return next();
  }

  return protect(req, res, next);
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to perform this action',
      });
    }
    next();
  };
};

module.exports = { protect, protectOptional, authorize };
