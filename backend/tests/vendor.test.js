const request = require('supertest');
const app = require('../server');
const Vendor = require('../models/Vendor');

describe('Vendor Authentication', () => {
  describe('POST /api/v1/vendor/register', () => {
    it('should register a new vendor', async () => {
      const res = await request(app)
        .post('/api/v1/vendor/register')
        .send({
          name: 'Test Vendor',
          email: 'test@vendor.com',
          phone: '1234567890',
          password: 'password123',
          companyName: 'Test Company',
        });

      expect(res.statusCode).toEqual(201);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
    });

    it('should not register vendor with existing email', async () => {
      await Vendor.create({
        name: 'Existing Vendor',
        email: 'existing@vendor.com',
        phone: '0987654321',
        password: 'password123',
        companyName: 'Existing Company',
      });

      const res = await request(app)
        .post('/api/v1/vendor/register')
        .send({
          name: 'Another Vendor',
          email: 'existing@vendor.com',
          phone: '1112223334',
          password: 'password123',
          companyName: 'Another Company',
        });

      expect(res.statusCode).toEqual(400);
    });
  });

  describe('POST /api/v1/vendor/login', () => {
    it('should login a vendor with valid credentials', async () => {
      await Vendor.create({
        name: 'Login Test',
        email: 'login@test.com',
        phone: '5555555555',
        password: 'password123',
        companyName: 'Login Company',
      });

      const res = await request(app)
        .post('/api/v1/vendor/login')
        .send({
          email: 'login@test.com',
          password: 'password123',
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
    });

    it('should reject invalid credentials', async () => {
      const res = await request(app)
        .post('/api/v1/vendor/login')
        .send({
          email: 'invalid@test.com',
          password: 'wrongpassword',
        });

      expect(res.statusCode).toEqual(401);
    });
  });
});
