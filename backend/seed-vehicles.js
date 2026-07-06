const mongoose = require('mongoose');
const Vehicle = require('./models/Vehicle');
const Driver = require('./models/Driver');
require('dotenv').config({ path: '.env.development' });

async function seedVehicles() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const drivers = await Driver.find().limit(3);
    console.log(`Using ${drivers.length} drivers for vehicles`);

    const vehicles = [
      {
        driver: drivers[0]?._id,
        model: 'Toyota Camry',
        plateNumber: 'TN 01 AB 1234',
        color: 'White',
        type: 'sedan',
        year: 2022,
        brand: 'Toyota',
        rcNumber: 'RC-TN01-1234',
        insuranceExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        pollutionExpiry: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
        status: 'active',
      },
      {
        driver: drivers[1]?._id,
        model: 'Honda City',
        plateNumber: 'TN 02 CD 5678',
        color: 'Silver',
        type: 'sedan',
        year: 2021,
        brand: 'Honda',
        rcNumber: 'RC-TN02-5678',
        insuranceExpiry: new Date(Date.now() + 300 * 24 * 60 * 60 * 1000),
        pollutionExpiry: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
        status: 'active',
      },
      {
        driver: drivers[2]?._id,
        model: 'Ford EcoSport',
        plateNumber: 'TN 03 EF 9012',
        color: 'Blue',
        type: 'suv',
        year: 2020,
        brand: 'Ford',
        rcNumber: 'RC-TN03-9012',
        insuranceExpiry: new Date(Date.now() + 200 * 24 * 60 * 60 * 1000),
        pollutionExpiry: new Date(Date.now() + 100 * 24 * 60 * 60 * 1000),
        status: 'maintenance',
      },
    ];

    await Vehicle.deleteMany();
    await Vehicle.insertMany(vehicles);
    
    console.log(`Successfully seeded ${vehicles.length} vehicles!`);
    process.exit(0);
  } catch (error) {
    console.error('Error seeding vehicles:', error);
    process.exit(1);
  }
}

seedVehicles();
