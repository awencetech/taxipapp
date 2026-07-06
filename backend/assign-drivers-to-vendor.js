
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const Vendor = require('./models/Vendor');
const Driver = require('./models/Driver');
const User = require('./models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    // Find first vendor
    const vendor = await Vendor.findOne();
    console.log('Vendor found:', vendor);

    // Update all drivers to have this vendor
    if (vendor) {
      await Driver.updateMany({}, { vendor: vendor._id, isApproved: true });
      console.log('All drivers updated with vendor and approved!');
    } else {
      console.log('No vendor found! Please register a vendor first!');
    }

    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
