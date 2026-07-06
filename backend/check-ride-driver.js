
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const Ride = require('./models/Ride');
const Driver = require('./models/Driver');

async function check() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected!');

    // Find completed rides
    const rides = await Ride.find({ status: 'completed' }).populate('driver');
    console.log('Completed rides:', rides.length);
    rides.forEach(ride => {
      console.log(`  Ride ${ride._id}: driver=${ride.driver?._id}, fare=${ride.fare}`);
    });

    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

check();
