const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { getFirestore, FieldValue } = require('../config/firestore');
const economy = require('../config/economy');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

// Get wallet
router.get('/', authenticateToken, async (req, res) => {
  try {
    const db = getFirestore();
    const walletDoc = await db.collection('wallets').doc(req.user.uid).get();

    if (!walletDoc.exists) {
      return res.status(404).json({ error: 'Wallet not found' });
    }

    res.json(walletDoc.data());
  } catch (error) {
    console.error('Get wallet error:', error);
    res.status(500).json({ error: 'Failed to fetch wallet' });
  }
});

// Get transaction history
router.get('/transactions', authenticateToken, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const db = getFirestore();

    const snapshot = await db.collection('transactions')
      .where('uid', '==', req.user.uid)
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const transactions = snapshot.docs.map(doc => doc.data());

    res.json({ transactions, total: snapshot.size });
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

// Add coins (internal use)
router.post('/add', authenticateToken, [
  body('amount').isInt({ min: 1 }),
  body('type').isIn(['game_reward', 'challenge_reward', 'referral_bonus', 'daily_bonus', 'ad_reward', 'admin_grant']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { amount, type, description, relatedId, relatedType } = req.body;
    const db = getFirestore();

    // Check for suspicious activity
    const isSuspicious = await fraudDetection.checkSuspiciousActivity(req.user.uid, 'add_coins', { amount, type });
    if (isSuspicious) {
      return res.status(429).json({ error: 'Activity flagged for review' });
    }

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const walletData = walletDoc.data();
      const newBalance = walletData.availableBalance + amount;

      transaction.update(walletRef, {
        availableBalance: newBalance,
        lastUpdated: new Date(),
      });

      // Create transaction record
      const transactionRef = db.collection('transactions').doc();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        uid: req.user.uid,
        type: 'credit',
        amount: amount,
        balanceAfter: newBalance,
        transactionType: type,
        description: description || `Coins added: ${type}`,
        relatedId: relatedId || null,
        relatedType: relatedType || null,
        status: 'completed',
        createdAt: new Date(),
        metadata: {},
      });

      // Update user total coins
      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        totalCoins: FieldValue.increment(amount),
        availableCoins: FieldValue.increment(amount),
        lifetimeEarnings: FieldValue.increment(amount),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Add coins error:', error);
    res.status(500).json({ error: 'Failed to add coins' });
  }
});

// Deduct coins
router.post('/deduct', authenticateToken, [
  body('amount').isInt({ min: 1 }),
  body('type').isIn(['purchase', 'withdrawal', 'chest_open', 'game_cost']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { amount, type, description, relatedId, relatedType } = req.body;
    const db = getFirestore();

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const walletData = walletDoc.data();

      if (walletData.availableBalance < amount) {
        throw new Error('Insufficient balance');
      }

      const newBalance = walletData.availableBalance - amount;

      transaction.update(walletRef, {
        availableBalance: newBalance,
        lastUpdated: new Date(),
      });

      // Create transaction record
      const transactionRef = db.collection('transactions').doc();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        uid: req.user.uid,
        type: 'debit',
        amount: amount,
        balanceAfter: newBalance,
        transactionType: type,
        description: description || `Coins deducted: ${type}`,
        relatedId: relatedId || null,
        relatedType: relatedType || null,
        status: 'completed',
        createdAt: new Date(),
        metadata: {},
      });

      // Update user total coins
      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        availableCoins: FieldValue.increment(-amount),
        lifetimeSpent: FieldValue.increment(amount),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Deduct coins error:', error);
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ error: 'Insufficient balance' });
    }
    res.status(500).json({ error: 'Failed to deduct coins' });
  }
});

// Request withdrawal
router.post('/withdraw', authenticateToken, [
  body('amount').isInt({ min: economy.limits.minWithdrawal }),
  body('destination').notEmpty(),
  body('method').isIn(['paypal', 'gift_card']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { amount, destination, method, currency } = req.body;
    const db = getFirestore();

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (!walletDoc.exists) {
        throw new Error('Wallet not found');
      }

      const walletData = walletDoc.data();

      if (walletData.availableBalance < amount) {
        throw new Error('Insufficient balance');
      }

      // Freeze coins
      const newAvailableBalance = walletData.availableBalance - amount;
      const newFrozenBalance = walletData.frozenBalance + amount;

      transaction.update(walletRef, {
        availableBalance: newAvailableBalance,
        frozenBalance: newFrozenBalance,
        lastUpdated: new Date(),
      });

      // Create withdrawal request
      const withdrawalRef = db.collection('withdrawal_requests').doc();
      transaction.set(withdrawalRef, {
        id: withdrawalRef.id,
        uid: req.user.uid,
        amount: amount,
        currency: currency || 'USD',
        destination: destination,
        method: method,
        status: 'pending',
        requestedAt: new Date(),
        processedAt: null,
        rejectedAt: null,
        rejectionReason: null,
        transactionId: null,
        metadata: {},
      });

      // Create transaction record
      const transactionRef = db.collection('transactions').doc();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        uid: req.user.uid,
        type: 'debit',
        amount: amount,
        balanceAfter: newAvailableBalance,
        transactionType: 'withdrawal',
        description: `Withdrawal request: ${method}`,
        relatedId: withdrawalRef.id,
        relatedType: 'withdrawal_request',
        status: 'pending',
        createdAt: new Date(),
        metadata: {},
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Withdrawal error:', error);
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ error: 'Insufficient balance' });
    }
    res.status(500).json({ error: 'Failed to request withdrawal' });
  }
});

// Get withdrawal requests
router.get('/withdrawals', authenticateToken, async (req, res) => {
  try {
    const db = getFirestore();
    const snapshot = await db.collection('withdrawal_requests')
      .where('uid', '==', req.user.uid)
      .orderBy('requestedAt', 'desc')
      .get();

    const withdrawals = snapshot.docs.map(doc => doc.data());

    res.json({ withdrawals });
  } catch (error) {
    console.error('Get withdrawals error:', error);
    res.status(500).json({ error: 'Failed to fetch withdrawals' });
  }
});

module.exports = router;
