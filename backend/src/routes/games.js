const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken, gameRateLimiter } = require('../middleware/auth');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

// Get available games
router.get('/', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const snapshot = await db.collection('games')
      .where('isActive', '==', true)
      .where('isPublished', '==', true)
      .get();

    const games = snapshot.docs.map(doc => doc.data());

    res.json({ games });
  } catch (error) {
    console.error('Get games error:', error);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});

// Get game by ID
router.get('/:gameId', authenticateToken, async (req, res) => {
  try {
    const { gameId } = req.params;
    const db = require('../config/firebase').getFirestore();
    const gameDoc = await db.collection('games').doc(gameId).get();

    if (!gameDoc.exists) {
      return res.status(404).json({ error: 'Game not found' });
    }

    res.json(gameDoc.data());
  } catch (error) {
    console.error('Get game error:', error);
    res.status(500).json({ error: 'Failed to fetch game' });
  }
});

// Start game session
router.post('/session/start', authenticateToken, gameRateLimiter, [
  body('gameId').notEmpty(),
  body('difficulty').optional().isIn(['easy', 'medium', 'hard']),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { gameId, difficulty } = req.body;
    const db = require('../config/firebase').getFirestore();

    // Verify game exists
    const gameDoc = await db.collection('games').doc(gameId).get();
    if (!gameDoc.exists) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const gameData = gameDoc.data();

    // Create session
    const sessionRef = db.collection('game_sessions').doc();
    await sessionRef.set({
      id: sessionRef.id,
      uid: req.user.uid,
      gameId: gameId,
      gameName: gameData.name,
      difficulty: difficulty || 'medium',
      score: 0,
      duration: 0,
      status: 'active',
      startedAt: new Date(),
      endedAt: null,
      reward: 0,
      xpEarned: 0,
      metadata: {},
    });

    res.json({
      sessionId: sessionRef.id,
      game: gameData,
    });
  } catch (error) {
    console.error('Start session error:', error);
    res.status(500).json({ error: 'Failed to start session' });
  }
});

// Update game session
router.put('/session/:sessionId', authenticateToken, [
  body('score').isInt({ min: 0 }),
  body('duration').isInt({ min: 0 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { sessionId } = req.params;
    const { score, duration, saveData } = req.body;
    const db = require('../config/firebase').getFirestore();

    const sessionRef = db.collection('game_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();

    if (sessionData.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await sessionRef.update({
      score: score,
      duration: duration,
      saveData: saveData || null,
      lastUpdated: new Date(),
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Update session error:', error);
    res.status(500).json({ error: 'Failed to update session' });
  }
});

// End game session
router.post('/session/:sessionId/end', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { won } = req.body;
    const db = require('../config/firebase').getFirestore();

    const sessionRef = db.collection('game_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();

    if (sessionData.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Calculate reward
    const baseReward = 10;
    const scoreMultiplier = Math.floor(sessionData.score / 100);
    const durationBonus = Math.floor(sessionData.duration / 60);
    const reward = baseReward + scoreMultiplier + durationBonus;
    const xpEarned = Math.floor(reward / 2);

    await db.runTransaction(async (transaction) => {
      // Update session
      transaction.update(sessionRef, {
        status: won ? 'won' : 'lost',
        endedAt: new Date(),
        reward: reward,
        xpEarned: xpEarned,
      });

      // Add coins to wallet
      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (walletDoc.exists) {
        const walletData = walletDoc.data();
        const newBalance = walletData.availableBalance + reward;
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
          amount: reward,
          balanceAfter: newBalance,
          transactionType: 'game_reward',
          description: `Game reward: ${sessionData.gameName}`,
          relatedId: sessionId,
          relatedType: 'game_session',
          status: 'completed',
          createdAt: new Date(),
          metadata: {},
        });
      }

      // Update user stats
      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        totalCoins: FieldValue.increment(reward),
        availableCoins: FieldValue.increment(reward),
        lifetimeEarnings: FieldValue.increment(reward),
        gamesPlayed: FieldValue.increment(1),
        totalWins: won ? FieldValue.increment(1) : FieldValue.increment(0),
        totalLosses: won ? FieldValue.increment(0) : FieldValue.increment(1),
        xp: FieldValue.increment(xpEarned),
      });
    });

    res.json({
      success: true,
      reward: reward,
      xpEarned: xpEarned,
    });
  } catch (error) {
    console.error('End session error:', error);
    res.status(500).json({ error: 'Failed to end session' });
  }
});

// Get user game sessions
router.get('/sessions', authenticateToken, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const db = require('../config/firebase').getFirestore();

    const snapshot = await db.collection('game_sessions')
      .where('uid', '==', req.user.uid)
      .orderBy('startedAt', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const sessions = snapshot.docs.map(doc => doc.data());

    res.json({ sessions, total: snapshot.size });
  } catch (error) {
    console.error('Get sessions error:', error);
    res.status(500).json({ error: 'Failed to fetch sessions' });
  }
});

// Save game progress
router.post('/save', authenticateToken, async (req, res) => {
  try {
    const { gameId, saveData } = req.body;
    const db = require('../config/firebase').getFirestore();

    const saveRef = db.collection('game_saves').doc();
    await saveRef.set({
      id: saveRef.id,
      uid: req.user.uid,
      gameId: gameId,
      saveData: saveData,
      savedAt: new Date(),
      metadata: {},
    });

    res.json({ success: true, saveId: saveRef.id });
  } catch (error) {
    console.error('Save game error:', error);
    res.status(500).json({ error: 'Failed to save game' });
  }
});

// Load game progress
router.get('/save/:saveId', authenticateToken, async (req, res) => {
  try {
    const { saveId } = req.params;
    const db = require('../config/firebase').getFirestore();
    const saveDoc = await db.collection('game_saves').doc(saveId).get();

    if (!saveDoc.exists) {
      return res.status(404).json({ error: 'Save not found' });
    }

    const saveData = saveDoc.data();

    if (saveData.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json(saveData);
  } catch (error) {
    console.error('Load game error:', error);
    res.status(500).json({ error: 'Failed to load game' });
  }
});

module.exports = router;
