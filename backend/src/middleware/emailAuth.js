// Simple API key middleware for internal email routes
module.exports = function emailApiKey(req, res, next) {
  const apiKey = process.env.EMAIL_API_KEY;
  // If no API key configured, allow (useful for local/dev)
  if (!apiKey) return next();

  const provided = req.headers['x-email-api-key'] || req.query.api_key || req.body.api_key;
  if (!provided || provided !== apiKey) {
    return res.status(401).json({ success: false, message: 'Unauthorized: missing or invalid email API key' });
  }
  return next();
};
