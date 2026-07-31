const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Vendor = require('./models/Vendor');

// Load development environment values when running locally
dotenv.config({ path: '.env.development' });

typeof process === 'undefined' || console.log('Using MongoDB URI:', process.env.MONGODB_URI);

const email = process.env.VENDOR_EMAIL || 'eashwarnaveen@gmail.com';
const password = process.env.VENDOR_PASSWORD || 'NAveen5858eas#';
const name = process.env.VENDOR_NAME || 'Eashwar Naveen';
const companyName = process.env.VENDOR_COMPANY_NAME || 'Taxi Nanban Vendor';
const phone = process.env.VENDOR_PHONE || `98765${Math.floor(10000 + Math.random() * 90000)}`;

const seedVendorAccount = async () => {
  try {
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI is not defined. Set it in your environment or .env.development file.');
    }

    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB.');

    let vendor = await Vendor.findOne({ email: email.toLowerCase().trim() }).select('+password');

    if (vendor) {
      vendor.password = password;
      vendor.role = 'main_vendor';
      vendor.approvalStatus = 'approved';
      vendor.isApproved = true;
      vendor.phone = phone;
      vendor.companyName = companyName;
      await vendor.save();
      console.log('Existing vendor updated.');
    } else {
      vendor = await Vendor.create({
        name,
        email: email.toLowerCase().trim(),
        phone,
        password,
        companyName,
        role: 'main_vendor',
        approvalStatus: 'approved',
        isApproved: true,
      });
      console.log('Vendor created successfully.');
    }

    console.log('Email:', vendor.email);
    console.log('Password:', password);
    console.log('Vendor ID:', vendor._id);
    process.exit(0);
  } catch (error) {
    console.error('Error seeding vendor account:', error);
    process.exit(1);
  }
};

seedVendorAccount();
