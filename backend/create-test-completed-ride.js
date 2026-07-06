
require('dotenv').config({ path: './.env' });
const mongoose = require('mongoose');
const User = require('./models/User');
const Driver = require('./models/Driver');
const Ride = require('./models/Ride');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/taxi_nanban';

async function createTestCompletedRide() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    // Find our test user (Murali)
    const user = await User.findOne({ email: 'murali@example.com' });
    if (!user) {
      console.error('Test user not found!');
      process.exit(1);
    }
    console.log('Found user:', user.name, user._id);

    // Find our test driver (Ravi Kumar)
    const driver = await Driver.findOne().populate('user');
    if (!driver) {
      console.error('Test driver not found!');
      process.exit(1);
    }
    console.log('Found driver:', driver.user.name, driver._id);

    // Create a test completed ride
    const ride = new Ride({
      user: user._id,
      driver: driver._id,
      pickupLocation: {
        type: 'Point',
        coordinates: [80.2707, 13.0827], // Chennai Central
        address: 'Chennai Central Railway Station, Park Town, Chennai, Tamil Nadu'
      },
      dropLocation: {
        type: 'Point',
        coordinates: [80.2800, 13.0820], // T Nagar
        address: 'T Nagar Bus Stand, Pondy Bazaar, T Nagar, Chennai, Tamil Nadu'
      },
      vehicleType: 'Auto',
      fare: 180,
      distance: 2.5,
      duration: 12,
      paymentMethod: 'UPI',
      status: 'completed',
      createdAt: new Date(Date.now() - 1000 * 60 * 60), // 1 hour ago
      completedAt: new Date()
    });

    await ride.save();
    console.log('Created completed ride:', ride._id);

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

createTestCompletedRide();
