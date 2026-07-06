
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');

dotenv.config({ path: '.env.development' });
const User = require('./models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    // Find Ravi Kumar
    const user = await User.findOne({ email: 'ravi@taxinanban.com' });
    if (!user) {
      console.log('User not found');
      process.exit(1);
    }

    console.log('Found user:', user.name);

    // Hash the password "test123456"
    const hashedPassword = await bcrypt.hash('test123456', 10);

    // Update user's password using updateOne to bypass the pre-save middleware that rehashes
    await User.updateOne(
      { _id: user._id },
      { $set: { password: hashedPassword } }
    );

    console.log('Password updated successfully!');
    console.log('Use these credentials to login:');
    console.log('Email: ravi@taxinanban.com');
    console.log('Password: test123456');

    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
