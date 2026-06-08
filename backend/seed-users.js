const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

const seedUsers = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected');

    // Clear existing users (optional, comment out if you don't want to delete)
    // await User.deleteMany({});
    // console.log('Existing users cleared');

    // Test users
    const users = [
      {
        name: 'Test User',
        email: 'user@taxinanban.com',
        mobile: '9876543210',
        password: 'password123',
        role: 'user',
        isVerified: true
      },
      {
        name: 'Test Driver',
        email: 'driver@taxinanban.com',
        mobile: '9876543211',
        password: 'password123',
        role: 'driver',
        isVerified: true
      },
      {
        name: 'Test Admin',
        email: 'admin@taxinanban.com',
        mobile: '9876543212',
        password: 'password123',
        role: 'admin',
        isVerified: true
      }
    ];

    for (const userData of users) {
      // Check if user already exists
      const existingUser = await User.findOne({ email: userData.email });
      if (!existingUser) {
        const user = await User.create(userData);
        console.log(`Created user: ${user.email}`);
      } else {
        console.log(`User already exists: ${userData.email}`);
      }
    }

    console.log('User seeding complete!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding users:', error);
    process.exit(1);
  }
};

seedUsers();
