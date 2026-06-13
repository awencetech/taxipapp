const jwt = require('jsonwebtoken');
const User = require('../models/User');

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
      
      req.user = await User.findById(decoded.id);
      console.log('Found user:', req.user);
      
      if (!req.user) {
        console.log('User not found for decoded id');
        return res.status(401).json({
          success: false,
          message: 'The user belonging to this token no longer exists.',
        });
      }
      
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

module.exports = { protect, authorize };
