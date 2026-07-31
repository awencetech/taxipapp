const rateLimit = require('express-rate-limit');

// Generic rate limiter factory
function createRateLimiter(options = {}) {
  const {
    windowMs = 60 * 1000, // 1 minute
    max = 5,
    message = 'Too many requests, please try again later.'
  } = options;

  return rateLimit({
    windowMs,
    max,
    standardHeaders: true,
    legacyHeaders: false,
    message,
  });
}

module.exports = { createRateLimiter };
