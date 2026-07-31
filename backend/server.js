// Taxi Nanban Backend Server - Updated port to 5003
const express = require('express');
const http = require('http');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const path = require('path');
const fs = require('fs');

const { connectDB } = require('./config/db');
const initSocket = require('./sockets/socketManager');
const errorHandler = require('./middleware/errorMiddleware');
const swaggerSpec = require('./config/swagger');
const logger = require('./utils/logger');
const { metricsMiddleware, metricsRouter } = require('./utils/metrics');
const { createRedisClient } = require('./utils/cache');

// Load environment-specific config
const envPath = path.resolve(__dirname, `.env.${process.env.NODE_ENV || 'development'}`);
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
  logger.info(`Loaded environment config from ${envPath}`);
} else {
  dotenv.config();
  logger.warn(`Environment file not found at ${envPath}; falling back to default dotenv resolution`);
}

logger.info(`Backend environment: NODE_ENV=${process.env.NODE_ENV || 'development'}, PORT=${process.env.PORT || 5001}`);

// Ensure logs directory exists
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir);
}

// Connect to database
connectDB();

// Initialize Redis
createRedisClient();

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = initSocket(server);

// Make io available globally
app.set('io', io);

// Metrics middleware
app.use(metricsMiddleware);
app.use(metricsRouter);

// Enable CORS
app.use(cors({
  origin: process.env.NODE_ENV === 'development' ? '*' : [
    'https://yourdomain.com',
    'https://app.yourdomain.com'
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
}));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Set security headers
app.use(helmet());

// Logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev', {
    stream: { write: (message) => logger.info(message.trim()) }
  }));
} else {
  app.use(morgan('combined', {
    stream: { write: (message) => logger.info(message.trim()) }
  }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: process.env.NODE_ENV === 'production' ? 100 : 500,
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Set static folder for uploads
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
app.use('/uploads', express.static(uploadsDir));

// Swagger Documentation (only in dev/staging)
if (process.env.NODE_ENV !== 'production') {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
}

// Mount routers
app.use('/api/v1/auth', require('./routes/authRoutes'));
app.use('/api/v1/users', require('./routes/userRoutes'));
app.use('/api/v1/drivers', require('./routes/driverRoutes'));
app.use('/api/v1/rides', require('./routes/rideRoutes'));
app.use('/api/v1/ride', require('./routes/rideSingularRoutes'));
app.use('/api/v1/driver/auth', require('./routes/driverAuthRoutes'));
app.use('/api/v1/driver', require('./routes/driverSingularRoutes'));
app.use('/api/v1/admin', require('./routes/adminRoutes'));
app.use('/api/v1/maps', require('./routes/mapsRoutes'));
app.use('/api/v1/vendor', require('./routes/vendorRoutes'));
app.use('/api/v1/support-tickets', require('./routes/supportTicketRoutes'));
app.use('/api/v1/driver-earnings', require('./routes/driverEarningRoutes'));
app.use('/api/v1/wallets', require('./routes/walletRoutes'));
app.use('/api/v1/coupons', require('./routes/couponRoutes'));
// Email routes (handles OTP, verification, forgot password, and generic sends)
app.use('/api/v1/email', require('./src/routes/email.routes'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to Taxi Nanban API' });
});

// Error handler middleware
app.use(errorHandler);

const PORT = process.env.PORT || 5001;

if (require.main === module) {
  server.listen(PORT, "0.0.0.0", async () => {
    logger.info(`Server running in ${process.env.NODE_ENV} mode on port ${PORT} (0.0.0.0)`);
    // Verify SMTP transporter but don't crash the server if email fails to connect.
    try {
      const EmailService = require('./src/services/email.service');
      await EmailService.verifyTransporter();
    } catch (err) {
      logger.warn('SMTP verification failed at startup: %s', err.message || err);
    }
  });
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err, promise) => {
  logger.error('Unhandled Rejection:', err);
  // Close server & exit process
  // server.close(() => process.exit(1));
});

module.exports = { app, server };

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});
