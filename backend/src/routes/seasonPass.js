const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get current season pass
router.get('/current', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const now = new Date();

    const snapshot = await db.collection('season_pass')
      .where('startDate', '<=', now)
      .where('endDate', '>=', now)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'No active season pass' });
    }

    const seasonPass = snapshot.docs[0].data();

    res.json(seasonPass);
  } catch (error) {
    console.error('Get season pass error:', error);
    res.status(500).json({ error: 'Failed to fetch season pass' });
  }
});

// Get user season pass progress
router.get('/progress', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const now = new Date();

    // Get current season pass
    const seasonSnapshot = await db.collection('season_pass')
      .where('startDate', '<=', now)
      .where('endDate', '>=', now)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (seasonSnapshot.empty) {
      return res.status(404).json({ error: 'No active season pass' });
    }

    const seasonPassId = seasonSnapshot.docs[0].id;

    // Get user progress
    const userProgressDoc = await db.collection('user_season_pass')
      .doc(`${req.user.uid}_${seasonPassId}`)
      .get();

    if (!userProgressDoc.exists) {
      return res.json({
        currentLevel: 0,
        xp: 0,
        isPremium: false,
        claimedFreeRewards: [],
        claimedPremiumRewards: [],
      });
    }

    const progressData = userProgressDoc.data();

    res.json(progressData);
  } catch (error) {
    console.error('Get season pass progress error:', error);
    res.status(500).json({ error: 'Failed to fetch progress' });
  }
});

// Add XP to season pass
router.post('/xp', authenticateToken, [
  body('xp').isInt({ min: 1 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { xp } = req.body;
    const db = require('../config/firebase').getFirestore();
    const now = new Date();

    // Get current season pass
    const seasonSnapshot = await db.collection('season_pass')
      .where('startDate', '<=', now)
      .where('endDate', '>=', now)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (seasonSnapshot.empty) {
      return res.status(404).json({ error: 'No active season pass' });
    }

    const seasonPassId = seasonSnapshot.docs[0].id;
    const seasonPassData = seasonSnapshot.docs[0].data();

    const userProgressRef = db.collection('user_season_pass').doc(`${req.user.uid}_${seasonPassId}`);
    const userProgressDoc = await userProgressRef.get();

    if (!userProgressDoc.exists) {
      await userProgressRef.set({
        id: `${req.user.uid}_${seasonPassId}`,
        uid: req.user.uid,
        seasonPassId: seasonPassId,
        currentLevel: 0,
        xp: xp,
        isPremium: false,
        claimedFreeRewards: [],
        claimedPremiumRewards: [],
        metadata: {},
      });
    } else {
      const progressData = userProgressDoc.data();
      const newXP = progressData.xp + xp;
      const xpPerLevel = 100;
      const newLevel = Math.floor(newXP / xpPerLevel);

      await userProgressRef.update({
        xp: newXP,
        currentLevel: Math.min(newLevel, seasonPassData.totalLevels),
      });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Add season pass XP error:', error);
    res.status(500).json({ error: 'Failed to add XP' });
  }
});

// Purchase premium season pass
router.post('/purchase', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const now = new Date();

    // Get current season pass
    const seasonSnapshot = await db.collection('season_pass')
      .where('startDate', '<=', now)
      .where('endDate', '>=', now)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (seasonSnapshot.empty) {
      return res.status(404).json({ error: 'No active season pass' });
    }

    const seasonPassId = seasonSnapshot.docs[0].id;
    const seasonPassData = seasonSnapshot.docs[0].data();

    const userProgressRef = db.collection('user_season_pass').doc(`${req.user.uid}_${seasonPassId}`);
    const userProgressDoc = await userProgressRef.get();

    if (!userProgressDoc.exists) {
      await userProgressRef.set({
        id: `${req.user.uid}_${seasonPassId}`,
        uid: req.user.uid,
        seasonPassId: seasonPassId,
        currentLevel: 0,
        xp: 0,
        isPremium: true,
        purchasedAt: new Date(),
        price: seasonPassData.premiumPrice,
        claimedFreeRewards: [],
        claimedPremiumRewards: [],
        metadata: {},
      });
    } else {
      await userProgressRef.update({
        isPremium: true,
        purchasedAt: new Date(),
        price: seasonPassData.premiumPrice,
      });
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Purchase season pass error:', error);
    res.status(500).json({ error: 'Failed to purchase season pass' });
  }
});

// Claim season pass reward
router.post('/claim', authenticateToken, [
  body('level').isInt({ min: 1 }),
  body('isPremium').isBoolean(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { level, isPremium } = req.body;
    const db = require('../config/firebase').getFirestore();
    const now = new Date();

    // Get current season pass
    const seasonSnapshot = await db.collection('season_pass')
      .where('startDate', '<=', now)
      .where('endDate', '>=', now)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (seasonSnapshot.empty) {
      return res.status(404).json({ error: 'No active season pass' });
    }

    const seasonPassId = seasonSnapshot.docs[0].id;
    const seasonPassData = seasonSnapshot.docs[0].data();

    const userProgressRef = db.collection('user_season_pass').doc(`${req.user.uid}_${seasonPassId}`);
    const userProgressDoc = await userProgressRef.get();

    if (!userProgressDoc.exists) {
      return res.status(404).json({ error: 'User progress not found' });
    }

    const progressData = userProgressDoc.data();

    if (isPremium && !progressData.isPremium) {
      return res.status(403).json({ error: 'Premium pass required' });
    }

    if (level > progressData.currentLevel) {
      return res.status(400).json({ error: 'Level not reached' });
    }

    const claimedRewards = isPremium 
      ? progressData.claimedPremiumRewards 
      : progressData.claimedFreeRewards;

    if (claimedRewards.includes(level)) {
      return res.status(400).json({ error: 'Reward already claimed' });
    }

    const rewards = isPremium ? seasonPassData.premiumRewards : seasonPassData.freeRewards;
    const reward = rewards.find(r => r.level === level);

    if (!reward) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    await db.runTransaction(async (transaction) => {
      // Add reward to wallet
      if (reward.type === 'coins') {
        const walletRef = db.collection('wallets').doc(req.user.uid);
        const walletDoc = await transaction.get(walletRef);

        if (walletDoc.exists) {
          const walletData = walletDoc.data();
          const newBalance = walletData.availableBalance + reward.quantity;
          transaction.update(walletRef, {
            availableBalance: newBalance,
            lastUpdated: new Date(),
          });

          // Create transaction
          const transactionRef = db.collection('transactions').doc();
          transaction.set(transactionRef, {
            id: transactionRef.id,
            uid: req.user.uid,
            type: 'credit',
            amount: reward.quantity,
            balanceAfter: newBalance,
            transactionType: 'season_pass_reward',
            description: 'Season pass reward',
            relatedId: seasonPassId,
            relatedType: 'season_pass',
            status: 'completed',
            createdAt: new Date(),
            metadata: {},
          });
        }

        // Update user stats
        const userRef = db.collection('users').doc(req.user.uid);
        transaction.update(userRef, {
          totalCoins: FieldValue.increment(reward.quantity),
          availableCoins: FieldValue.increment(reward.quantity),
          lifetimeEarnings: FieldValue.increment(reward.quantity),
        });
      }

      // Update claimed rewards
      const claimedField = isPremium ? 'claimedPremiumRewards' : 'claimedFreeRewards';
      transaction.update(userProgressRef, {
        [claimedField]: FieldValue.arrayUnion([level]),
      });
    });

    res.json({ success: true, reward });
  } catch (error) {
    console.error('Claim season pass reward error:', error);
    res.status(500).json({ error: 'Failed to claim reward' });
  }
});

module.exports = router;
