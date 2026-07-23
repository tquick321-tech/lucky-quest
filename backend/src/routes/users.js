const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

// Get user profile
router.get('/profile', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    
    // Remove sensitive data
    const { deviceFingerprint, lastIpAddress, ...safeData } = userData;

    res.json(safeData);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update user profile
router.put('/profile', authenticateToken, [
  body('username').optional().isLength({ min: 3, max: 20 }),
  body('displayName').optional().isLength({ max: 50 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { username, displayName, avatarUrl } = req.body;
    const db = require('../config/firebase').getFirestore();

    const updateData = {
      lastUpdated: new Date(),
    };

    if (username) updateData.username = username;
    if (displayName) updateData.displayName = displayName;
    if (avatarUrl) updateData.avatarUrl = avatarUrl;

    await db.collection('users').doc(req.user.uid).update(updateData);

    res.json({ success: true });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Update user settings
router.put('/settings', authenticateToken, async (req, res) => {
  try {
    const { settings } = req.body;
    const db = require('../config/firebase').getFirestore();

    await db.collection('users').doc(req.user.uid).update({
      settings: settings,
      lastUpdated: new Date(),
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Failed to update settings' });
  }
});

// Update last active
router.post('/active', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const { deviceFingerprint } = req.body;

    // Check for fraud
    if (deviceFingerprint) {
      await fraudDetection.checkDeviceFingerprint(req.user.uid, deviceFingerprint);
    }
    await fraudDetection.checkIPChange(req.user.uid, req.ip);

    await db.collection('users').doc(req.user.uid).update({
      lastActiveAt: new Date(),
      lastIpAddress: req.ip,
      ...(deviceFingerprint && { deviceFingerprint }),
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Update active error:', error);
    res.status(500).json({ error: 'Failed to update activity' });
  }
});

// Get user statistics
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();

    res.json({
      gamesPlayed: userData.gamesPlayed,
      totalWins: userData.totalWins,
      totalLosses: userData.totalLosses,
      currentStreak: userData.currentStreak,
      maxStreak: userData.maxStreak,
      lifetimeEarnings: userData.lifetimeEarnings,
      lifetimeSpent: userData.lifetimeSpent,
      xp: userData.xp,
      level: userData.level,
      statistics: userData.statistics,
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// Delete user account
router.delete('/', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const auth = require('../config/firebase').getAuth();

    // Delete user from Firebase Auth
    await auth.deleteUser(req.user.uid);

    // Delete user document
    await db.collection('users').doc(req.user.uid).delete();

    // Delete wallet
    await db.collection('wallets').doc(req.user.uid).delete();

    // Delete other user-related data
    const collectionsToDelete = [
      'user_challenges',
      'user_achievements',
      'user_season_pass',
      'referral_records',
    ];

    for (const collection of collectionsToDelete) {
      const snapshot = await db.collection(collection)
        .where('uid', '==', req.user.uid)
        .get();
      
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  }
});

module.exports = router;
