const mongoose = require('mongoose');
const Driver = require('./models/Driver');
require('dotenv').config({ path: '.env.development' });

async function migrateDriverIds() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find all drivers without driverId
    const drivers = await Driver.find({ driverId: { $exists: false } });
    console.log(`Found ${drivers.length} drivers without driverId`);

    // Find the highest existing driverId to continue numbering
    const lastDriverWithId = await Driver.findOne({ driverId: { $exists: true } }).sort({ driverId: -1 });
    let nextId = 1;
    if (lastDriverWithId && lastDriverWithId.driverId) {
      const lastNum = parseInt(lastDriverWithId.driverId.replace('DRV', ''), 10);
      nextId = lastNum + 1;
    }

    // Update each driver
    for (const driver of drivers) {
      const newDriverId = `DRV${String(nextId).padStart(6, '0')}`;
      driver.driverId = newDriverId;
      await driver.save();
      console.log(`Updated driver ${driver._id} with driverId: ${newDriverId}`);
      nextId++;
    }

    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrateDriverIds();
