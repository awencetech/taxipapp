const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Vendor = require('./models/Vendor');

dotenv.config();

const seedVendor = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const existingVendor = await Vendor.findOne({ email: 'vendor@taxinanban.com' });
    if (existingVendor) {
      existingVendor.password = 'password123';
      existingVendor.role = 'main_vendor';
      existingVendor.approvalStatus = 'approved';
      existingVendor.isApproved = true;
      await existingVendor.save();

      console.log('Test vendor already exists and has been updated to active status!');
      console.log('Email: vendor@taxinanban.com');
      console.log('Password: password123');
      process.exit(0);
    }

    const vendor = await Vendor.create({
      name: 'John Doe',
      email: 'vendor@taxinanban.com',
      phone: '9876543210',
      password: 'password123',
      companyName: 'Taxi Nanban Fleet',
      role: 'main_vendor',
      approvalStatus: 'approved',
      isApproved: true,
    });

    console.log('Test vendor created successfully!');
    console.log('Email: vendor@taxinanban.com');
    console.log('Password: password123');
    console.log('Vendor ID:', vendor._id);

    process.exit(0);
  } catch (error) {
    console.error('Error seeding vendor:', error);
    process.exit(1);
  }
};

seedVendor();
