
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const User = require('./models/User');
const Driver = require('./models/Driver');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    const users = await User.find();
    console.log('Users in database:');
    for (const user of users) {
      console.log(`- Name: ${user.name}, Email: ${user.email}, Role: ${user.role}, ID: ${user._id}`);
    }

    console.log('\nDrivers:');
    const drivers = await Driver.find().populate('user');
    for (const driver of drivers) {
      console.log(`- Driver: ${driver.user?.name}, ID: ${driver._id}, Approved: ${driver.isApproved}`);
    }

    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
