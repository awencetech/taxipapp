
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const Vendor = require('./models/Vendor');
const Driver = require('./models/Driver');
const User = require('./models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    const vendors = await Vendor.find();
    console.log('\nVendors in DB:', vendors.length);
    vendors.forEach(v => {
      console.log(`Vendor: ${v.name}, ID: ${v._id.toString()}, Approved: ${v.isApproved}`);
    });

    const drivers = await Driver.find().populate('user', 'name');
    console.log('\nDrivers in DB:', drivers.length);
    drivers.forEach(d => {
      console.log(`Driver: ${d.user?.name}, Vendor ID: ${d.vendor ? d.vendor.toString() : 'NULL'}, Approved: ${d.isApproved}`);
    });

    if (vendors.length > 0) {
      const vendor = vendors[0];
      const result = await Driver.updateMany({}, { $set: { vendor: vendor._id } });
      console.log(`\nUpdated ${result.modifiedCount} drivers to vendor ${vendor._id.toString()}`);
    }

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
