
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const User = require('./models/User');
const Driver = require('./models/Driver');
const Ride = require('./models/Ride');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    const drivers = await Driver.find().populate('user');
    console.log('Drivers found:', drivers.length);
    for (const d of drivers) {
      console.log('Driver:', d.user?.name, d._id, 'isApproved:', d.isApproved);
    }

    const rides = await Ride.find().populate('user').populate('driver');
    console.log('\nRides found:', rides.length);
    for (const r of rides) {
      console.log('Ride:', r._id, 'Driver:', r.driver?._id, 'Status:', r.status);
    }

    // Set all drivers to approved
    await Driver.updateMany({}, { isApproved: true });
    console.log('\nAll drivers set to approved!');

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
