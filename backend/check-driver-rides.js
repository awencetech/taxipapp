
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const Ride = require('./models/Ride');
const Driver = require('./models/Driver');
const User = require('./models/User');

async function checkDriverRides() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected!');

    const drivers = await Driver.find({}).populate('user');
    console.log('Drivers found:', drivers.length);
    if (drivers.length > 0) {
      const driver = drivers[0];
      console.log('Checking driver:', driver.user.name, driver._id);
      
      const rides = await Ride.find({ driver: driver._id }).populate('user');
      console.log('Rides for this driver:', rides.length);
      
      rides.forEach((ride, index) => {
        console.log(`Ride ${index + 1}:`);
        console.log(`  ID: ${ride._id}`);
        console.log(`  Fare: ${ride.fare}`);
        console.log(`  Status: ${ride.status}`);
        console.log(`  Created At: ${ride.createdAt}`);
        console.log('  ---');
      });
    }
    
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

checkDriverRides();
