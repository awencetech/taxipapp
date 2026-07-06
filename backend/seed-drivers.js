const mongoose = require('mongoose');
const User = require('./models/User');
const Driver = require('./models/Driver');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env.development') });

const seedDrivers = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected');

    // Test driver users with coordinates
    const testDrivers = [
      {
        name: 'Ravi Kumar',
        email: 'ravi@taxinanban.com',
        mobile: '9876543213',
        password: 'password123',
        role: 'driver',
        isVerified: true,
        profilePic: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=60',
        lat: 19.0760,
        lng: 72.8777,
        vehicleType: 'Car',
        vehicleNumber: 'MH 01 AB 1234',
        isOnline: true,
        isBusy: false,
        ratings: 4.8,
        numReviews: 50,
        speed: 45,
      },
      {
        name: 'Suresh Singh',
        email: 'suresh@taxinanban.com',
        mobile: '9876543214',
        password: 'password123',
        role: 'driver',
        isVerified: true,
        profilePic: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=60',
        lat: 19.0820,
        lng: 72.8850,
        vehicleType: 'SUV',
        vehicleNumber: 'MH 02 CD 5678',
        isOnline: true,
        isBusy: true,
        ratings: 4.7,
        numReviews: 80,
        speed: 60,
      },
    ];

    for (const driverData of testDrivers) {
      // Check if user already exists
      let user = await User.findOne({ email: driverData.email });
      if (!user) {
        user = await User.create({
          name: driverData.name,
          email: driverData.email,
          mobile: driverData.mobile,
          password: driverData.password,
          role: driverData.role,
          isVerified: driverData.isVerified,
          profilePic: driverData.profilePic,
        });
        console.log(`Created driver user: ${user.email}`);
      } else {
        console.log(`Driver user already exists: ${driverData.email}`);
      }

      // Check if driver profile exists
      let driver = await Driver.findOne({ user: user._id });
      if (!driver) {
        driver = await Driver.create({
          user: user._id,
          licenseNumber: `LIC-${driverData.mobile}`,
          status: 'available',
          isApproved: true,
          vehicleType: driverData.vehicleType,
          vehicleNumber: driverData.vehicleNumber,
          ratings: driverData.ratings,
          numReviews: driverData.numReviews,
          currentLatitude: driverData.lat,
          currentLongitude: driverData.lng,
          isOnline: driverData.isOnline,
          isBusy: driverData.isBusy,
          speed: driverData.speed,
        });
        console.log(`Created driver profile for: ${user.name}`);
      } else {
        // Update existing driver with coordinates
        driver.currentLatitude = driverData.lat;
        driver.currentLongitude = driverData.lng;
        driver.isOnline = driverData.isOnline;
        driver.isBusy = driverData.isBusy;
        driver.speed = driverData.speed;
        driver.vehicleType = driverData.vehicleType;
        driver.vehicleNumber = driverData.vehicleNumber;
        await driver.save();
        console.log(`Updated driver profile for: ${user.name}`);
      }
    }

    console.log('Driver seeding complete!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding drivers:', error);
    process.exit(1);
  }
};

seedDrivers();
