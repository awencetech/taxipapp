const redis = require('redis');
const logger = require('./logger');

let redisClient;
let redisAttempted = false;

const createRedisClient = async () => {
  if (redisAttempted) return redisClient;
  redisAttempted = true;
  
  try {
    redisClient = redis.createClient({
      socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379,
        reconnectStrategy: false // Disable auto-reconnect to stop repeated errors
      },
      password: process.env.REDIS_PASSWORD || undefined,
    });

    // Only log critical Redis errors once
    redisClient.on('error', (err) => {
      if (!redisClient._loggedError) {
        logger.warn('Redis unavailable - running without caching', { code: err.code });
        redisClient._loggedError = true;
      }
    });

    redisClient.on('connect', () => {
      logger.info('Redis Client Connected');
    });

    await redisClient.connect();
    return redisClient;
  } catch (error) {
    logger.warn('Redis unavailable - running without caching');
    redisClient = null;
    return null;
  }
};

const getCache = async (key) => {
  if (!redisClient) return null;
  try {
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    // Silently fail - no need to log every cache miss
    return null;
  }
};

const setCache = async (key, value, ttl = 3600) => {
  if (!redisClient) return;
  try {
    await redisClient.setEx(key, ttl, JSON.stringify(value));
  } catch (error) {
    // Silently fail
  }
};

const deleteCache = async (key) => {
  if (!redisClient) return;
  try {
    await redisClient.del(key);
  } catch (error) {
    // Silently fail
  }
};

const deleteCachePattern = async (pattern) => {
  if (!redisClient) return;
  try {
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  } catch (error) {
    // Silently fail
  }
};

module.exports = {
  createRedisClient,
  getCache,
  setCache,
  deleteCache,
  deleteCachePattern,
};
