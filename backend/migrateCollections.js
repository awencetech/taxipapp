const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

// Load environment config
const envPath = path.resolve(__dirname, `.env.${process.env.NODE_ENV || 'development'}`);
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
} else {
  dotenv.config();
}

// Import models
const User = require('./models/User');
const Driver = require('./models/Driver');
const Wallet = require('./models/Wallet');

// Connect to DB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('MongoDB Connected');
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

const migrateWallets = async () => {
  console.log('Starting wallet migration...');
  try {
    // Get all users
    const users = await User.find();
    console.log(`Found ${users.length} users`);
    
    for (let user of users) {
      let wallet = await Wallet.findOne({
        userType: user.role === 'driver' ? 'Driver' : 'User',
        userId: user._id
      });
      
      if (!wallet) {
        await Wallet.create({
          userType: user.role === 'driver' ? 'Driver' : 'User',
          userId: user._id,
          balance: 0
        });
        console.log(`Created wallet for user ${user._id}`);
      }
    }
    
    // Also check for drivers who may not have a user record linked properly
    const drivers = await Driver.find();
    console.log(`Found ${drivers.length} drivers`);
    
    for (let driver of drivers) {
      let wallet = await Wallet.findOne({
        userType: 'Driver',
        userId: driver.user
      });
      
      if (!wallet) {
        await Wallet.create({
          userType: 'Driver',
          userId: driver.user,
          balance: 0
        });
        console.log(`Created wallet for driver user ${driver.user}`);
      }
    }
    
    console.log('Wallet migration complete');
  } catch (error) {
    console.error('Error during wallet migration:', error);
  }
};

const runMigrations = async () => {
  await connectDB();
  
  await migrateWallets();
  
  console.log('All migrations complete');
  process.exit(0);
};

runMigrations();
