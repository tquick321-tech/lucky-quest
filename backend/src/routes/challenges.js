const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Get active challenges
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { frequency } = req.query;
    const db = require('../config/firebase').getFirestore();

    const now = new Date();
    let query = db.collection('challenges')
      .where('isActive', '==', true)
      .where('startDate', '<=', now)
      .where('endDate', '>=', now);

    if (frequency) {
      query = query.where('frequency', '==', frequency);
    }

    const snapshot = await query.get();
    const challenges = snapshot.docs.map(doc => doc.data());

    res.json({ challenges });
  } catch (error) {
    console.error('Get challenges error:', error);
    res.status(500).json({ error: 'Failed to fetch challenges' });
  }
});

// Get challenge by ID
router.get('/:challengeId', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const db = require('../config/firebase').getFirestore();
    const challengeDoc = await db.collection('challenges').doc(challengeId).get();

    if (!challengeDoc.exists) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    res.json(challengeDoc.data());
  } catch (error) {
    console.error('Get challenge error:', error);
    res.status(500).json({ error: 'Failed to fetch challenge' });
  }
});

// Get user challenge progress
router.get('/progress/:challengeId', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const db = require('../config/firebase').getFirestore();
    const progressDoc = await db.collection('user_challenges')
      .doc(`${req.user.uid}_${challengeId}`)
      .get();

    if (!progressDoc.exists) {
      return res.json({
        progress: 0,
        isCompleted: false,
        isClaimed: false,
      });
    }

    const progressData = progressDoc.data();

    res.json({
      progress: progressData.progress,
      isCompleted: progressData.isCompleted,
      isClaimed: progressData.isClaimed,
      completedAt: progressData.completedAt,
    });
  } catch (error) {
    console.error('Get progress error:', error);
    res.status(500).json({ error: 'Failed to fetch progress' });
  }
});

// Update challenge progress
router.post('/progress/:challengeId', authenticateToken, [
  body('progress').isInt({ min: 0 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { challengeId } = req.params;
    const { progress } = req.body;
    const db = require('../config/firebase').getFirestore();

    // Get challenge details
    const challengeDoc = await db.collection('challenges').doc(challengeId).get();
    if (!challengeDoc.exists) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    const challengeData = challengeDoc.data();
    const isCompleted = progress >= challengeData.target;

    const progressRef = db.collection('user_challenges').doc(`${req.user.uid}_${challengeId}`);
    const progressDoc = await progressRef.get();

    if (progressDoc.exists) {
      await progressRef.update({
        progress: progress,
        isCompleted: isCompleted,
        completedAt: isCompleted ? new Date() : null,
        lastUpdated: new Date(),
      });
    } else {
      await progressRef.set({
        id: `${req.user.uid}_${challengeId}`,
        uid: req.user.uid,
        challengeId: challengeId,
        progress: progress,
        target: challengeData.target,
        isCompleted: isCompleted,
        isClaimed: false,
        completedAt: isCompleted ? new Date() : null,
        claimedAt: null,
        lastUpdated: new Date(),
        metadata: {},
      });
    }

    res.json({
      success: true,
      isCompleted: isCompleted,
    });
  } catch (error) {
    console.error('Update progress error:', error);
    res.status(500).json({ error: 'Failed to update progress' });
  }
});

// Claim challenge reward
router.post('/claim/:challengeId', authenticateToken, async (req, res) => {
  try {
    const { challengeId } = req.params;
    const db = require('../config/firebase').getFirestore();

    const progressRef = db.collection('user_challenges').doc(`${req.user.uid}_${challengeId}`);
    const progressDoc = await progressRef.get();

    if (!progressDoc.exists) {
      return res.status(404).json({ error: 'Challenge progress not found' });
    }

    const progressData = progressDoc.data();

    if (!progressData.isCompleted) {
      return res.status(400).json({ error: 'Challenge not completed' });
    }

    if (progressData.isClaimed) {
      return res.status(400).json({ error: 'Reward already claimed' });
    }

    // Get challenge details
    const challengeDoc = await db.collection('challenges').doc(challengeId).get();
    const challengeData = challengeDoc.data();

    await db.runTransaction(async (transaction) => {
      // Add coins to wallet
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (walletDoc.exists) {
        const walletData = walletDoc.data();
        const newBalance = walletData.availableBalance + challengeData.reward;
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
          amount: challengeData.reward,
          balanceAfter: newBalance,
          transactionType: 'challenge_reward',
          description: `Challenge reward: ${challengeData.name}`,
          relatedId: challengeId,
          relatedType: 'challenge',
          status: 'completed',
          createdAt: new Date(),
          metadata: {},
        });
      }

      // Update progress
      transaction.update(progressRef, {
        isClaimed: true,
        claimedAt: new Date(),
      });

      // Update user stats
      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        totalCoins: FieldValue.increment(challengeData.reward),
        availableCoins: FieldValue.increment(challengeData.reward),
        lifetimeEarnings: FieldValue.increment(challengeData.reward),
      });
    });

    res.json({ success: true, reward: challengeData.reward });
  } catch (error) {
    console.error('Claim reward error:', error);
    res.status(500).json({ error: 'Failed to claim reward' });
  }
});

// Get all user challenges
router.get('/user/all', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const snapshot = await db.collection('user_challenges')
      .where('uid', '==', req.user.uid)
      .get();

    const challenges = snapshot.docs.map(doc => doc.data());

    res.json({ challenges });
  } catch (error) {
    console.error('Get user challenges error:', error);
    res.status(500).json({ error: 'Failed to fetch user challenges' });
  }
});

module.exports = router;
