const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { getFirestore, FieldValue } = require('../config/firestore');
const economy = require('../config/economy');

const router = express.Router();

const DEFAULT_REWARDS = [
  {
    id: 'paypal-5',
    name: '$5 PayPal Cash',
    category: 'paypal',
    cost: 5000,
    value: 5.0,
    currency: 'USD',
    isActive: true,
    description: 'Redeem for $5 via PayPal',
  },
  {
    id: 'paypal-10',
    name: '$10 PayPal Cash',
    category: 'paypal',
    cost: 10000,
    value: 10.0,
    currency: 'USD',
    isActive: true,
    description: 'Redeem for $10 via PayPal',
  },
  {
    id: 'amazon-5',
    name: '$5 Amazon Gift Card',
    category: 'gift_card',
    cost: 5000,
    value: 5.0,
    currency: 'USD',
    isActive: true,
    description: 'Amazon.com gift card',
  },
  {
    id: 'google-5',
    name: '$5 Google Play Gift Card',
    category: 'gift_card',
    cost: 5000,
    value: 5.0,
    currency: 'USD',
    isActive: true,
    description: 'Google Play Store credit',
  },
];

async function ensureDefaultRewards(db) {
  const snapshot = await db.collection('rewards').limit(1).get();
  if (!snapshot.empty) return;

  const batch = db.batch();
  for (const reward of DEFAULT_REWARDS) {
    batch.set(db.collection('rewards').doc(reward.id), {
      ...reward,
      createdAt: new Date(),
    });
  }
  await batch.commit();
}

router.get('/', authenticateToken, async (req, res) => {
  try {
    const { category } = req.query;
    const db = getFirestore();
    await ensureDefaultRewards(db);

    let query = db.collection('rewards').where('isActive', '==', true);
    if (category) {
      query = query.where('category', '==', category);
    }

    const snapshot = await query.get();
    const rewards = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ rewards });
  } catch (error) {
    console.error('Get rewards error:', error);
    res.status(500).json({ error: 'Failed to fetch rewards' });
  }
});

router.get('/:rewardId', authenticateToken, async (req, res) => {
  try {
    const { rewardId } = req.params;
    const db = getFirestore();
    const rewardDoc = await db.collection('rewards').doc(rewardId).get();

    if (!rewardDoc.exists) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    res.json({ id: rewardDoc.id, ...rewardDoc.data() });
  } catch (error) {
    console.error('Get reward error:', error);
    res.status(500).json({ error: 'Failed to fetch reward' });
  }
});

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
    const db = getFirestore();

    const rewardDoc = await db.collection('rewards').doc(rewardId).get();
    if (!rewardDoc.exists) {
      return res.status(404).json({ error: 'Reward not found' });
    }

    const rewardData = rewardDoc.data();
    if (rewardData.cost < economy.limits.minWithdrawal) {
      return res.status(400).json({ error: 'Reward below minimum withdrawal' });
    }

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) throw new Error('Wallet not found');

      const walletData = walletDoc.data();
      if (walletData.availableBalance < rewardData.cost) {
        throw new Error('Insufficient balance');
      }

      const newBalance = walletData.availableBalance - rewardData.cost;
      const newFrozen = walletData.frozenBalance + rewardData.cost;

      transaction.update(walletRef, {
        availableBalance: newBalance,
        frozenBalance: newFrozen,
        lastUpdated: new Date(),
      });

      const withdrawalRef = db.collection('withdrawal_requests').doc();
      transaction.set(withdrawalRef, {
        id: withdrawalRef.id,
        uid: req.user.uid,
        amount: rewardData.cost,
        currency: 'USD',
        destination,
        method: rewardData.category === 'paypal' ? 'paypal' : 'gift_card',
        rewardId,
        rewardName: rewardData.name,
        status: 'pending',
        requestedAt: new Date(),
        metadata: {},
      });

      const txRef = db.collection('transactions').doc();
      transaction.set(txRef, {
        id: txRef.id,
        uid: req.user.uid,
        type: 'debit',
        amount: rewardData.cost,
        balanceAfter: newBalance,
        transactionType: 'withdrawal',
        description: `Redeemed: ${rewardData.name}`,
        relatedId: withdrawalRef.id,
        relatedType: 'withdrawal_request',
        status: 'pending',
        createdAt: new Date(),
        metadata: {},
      });

      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        availableCoins: FieldValue.increment(-rewardData.cost),
        lifetimeSpent: FieldValue.increment(rewardData.cost),
      });
    });

    res.json({ success: true, message: 'Redemption submitted for review' });
  } catch (error) {
    console.error('Redeem error:', error);
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ error: 'Insufficient balance' });
    }
    res.status(500).json({ error: 'Failed to redeem reward' });
  }
});

module.exports = router;
