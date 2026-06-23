const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: './.env.development' });

// Import models
const Ride = require('./models/Ride');
const User = require('./models/User');

async function createTestRides() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected!');

    // Get test user (same as update-test-rides.js)
    const user = await User.findById('6a2bd41fb213344046e73645');

    if (!user) {
      console.error('❌ User not found!');
      process.exit(1);
    }

    // Create test pending rides
    const rides = [
      {
        user: user._id,
        pickupLocation: {
          address: 'Anna Nagar, Chennai',
          coordinates: [80.2182, 13.0827] // [lng, lat]
        },
        dropLocation: {
          address: 'T Nagar, Chennai',
          coordinates: [80.2542, 13.0407]
        },
        fare: 150,
        distance: 5.5,
        duration: 18,
        vehicleType: 'standard',
        status: 'pending'
      },
      {
        user: user._id,
        pickupLocation: {
          address: 'Besant Nagar, Chennai',
          coordinates: [80.2784, 13.0004]
        },
        dropLocation: {
          address: 'Vadapalani, Chennai',
          coordinates: [80.2180, 13.0530]
        },
        fare: 200,
        distance: 8,
        duration: 25,
        vehicleType: 'standard',
        status: 'pending'
      }
    ];

    // Insert rides into DB
    const createdRides = await Ride.insertMany(rides);
    console.log('✅ Created test pending rides:', createdRides.map(r => ({ _id: r._id, status: r.status })));

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createTestRides();