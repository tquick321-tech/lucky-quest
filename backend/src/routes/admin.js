const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateAdmin } = require('../middleware/auth');

const router = express.Router();

// Get dashboard stats
router.get('/dashboard', authenticateAdmin, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();

    // Get user count
    const usersSnapshot = await db.collection('users').get();
    const totalUsers = usersSnapshot.size;

    // Get active users (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const activeUsersSnapshot = await db.collection('users')
      .where('lastActiveAt', '>=', sevenDaysAgo)
      .get();
    const activeUsers = activeUsersSnapshot.size;

    // Get total coins distributed
    const transactionsSnapshot = await db.collection('transactions')
      .where('type', '==', 'credit')
      .get();
    const totalCoinsDistributed = transactionsSnapshot.docs.reduce(
      (sum, doc) => sum + (doc.data().amount || 0),
      0
    );

    // Get pending withdrawals
    const withdrawalsSnapshot = await db.collection('withdrawal_requests')
      .where('status', '==', 'pending')
      .get();
    const pendingWithdrawals = withdrawalsSnapshot.size;

    // Get total revenue (from premium purchases)
    const revenueSnapshot = await db.collection('user_vip')
      .where('isPremium', '==', true)
      .get();
    const totalRevenue = revenueSnapshot.docs.reduce(
      (sum, doc) => sum + (doc.data().price || 0),
      0
    );

    res.json({
      totalUsers,
      activeUsers,
      totalCoinsDistributed,
      pendingWithdrawals,
      totalRevenue,
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// Get pending withdrawals
router.get('/withdrawals/pending', authenticateAdmin, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const snapshot = await db.collection('withdrawal_requests')
      .where('status', '==', 'pending')
      .orderBy('requestedAt', 'desc')
      .get();

    const withdrawals = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data();
        const userDoc = await db.collection('users').doc(data.uid).get();
        const userData = userDoc.exists ? userDoc.data() : null;
        return {
          ...data,
          userEmail: userData?.email,
          username: userData?.username,
        };
      })
    );

    res.json({ withdrawals });
  } catch (error) {
    console.error('Get pending withdrawals error:', error);
    res.status(500).json({ error: 'Failed to fetch pending withdrawals' });
  }
});

// Approve withdrawal
router.post('/withdrawals/:id/approve', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { transactionId } = req.body;
    const db = require('../config/firebase').getFirestore();

    await db.runTransaction(async (transaction) => {
      const withdrawalRef = db.collection('withdrawal_requests').doc(id);
      const withdrawalDoc = await transaction.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw new Error('Withdrawal not found');
      }

      const withdrawalData = withdrawalDoc.data();

      if (withdrawalData.status !== 'pending') {
        throw new Error('Withdrawal already processed');
      }

      // Update withdrawal status
      transaction.update(withdrawalRef, {
        status: 'approved',
        processedAt: new Date(),
        transactionId: transactionId,
      });

      // Update wallet (deduct from frozen)
      const walletRef = db.collection('wallets').doc(withdrawalData.uid);
      const walletDoc = await transaction.get(walletRef);

      if (walletDoc.exists) {
        const walletData = walletDoc.data();
        transaction.update(walletRef, {
          frozenBalance: walletData.frozenBalance - withdrawalData.amount,
          totalWithdrawals: walletData.totalWithdrawals + withdrawalData.amount,
          lastUpdated: new Date(),
        });

        // Update transaction
        const transactionRef = db.collection('transactions')
          .where('relatedId', '==', id)
          .where('relatedType', '==', 'withdrawal_request')
          .limit(1);

        const transactionSnapshot = await transactionRef.get();
        if (!transactionSnapshot.empty) {
          transaction.update(transactionSnapshot.docs[0].ref, {
            status: 'completed',
          });
        }
      }
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Approve withdrawal error:', error);
    res.status(500).json({ error: 'Failed to approve withdrawal' });
  }
});

// Reject withdrawal
router.post('/withdrawals/:id/reject', authenticateAdmin, [
  body('reason').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { id } = req.params;
    const { reason } = req.body;
    const db = require('../config/firebase').getFirestore();

    await db.runTransaction(async (transaction) => {
      const withdrawalRef = db.collection('withdrawal_requests').doc(id);
      const withdrawalDoc = await transaction.get(withdrawalRef);

      if (!withdrawalDoc.exists) {
        throw new Error('Withdrawal not found');
      }

      const withdrawalData = withdrawalDoc.data();

      if (withdrawalData.status !== 'pending') {
        throw new Error('Withdrawal already processed');
      }

      // Update withdrawal status
      transaction.update(withdrawalRef, {
        status: 'rejected',
        rejectedAt: new Date(),
        rejectionReason: reason,
      });

      // Refund to wallet
      const walletRef = db.collection('wallets').doc(withdrawalData.uid);
      const walletDoc = await transaction.get(walletRef);

      if (walletDoc.exists) {
        const walletData = walletDoc.data();
        const newBalance = walletData.availableBalance + withdrawalData.amount;
        transaction.update(walletRef, {
          availableBalance: newBalance,
          frozenBalance: walletData.frozenBalance - withdrawalData.amount,
          lastUpdated: new Date(),
        });

        // Create refund transaction
        const transactionRef = db.collection('transactions').doc();
        transaction.set(transactionRef, {
          id: transactionRef.id,
          uid: withdrawalData.uid,
          type: 'credit',
          amount: withdrawalData.amount,
          balanceAfter: newBalance,
          transactionType: 'withdrawal_refund',
          description: 'Withdrawal refund',
          relatedId: id,
          relatedType: 'withdrawal_request',
          status: 'completed',
          createdAt: new Date(),
          metadata: { reason },
        });
      }

      // Update user
      const userRef = db.collection('users').doc(withdrawalData.uid);
      transaction.update(userRef, {
        availableCoins: FieldValue.increment(withdrawalData.amount),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Reject withdrawal error:', error);
    res.status(500).json({ error: 'Failed to reject withdrawal' });
  }
});

// Get fraud reports
router.get('/fraud-reports', authenticateAdmin, async (req, res) => {
  try {
    const { status } = req.query;
    const db = require('../config/firebase').getFirestore();

    let query = db.collection('fraud_reports');
    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.orderBy('timestamp', 'desc').get();

    const reports = await Promise.all(
      snapshot.docs.map(async (doc) => {
        const data = doc.data();
        const userDoc = await db.collection('users').doc(data.uid).get();
        const userData = userDoc.exists ? userDoc.data() : null;
        return {
          ...data,
          userEmail: userData?.email,
          username: userData?.username,
        };
      })
    );

    res.json({ reports });
  } catch (error) {
    console.error('Get fraud reports error:', error);
    res.status(500).json({ error: 'Failed to fetch fraud reports' });
  }
});

// Ban user
router.post('/users/:uid/ban', authenticateAdmin, [
  body('reason').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { uid } = req.params;
    const { reason } = req.body;
    const db = require('../config/firebase').getFirestore();

    await db.collection('users').doc(uid).update({
      isBanned: true,
      banReason: reason,
      bannedAt: new Date(),
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Ban user error:', error);
    res.status(500).json({ error: 'Failed to ban user' });
  }
});

// Unban user
router.post('/users/:uid/unban', authenticateAdmin, async (req, res) => {
  try {
    const { uid } = req.params;
    const db = require('../config/firebase').getFirestore();

    await db.collection('users').doc(uid).update({
      isBanned: false,
      banReason: null,
      bannedAt: null,
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Unban user error:', error);
    res.status(500).json({ error: 'Failed to unban user' });
  }
});

// Grant coins to user
router.post('/users/:uid/grant', authenticateAdmin, [
  body('amount').isInt({ min: 1 }),
  body('reason').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { uid } = req.params;
    const { amount, reason } = req.body;
    const db = require('../config/firebase').getFirestore();

    await db.runTransaction(async (transaction) => {
      const walletRef = db.collection('wallets').doc(uid);
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

      // Create transaction
      const transactionRef = db.collection('transactions').doc();
      transaction.set(transactionRef, {
        id: transactionRef.id,
        uid: uid,
        type: 'credit',
        amount: amount,
        balanceAfter: newBalance,
        transactionType: 'admin_grant',
        description: reason || 'Admin grant',
        status: 'completed',
        createdAt: new Date(),
        metadata: { adminId: req.user.uid },
      });

      // Update user
      const userRef = db.collection('users').doc(uid);
      transaction.update(userRef, {
        totalCoins: FieldValue.increment(amount),
        availableCoins: FieldValue.increment(amount),
        lifetimeEarnings: FieldValue.increment(amount),
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Grant coins error:', error);
    res.status(500).json({ error: 'Failed to grant coins' });
  }
});

module.exports = router;
