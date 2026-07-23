const express = require('express');
const { body, validationResult } = express('express-validator');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get VIP tiers
router.get('/tiers', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const snapshot = await db.collection('vip_tiers').get();

    const tiers = snapshot.docs.map(doc => doc.data());

    res.json({ tiers });
  } catch (error) {
    console.error('Get VIP tiers error:', error);
    res.status(500).json({ error: 'Failed to fetch VIP tiers' });
  }
});

// Get user VIP status
router.get('/status', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    const vipDoc = await db.collection('user_vip').doc(req.user.uid).get();

    const vipData = vipDoc.exists ? vipDoc.data() : null;

    res.json({
      currentTier: userData.vipTier,
      xp: userData.xp,
      isPremium: userData.isPremium,
      vipProgress: userData.vipProgress,
      premiumExpiresAt: vipData?.premiumExpiresAt || null,
      unlockedBenefits: vipData?.unlockedBenefits || [],
    });
  } catch (error) {
    console.error('Get VIP status error:', error);
    res.status(500).json({ error: 'Failed to fetch VIP status' });
  }
});

// Purchase premium
router.post('/purchase', authenticateToken, [
  body('duration').isIn(['monthly', 'yearly']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { duration } = req.body;
    const db = require('../config/firebase').getFirestore();

    const prices = {
      monthly: 9.99,
      yearly: 89.99,
    };

    const price = prices[duration];
    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + (duration === 'monthly' ? 1 : 12));

    await db.collection('user_vip').doc(req.user.uid).set({
      uid: req.user.uid,
      isPremium: true,
      premiumExpiresAt: expiresAt,
      purchasedAt: new Date(),
      duration: duration,
      price: price,
      unlockedBenefits: [],
      metadata: {},
    }, { merge: true });

    await db.collection('users').doc(req.user.uid).update({
      isPremium: true,
    });

    res.json({ success: true, expiresAt });
  } catch (error) {
    console.error('Purchase premium error:', error);
    res.status(500).json({ error: 'Failed to purchase premium' });
  }
});

// Update VIP progress
router.post('/progress', authenticateToken, [
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    try {
      const { xp } = req.body;
      const db = require('../config/firebase').getFirestore();

      const userDoc = await db.collection('users').doc(req.user.uid).get();
      const userData = userDoc.data();

      const newXP = userData.xp + xp;
      const newProgress = userData.vipProgress + xp;

      // Check for tier upgrade
      const tiersSnapshot = await db.collection('vip_tiers')
        .orderBy('threshold')
        .get();

      let newTier = userData.vipTier;
      for (const tierDoc of tiersSnapshot.docs) {
        const tierData = tierDoc.data();
        if (newXP >= tierData.threshold) {
          newTier = tierData.id;
        }
      }

      await db.collection('users').doc(req.user.uid).update({
        xp: newXP,
        vipProgress: newProgress,
        vipTier: newTier,
      });

      res.json({
        success: true,
        newTier: newTier,
        xp: newXP,
      });
    } catch (error) {
      console.error('Update VIP progress error:', error);
      res.status(500).json({ error: 'Failed to update VIP progress' });
    }
  }
});

// Get VIP multiplier
router.get('/multiplier', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();

    // Get tier multiplier
    const tierDoc = await db.collection('vip_tiers').doc(userData.vipTier).get();
    const tierData = tierDoc.exists ? tierDoc.data() : { multiplier: 1.0 };

    let multiplier = tierData.multiplier;

    // Add premium bonus
    if (userData.isPremium) {
      multiplier += 0.5;
    }

    res.json({ multiplier });
  } catch (error) {
    console.error('Get VIP multiplier error:', error);
    res.status(500).json({ error: 'Failed to fetch VIP multiplier' });
  }
});

module.exports = router;
