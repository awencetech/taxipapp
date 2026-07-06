
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: '.env.development' });
const Vendor = require('./models/Vendor');
const Driver = require('./models/Driver');
const User = require('./models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    // Approve all vendors
    await Vendor.updateMany({}, { $set: { isApproved: true } });
    console.log('All vendors are now approved!');

    // Find Raj Awence
    const raj = await Vendor.findOne({ name: 'Raj Awence' });
    if (raj) {
      const updateResult = await Driver.updateMany({}, { $set: { vendor: raj._id } });
      console.log(`Updated ${updateResult.modifiedCount} drivers to Raj Awence's vendor (${raj._id.toString()})`);
    } else {
      console.log('Raj Awence not found!');
    }

    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
