const axios = require('axios');
const mongoose = require('mongoose');
const Vendor = require('./models/Vendor');
const jwt = require('jsonwebtoken');
require('dotenv').config({ path: '.env.development' });

async function testVehiclesAPI() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const vendor = await Vendor.findOne();
    if (!vendor) {
      console.error('No vendor found');
      process.exit(1);
    }

    const token = jwt.sign({ id: vendor._id }, process.env.JWT_SECRET, { expiresIn: '1d' });
    console.log('Vendor token generated');

    const response = await axios.get(`http://127.0.0.1:${process.env.PORT || 5003}/api/v1/vendor/vehicles`, {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log('\nAPI Response Status:', response.status);
    console.log('Number of vehicles:', response.data.length);
    console.log('\nFirst vehicle:', JSON.stringify(response.data[0], null, 2));

    process.exit(0);
  } catch (error) {
    console.error('Error:', error.response ? error.response.data : error.message);
    process.exit(1);
  }
}

testVehiclesAPI();
