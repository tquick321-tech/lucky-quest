const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { getFirestore, FieldValue } = require('../config/firestore');
const economy = require('../config/economy');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

const REWARD_TYPES = {
  rewarded: economy.rewards.rewardedAd,
  daily_bonus: economy.rewards.dailyBonus,
};

// Credit coins after a verified ad impression (client shows ad, server grants reward)
router.post('/reward', authenticateToken, [
  body('adType').isIn(['rewarded', 'daily_bonus']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { adType } = req.body;
    const db = getFirestore();
    const uid = req.user.uid;
    const amount = REWARD_TYPES[adType];

    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const stats = userDoc.data().statistics || {};
    const adsToday = stats.adsToday || 0;
    const adsThisHour = stats.adsThisHour || 0;
    const lastAdAt = stats.lastAdAt?.toDate?.() || null;

    if (adsToday >= economy.limits.maxAdsPerDay) {
      return res.status(429).json({ error: 'Daily ad limit reached' });
    }

    if (adsThisHour >= economy.limits.maxAdsPerHour) {
      return res.status(429).json({ error: 'Hourly ad limit reached' });
    }

    if (adType === 'daily_bonus' && stats.dailyBonusClaimedAt) {
      const claimed = stats.dailyBonusClaimedAt.toDate();
      const now = new Date();
      if (
        claimed.getFullYear() === now.getFullYear() &&
        claimed.getMonth() === now.getMonth() &&
        claimed.getDate() === now.getDate()
      ) {
        return res.status(400).json({ error: 'Daily bonus already claimed today' });
      }
    }

    const isSuspicious = await fraudDetection.checkSuspiciousActivity(uid, 'ad_reward', { adType, amount });
    if (isSuspicious) {
      return res.status(429).json({ error: 'Activity flagged for review' });
    }

    const hourReset = lastAdAt && (Date.now() - lastAdAt.getTime()) > 3600000;

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(uid);
      const walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw new Error('Wallet not found');

      const newBalance = walletDoc.data().availableBalance + amount;
      transaction.update(walletRef, { availableBalance: newBalance, lastUpdated: new Date() });

      const txRef = db.collection('transactions').doc();
      transaction.set(txRef, {
        id: txRef.id,
        uid,
        type: 'credit',
        amount,
        balanceAfter: newBalance,
        transactionType: adType === 'daily_bonus' ? 'daily_bonus' : 'ad_reward',
        description: adType === 'daily_bonus' ? 'Daily bonus' : 'Rewarded ad',
        status: 'completed',
        createdAt: new Date(),
        metadata: { adType },
      });

      const userUpdate = {
        totalCoins: FieldValue.increment(amount),
        availableCoins: FieldValue.increment(amount),
        lifetimeEarnings: FieldValue.increment(amount),
        'statistics.totalAdsWatched': FieldValue.increment(1),
        'statistics.adsToday': FieldValue.increment(1),
        'statistics.adsThisHour': hourReset ? 1 : FieldValue.increment(1),
        'statistics.lastAdAt': new Date(),
      };

      if (adType === 'daily_bonus') {
        userUpdate['statistics.dailyBonusClaimedAt'] = new Date();
      }

      transaction.update(userRef, userUpdate);
    });

    res.json({ success: true, amount, adType });
  } catch (error) {
    console.error('Ad reward error:', error);
    res.status(500).json({ error: 'Failed to grant ad reward' });
  }
});

module.exports = router;
