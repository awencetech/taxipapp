const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: './.env.development' });

// Import models
const Ride = require('./models/Ride');
const Driver = require('./models/Driver');

async function updateRides() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected!');

    // Get the current user's driver (the one logged in, user id is 6a2bd41fb213344046e73645)
    const driver = await Driver.findOne({ user: '6a2bd41fb213344046e73645' });
    
    if (!driver) {
      console.error('❌ Driver not found!');
      process.exit(1);
    }

    console.log('✅ Found driver:', driver._id);

    // Update all rides for this user to have this driver's ID
    const result = await Ride.updateMany(
      { user: '6a2bd41fb213344046e73645' },
      { driver: driver._id, status: 'accepted' }
    );

    console.log('✅ Updated rides:', result.modifiedCount);

    // Verify the update
    const updatedRides = await Ride.find({ user: '6a2bd41fb213344046e73645' });
    console.log('✅ Updated rides list:', updatedRides.map(r => ({ _id: r._id, status: r.status, driver: r.driver })));

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

updateRides();
