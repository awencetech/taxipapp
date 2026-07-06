
const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config({ path: './.env.development' });

const Driver = require('./models/Driver');
const User = require('./models/User');

async function check() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB connected!');

    const users = await User.find({});
    console.log('Users found:');
    users.forEach(u => console.log(`  ${u.name} - ${u.email} - ${u._id}`));

    const drivers = await Driver.find({}).populate('user');
    console.log('Drivers found:');
    drivers.forEach(d => console.log(`  Driver: ${d.user?.name} - ${d._id} - user: ${d.user?._id}`));

    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

check();
