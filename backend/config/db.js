
const mongoose = require('mongoose');
const logger = require('../utils/logger');

let mongoConnected = false;
let mongoConnecting = false;

const isMongoConnected = () => {
  return mongoConnected;
};

const connectDB = async () => {
  if (mongoConnecting || mongoConnected) return;
  mongoConnecting = true;
  
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 10000,
    });

    mongoConnected = true;
    mongoConnecting = false;
    logger.info('MongoDB Connected: ' + conn.connection.host);
  } catch (error) {
    logger.warn('MongoDB unavailable or authentication required: ' + error.message + '. Some features may not work.');
    mongoConnected = false;
    mongoConnecting = false;
  }
};

module.exports = { connectDB, isMongoConnected };
