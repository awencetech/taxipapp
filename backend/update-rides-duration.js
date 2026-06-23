const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const Ride = require('./models/Ride');

async function updateRides() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected!');

    const rides = await Ride.find({});
    const rideUpdates = [
      { id: '6a215e5e38a62a3590293f14', duration: 148, distance: 247.1 },
      { id: '6a34f84c7fd7b48971b8521e', duration: 90, distance: 115.5 },
      { id: '6a34fa627fd7b48971b85233', duration: 90, distance: 115.5 },
      { id: '6a36728742d5b9f567e0c406', duration: 90, distance: 115.5 },
    ];

    for (const rideUpdate of rideUpdates) {
      await Ride.findByIdAndUpdate(rideUpdate.id, {
        duration: rideUpdate.duration,
        distance: rideUpdate.distance,
      });
    }

    console.log('Updated all rides!');

    const updatedRides = await Ride.find({});
    console.log('Updated rides:');
    updatedRides.forEach((ride, index) => {
      console.log(`Ride ${index + 1}:`);
      console.log(`  ID: ${ride._id}`);
      console.log(`  Duration: ${ride.duration} min`);
      console.log(`  Distance: ${ride.distance} km`);
      console.log(`  ---`);
    });

    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

updateRides();
