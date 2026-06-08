const client = require('prom-client');
const express = require('express');

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 5, 15, 50, 100, 300, 500, 1000, 3000, 5000],
});

const httpRequestCount = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

const activeUsers = new client.Gauge({
  name: 'active_users',
  help: 'Number of active users',
});

register.registerMetric(httpRequestDurationMicroseconds);
register.registerMetric(httpRequestCount);
register.registerMetric(activeUsers);

const metricsMiddleware = (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route ? req.route.path : req.path;
    httpRequestDurationMicroseconds
      .labels(req.method, route, res.statusCode)
      .observe(duration);
    httpRequestCount
      .labels(req.method, route, res.statusCode)
      .inc();
  });
  next();
};

const metricsRouter = express.Router();
metricsRouter.get('/metrics', async (req, res) => {
  res.setHeader('Content-Type', register.contentType);
  res.send(await register.metrics());
});

module.exports = {
  metricsMiddleware,
  metricsRouter,
  activeUsers,
};
