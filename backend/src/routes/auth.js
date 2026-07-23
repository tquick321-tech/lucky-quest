const express = require('express');
const { body, validationResult } = require('express-validator');
const { getAuth } = require('../config/firebase');
const { generateToken, authRateLimiter } = require('../middleware/auth');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

// Register user
router.post('/register', authRateLimiter, [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('username').isLength({ min: 3, max: 20 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { email, password, username } = req.body;
    const auth = getAuth();

    const userRecord = await auth.createUser({
      email,
      password,
      displayName: username,
    });

    // Create user document in Firestore
    const db = require('../config/firebase').getFirestore();
    await db.collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email,
      username,
      displayName: username,
      createdAt: new Date(),
      lastLoginAt: new Date(),
      lastActiveAt: new Date(),
      totalCoins: 0,
      availableCoins: 0,
      pendingCoins: 0,
      frozenCoins: 0,
      lifetimeEarnings: 0,
      lifetimeSpent: 0,
      gamesPlayed: 0,
      totalWins: 0,
      totalLosses: 0,
      currentStreak: 0,
      maxStreak: 0,
      xp: 0,
      level: 1,
      vipTier: 'bronze',
      vipProgress: 0,
      isPremium: false,
      achievements: [],
      friends: [],
      referralCode: generateReferralCode(),
      referralsCount: 0,
      totalReferralEarnings: 0,
      settings: {
        darkMode: false,
        soundEnabled: true,
        musicEnabled: true,
        hapticEnabled: true,
        notificationsEnabled: true,
        language: 'en',
      },
      statistics: {
        totalPlayTime: 0,
        totalAdsWatched: 0,
        totalOffersCompleted: 0,
        totalWheelSpins: 0,
        totalChestsOpened: 0,
      },
      blockedUsers: [],
      isBanned: false,
      isVerified: false,
      deviceFingerprint: req.body.deviceFingerprint,
      lastIpAddress: req.ip,
      metadata: {},
    });

    // Create wallet
    await db.collection('wallets').doc(userRecord.uid).set({
      uid: userRecord.uid,
      availableBalance: 0,
      pendingBalance: 0,
      frozenBalance: 0,
      totalWithdrawals: 0,
      totalDeposits: 0,
      lastUpdated: new Date(),
      currency: 'LC',
    });

    const token = generateToken({ uid: userRecord.uid, email });

    res.status(201).json({
      token,
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        username,
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login
router.post('/login', authRateLimiter, [
  body('email').isEmail().normalizeEmail(),
  body('password').exists(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { email, password } = req.body;
    const auth = getAuth();

    // Note: Firebase Admin SDK doesn't have direct login, 
    // this would typically be handled by Firebase Client SDK
    // For backend, we verify the token from client
    
    res.status(501).json({ 
      error: 'Login should be handled by Firebase Client SDK' 
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Verify token
router.post('/verify', async (req, res) => {
  try {
    const { token } = req.body;
    const auth = getAuth();
    
    const decoded = await auth.verifyIdToken(token);
    
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(decoded.uid).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    
    if (userData.isBanned) {
      return res.status(403).json({ error: 'Account is banned', reason: userData.banReason });
    }

    res.json({
      valid: true,
      user: {
        uid: decoded.uid,
        email: decoded.email,
        username: userData.username,
        vipTier: userData.vipTier,
        isPremium: userData.isPremium,
      },
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

function generateReferralCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const random = Date.now();
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[(random + i) % chars.length];
  }
  return code;
}

module.exports = router;
