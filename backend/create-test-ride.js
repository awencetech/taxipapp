
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config({ path: '.env.development' });

// Import models
const User = require('./models/User');
const Driver = require('./models/Driver');
const Ride = require('./models/Ride');

// Connect to DB
mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    
    // Find a test user
    let user = await User.findOne({ role: 'user' });
    if (!user) {
      console.log('Creating test user...');
      user = await User.create({
        name: 'Test Passenger',
        email: 'testpassenger@example.com',
        password: 'test123',
        mobile: '9876543210',
        role: 'user'
      });
    }
    console.log('Using user:', user.name, user._id);

    // Find a test driver
    let driver = await Driver.findOne().populate('user');
    if (!driver) {
      let driverUser = await User.findOne({ role: 'driver' });
      if (!driverUser) {
        console.log('Creating test driver user...');
        driverUser = await User.create({
          name: 'Test Driver',
          email: 'testdriver@example.com',
          password: 'test123',
          mobile: '9876543211',
          role: 'driver'
        });
      }
      console.log('Creating test driver...');
      driver = await Driver.create({
        user: driverUser._id,
        licenseNumber: 'TEST123',
        vehicleType: 'Car',
        vehicleNumber: 'TN 01 AB 1234',
        isApproved: true,
        isOnline: true
      });
    }
    console.log('Using driver:', driver._id);

    // Create test ride
    console.log('Creating test ride...');
    const ride = await Ride.create({
      user: user._id,
      driver: driver._id,
      pickupLocation: {
        type: 'Point',
        coordinates: [80.2707, 13.0827],
        address: 'Chennai Central Railway Station, Park Town, Chennai'
      },
      dropLocation: {
        type: 'Point',
        coordinates: [80.2590, 13.0674],
        address: 'Anna Nagar Roundtana, Anna Nagar, Chennai'
      },
      fare: 250,
      distance: 5.2,
      duration: 15,
      vehicleType: 'Car',
      status: 'completed',
      paymentMethod: 'cash',
      paymentStatus: 'completed'
    });

    console.log('Test ride created:', ride._id);

    // Create another test ride
    const ride2 = await Ride.create({
      user: user._id,
      driver: driver._id,
      pickupLocation: {
        type: 'Point',
        coordinates: [80.2485, 13.0390],
        address: 'Phoenix Marketcity, Velachery, Chennai'
      },
      dropLocation: {
        type: 'Point',
        coordinates: [80.2707, 13.0827],
        address: 'Chennai Central Railway Station, Park Town, Chennai'
      },
      fare: 350,
      distance: 10.5,
      duration: 30,
      vehicleType: 'Car',
      status: 'completed',
      paymentMethod: 'upi',
      paymentStatus: 'completed'
    });

    console.log('Second test ride created:', ride2._id);

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
