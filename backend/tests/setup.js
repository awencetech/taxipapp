const mongoose = require('mongoose');

beforeAll(async () => {
  await mongoose.connect('mongodb://admin:admin123@localhost:27017/test_db?authSource=admin');
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key].deleteMany({});
  }
});
