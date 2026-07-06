const mongoose = require('mongoose');
const Vehicle = require('./models/Vehicle');
require('dotenv').config({ path: '.env.development' });

async function checkVehicles() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const vehicles = await Vehicle.find().populate('driver');
    console.log(`Found ${vehicles.length} vehicles in DB`);
    vehicles.forEach((v, i) => {
      console.log(`Vehicle ${i+1}:`, JSON.stringify(v, null, 2));
    });

    process.exit(0);
  } catch (error) {
    console.error('Error checking vehicles:', error);
    process.exit(1);
  }
}

checkVehicles();
