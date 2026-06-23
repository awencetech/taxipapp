const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const Ride = require('./models/Ride');

async function checkRides() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected!');

    const rides = await Ride.find({});
    console.log('All rides:');
    rides.forEach((ride, index) => {
      console.log(`Ride ${index + 1}:`);
      console.log(`  ID: ${ride._id}`);
      console.log(`  Duration: ${ride.duration}`);
      console.log(`  Status: ${ride.status}`);
      console.log(`  ---`);
    });
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

checkRides();
