const express = require('express');
const { body, validationResult } = require('express-validator');
const { getAuth } = require('../config/firebase');
const { getFirestore } = require('../config/firestore');
const { generateToken } = require('../middleware/auth');
const { authRateLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

function generateReferralCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

async function ensureUserProfile(uid, email, username) {
  const db = getFirestore();
  const userRef = db.collection('users').doc(uid);
  const userDoc = await userRef.get();

  if (userDoc.exists) {
    await userRef.update({ lastLoginAt: new Date(), lastActiveAt: new Date() });
    return userDoc.data();
  }

  const profile = {
    uid,
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
    achievements: [],
    friends: [],
    referralCode: generateReferralCode(),
    referralsCount: 0,
    totalReferralEarnings: 0,
    settings: {
      darkMode: false,
      soundEnabled: true,
      notificationsEnabled: true,
      language: 'en',
    },
    statistics: {
      totalPlayTime: 0,
      totalAdsWatched: 0,
      adsToday: 0,
      adsThisHour: 0,
      totalOffersCompleted: 0,
    },
    blockedUsers: [],
    isBanned: false,
    isVerified: false,
    metadata: {},
  };

  await userRef.set(profile);
  await db.collection('wallets').doc(uid).set({
    uid,
    availableBalance: 0,
    pendingBalance: 0,
    frozenBalance: 0,
    totalWithdrawals: 0,
    totalDeposits: 0,
    lastUpdated: new Date(),
    currency: 'LC',
  });

  return profile;
}

// Exchange Firebase ID token for app JWT (primary auth flow)
router.post('/session', authRateLimiter, [
  body('idToken').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { idToken } = req.body;
    const auth = getAuth();
    const decoded = await auth.verifyIdToken(idToken);

    const username =
      decoded.name ||
      decoded.email?.split('@')[0] ||
      `player_${decoded.uid.slice(0, 6)}`;

    const profile = await ensureUserProfile(decoded.uid, decoded.email, username);

    if (profile.isBanned) {
      return res.status(403).json({ error: 'Account is banned', reason: profile.banReason });
    }

    const token = generateToken({ uid: decoded.uid, email: decoded.email });

    res.json({
      token,
      user: {
        uid: decoded.uid,
        email: decoded.email,
        username: profile.username,
        level: profile.level,
        gamesPlayed: profile.gamesPlayed,
        totalWins: profile.totalWins,
        xp: profile.xp,
      },
    });
  } catch (error) {
    console.error('Session error:', error);
    res.status(401).json({ error: 'Invalid Firebase token' });
  }
});

// Register user (server-side, optional — prefer Firebase client + /session)
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

    await ensureUserProfile(userRecord.uid, email, username);
    const token = generateToken({ uid: userRecord.uid, email });

    res.status(201).json({
      token,
      user: { uid: userRecord.uid, email, username },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: error.message || 'Registration failed' });
  }
});

// Verify app JWT + return user profile
router.post('/verify', async (req, res) => {
  try {
    const { token } = req.body;
    const auth = getAuth();
    const decoded = await auth.verifyIdToken(token);

    const db = getFirestore();
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
        level: userData.level,
        gamesPlayed: userData.gamesPlayed,
        totalWins: userData.totalWins,
        xp: userData.xp,
      },
    });
  } catch (error) {
    console.error('Token verification error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;
