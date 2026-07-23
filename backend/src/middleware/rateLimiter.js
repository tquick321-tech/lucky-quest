const rateLimit = require('express-rate-limit');

const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: {
    error: 'Too many authentication attempts, please try again later.',
  },
});

const gameRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: {
    error: 'Too many game requests, please slow down.',
  },
});

module.exports = {
  rateLimiter,
  authRateLimiter,
  gameRateLimiter,
};
