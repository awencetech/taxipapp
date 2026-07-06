
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const User = require('./models/User');
const Driver = require('./models/Driver');
const Ride = require('./models/Ride');

async function createRide() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Mongo connected');

    const user = await User.findOne({ email: 'rajawence@gmail.com' });
    const driver = await Driver.findOne({ user: '6a4605b42a53adca426f205f' });

    if (!user || !driver) {
      console.log('User or driver not found');
      process.exit(1);
    }

    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const ride = new Ride({
      user: user._id,
      driver: driver._id,
      pickupLocation: {
        type: 'Point',
        coordinates: [80.2707, 13.0827],
        address: 'Chennai Central, Chennai'
      },
      dropLocation: {
        type: 'Point',
        coordinates: [80.2800, 13.0820],
        address: 'T Nagar, Chennai'
      },
      vehicleType: 'standard',
      fare: 180,
      distance: 4,
      duration: 12,
      paymentMethod: 'cash',
      status: 'completed',
      createdAt: yesterday,
      startTime: new Date(yesterday.getTime() - 30 * 60 * 1000),
      endTime: yesterday
    });

    await ride.save();
    console.log('Created yesterday ride:', ride);
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

createRide();
