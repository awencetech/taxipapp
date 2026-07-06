
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

dotenv.config({ path: '.env.development' });
const User = require('./models/User');
const Driver = require('./models/Driver');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');

    // Get user
    const user = await User.findOne({ email: 'ravi@taxinanban.com' }).select('+password');
    console.log('User found:', user.name, user.email, user.role);

    // Test password
    const passwordMatch = await bcrypt.compare('test123456', user.password);
    console.log('Password matches:', passwordMatch);

    // Generate token
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });
    console.log('Generated token:', token);

    // Get driver
    const driver = await Driver.findOne({ user: user._id });
    console.log('Driver isApproved:', driver.isApproved);

    process.exit(0);
  })
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
