
const axios = require('axios');
const dotenv = require('dotenv');
dotenv.config({ path: './.env.development' });

async function test() {
  try {
    // First login as driver
    const loginResponse = await axios.post(`${process.env.API_URL || `http://localhost:${process.env.PORT || 5003}`}/api/v1/auth/login`, {
      email: 'ravi@taxinanban.com',
      password: 'test123456',
      role: 'driver'
    });
    console.log('Login response:', loginResponse.data);
    const token = loginResponse.data.token || loginResponse.data.data.token;
    console.log('Token:', token);

    // Now get driver history
    const historyResponse = await axios.get(`${process.env.API_URL || `http://localhost:${process.env.PORT || 5003}`}/api/v1/rides/driver/history`, {
      headers: {
        Authorization: `Bearer ${token}`
      }
    });
    console.log('History response:', JSON.stringify(historyResponse.data, null, 2));
  } catch (error) {
    console.error('Error:', error.response ? error.response.data : error.message);
  }
}

test();
