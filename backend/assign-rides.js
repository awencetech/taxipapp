
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const User = require('./models/User');
const Driver = require('./models/Driver');
const Ride = require('./models/Ride');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    // Find Ravi Kumar's driver
    // Find Ravi Kumar's user first
const raviUser = await User.findOne({ name: 'Ravi Kumar' });
console.log('Found user:', raviUser?.name, raviUser?._id);

// Find his driver
const driver = await Driver.findOne({ user: raviUser._id });
console.log('Found driver:', driver._id);

    // Assign 5 completed rides to him
    const rides = await Ride.find({ status: 'completed' }).limit(5);
    for (const ride of rides) {
      ride.driver = driver._id;
      await ride.save();
      console.log('Assigned ride', ride._id, 'to driver');
    }

    console.log('Done assigning rides!');
    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
