const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get available rewards
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { category } = req.query;
    const db = require('../config/firebase').getFirestore();

    let query = db.collection('rewards')
      .where('isActive', '==', true);

    if (category) {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.get();
    const rewards = snapshot.docs.map(doc => doc.data());

    res.json({ rewards });
  } catch (error) {
    console.error('Get rewards error:', error);
    res.status(500).json({ error: 'Failed to fetch rewards' });
  }
});

// Get reward by ID
router.get('/:rewardId', authenticateToken, async (req, res) => {
  try {
    const { rewardId } = req.params;
    const db = require('../config/firebase').getFirestore();
    const rewardDoc = await db.collection('rewards').doc(rewardId).get();

    if (!rewardDoc.exists) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    res.json(rewardDoc.data());
  } catch (error) {
    console.error('Get reward error:', error);
    res.status(500).json({ error: 'Failed to fetch reward' });
  }
});

// Redeem reward
router.post('/redeem', authenticateToken, [
  body('rewardId').notEmpty(),
  body('destination').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { rewardId, destination } = req.body;
    const db = require('../config/firebase').getFirestore();

    const rewardDoc = await db.collection('rewards').doc(rewardId).get();
    if (!rewardDoc.exists) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    const rewardData = rewardDoc.data();

    if (!rewardData.isActive) {
      return res.status(400).json({ error: 'Reward is not available' });
    }

    await db.runTransaction(async (transaction) => {
      // Check wallet balance
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const walletData = walletDoc.data();

      if (walletData.availableBalance < rewardData.cost) {
        throw new Error('Insufficient balance');
      }

      // Deduct coins
      const newBalance = walletData.availableBalance - rewardData.cost;
      transaction.update(walletRef, {
        availableBalance: newBalance,
        lastUpdated: new Date(),
      });

      // Create redemption request
      const redemptionRef = db.collection('redemption_requests').doc();
      transaction.set(redemptionRef, {
        id: redemptionRef.id,
        uid: req.user.uid,
        rewardId: rewardId,
        rewardName: rewardData.name,
        amount: rewardData.cost,
        destination: destination,
        status: 'pending',
        requestedAt: new Date(),
        processedAt: null,
        rejectedAt: null,
        rejectionReason: null,
        metadata: {},
      });

      // Create transaction
      const transactionRef = db.collection('transactions').doc();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        uid: req.user.uid,
        type: 'debit',
        amount: rewardData.cost,
        balanceAfter: newBalance,
        transactionType: 'reward_redemption',
        description: `Redeemed: ${rewardData.name}`,
        relatedId: redemptionRef.id,
        relatedType: 'redemption_request',
        status: 'pending',
        createdAt: new Date(),
        metadata: {},
      });

      // Update user stats
      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        availableCoins: FieldValue.increment(-rewardData.cost),
        lifetimeSpent: FieldValue.increment(rewardData.cost),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Redeem reward error:', error);
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ error: 'Insufficient balance' });
    }
    res.status(500).json({ error: 'Failed to redeem reward' });
  }
});

// Get user redemption requests
router.get('/redemptions', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const snapshot = await db.collection('redemption_requests')
      .where('uid', '==', req.user.uid)
      .orderBy('requestedAt', 'desc')
      .get();

    const redemptions = snapshot.docs.map(doc => doc.data());

    res.json({ redemptions });
  } catch (error) {
    console.error('Get redemptions error:', error);
    res.status(500).json({ error: 'Failed to fetch redemptions' });
  }
});

module.exports = router;
