
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
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/taxinanban';
    const maskedUri = mongoUri.replace(/mongodb(?:\+srv)?:\/\/([^:]+):([^@]+)@/, 'mongodb://***:***@');

    logger.info('MongoDB connect attempt: ' + maskedUri);

    const conn = await mongoose.connect(mongoUri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 10000,
    });

    mongoConnected = true;
    mongoConnecting = false;
    logger.info('MongoDB Connected: host=' + conn.connection.host + ' db=' + conn.connection.name + ' readyState=' + conn.connection.readyState);
  } catch (error) {
    logger.warn('MongoDB unavailable or authentication required: ' + error.message + '. Some features may not work.');
    mongoConnected = false;
    mongoConnecting = false;
  }
};

module.exports = { connectDB, isMongoConnected };
