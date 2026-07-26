const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const { gameRateLimiter } = require('../middleware/rateLimiter');
const { getFirestore, FieldValue } = require('../config/firestore');
const economy = require('../config/economy');
const fraudDetection = require('../middleware/fraudDetection');

const router = express.Router();

const DEFAULT_GAMES = [
  {
    id: 'tap-rush',
    name: 'Tap Rush',
    description: 'Tap as fast as you can in 30 seconds!',
    category: 'arcade',
    minReward: 5,
    maxReward: 50,
    isActive: true,
    isPublished: true,
    icon: 'touch_app',
  },
];

async function ensureDefaultGames(db) {
  const snapshot = await db.collection('games').limit(1).get();
  if (!snapshot.empty) return;

  const batch = db.batch();
  for (const game of DEFAULT_GAMES) {
    batch.set(db.collection('games').doc(game.id), {
      ...game,
      createdAt: new Date(),
    });
  }
  await batch.commit();
}

// Get available games
router.get('/', authenticateToken, async (req, res) => {
  try {
    const db = getFirestore();
    await ensureDefaultGames(db);

    const snapshot = await db.collection('games')
      .where('isActive', '==', true)
      .where('isPublished', '==', true)
      .get();

    const games = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
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
    const db = getFirestore();
    const gameDoc = await db.collection('games').doc(gameId).get();

    if (!gameDoc.exists) {
      return res.status(404).json({ error: 'Game not found' });
    }

    res.json({ id: gameDoc.id, ...gameDoc.data() });
  } catch (error) {
    console.error('Get game error:', error);
    res.status(500).json({ error: 'Failed to fetch game' });
  }
});

// Start game session
router.post('/session/start', authenticateToken, gameRateLimiter, [
  body('gameId').notEmpty(),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { gameId } = req.body;
    const db = getFirestore();

    const gameDoc = await db.collection('games').doc(gameId).get();
    if (!gameDoc.exists) {
      return res.status(404).json({ error: 'Game not found' });
    }

    const gameData = gameDoc.data();
    const sessionRef = db.collection('game_sessions').doc();

    await sessionRef.set({
      id: sessionRef.id,
      uid: req.user.uid,
      gameId,
      gameName: gameData.name,
      score: 0,
      duration: 0,
      status: 'active',
      startedAt: new Date(),
      endedAt: null,
      reward: 0,
      metadata: {},
    });

    res.json({
      sessionId: sessionRef.id,
      game: { id: gameDoc.id, ...gameData },
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
    const { score, duration } = req.body;
    const db = getFirestore();

    const sessionRef = db.collection('game_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();
    if (sessionData.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await sessionRef.update({ score, duration, lastUpdated: new Date() });
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
    const { won = true } = req.body;
    const db = getFirestore();

    const sessionRef = db.collection('game_sessions').doc(sessionId);
    const sessionDoc = await sessionRef.get();

    if (!sessionDoc.exists) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const sessionData = sessionDoc.data();
    if (sessionData.uid !== req.user.uid) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (sessionData.status !== 'active') {
      return res.status(400).json({ error: 'Session already ended' });
    }

    if (sessionData.duration < economy.rewards.minSessionSeconds) {
      return res.status(400).json({ error: 'Session too short to earn rewards' });
    }

    const isSuspicious = await fraudDetection.checkSuspiciousActivity(
      req.user.uid,
      'game_reward',
      { sessionId, score: sessionData.score }
    );
    if (isSuspicious) {
      return res.status(429).json({ error: 'Activity flagged for review' });
    }

    const reward = economy.calculateGameReward({
      score: sessionData.score,
      durationSeconds: sessionData.duration,
    });

    await db.runTransaction(async (transaction) => {
      transaction.update(sessionRef, {
        status: won ? 'won' : 'lost',
        endedAt: new Date(),
        reward,
      });

      const walletRef = db.collection('wallets').doc(req.user.uid);
      const walletDoc = await transaction.get(walletRef);

      if (walletDoc.exists) {
        const newBalance = walletDoc.data().availableBalance + reward;
        transaction.update(walletRef, {
          availableBalance: newBalance,
          lastUpdated: new Date(),
        });

        const txRef = db.collection('transactions').doc();
        transaction.set(txRef, {
          id: txRef.id,
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

      const userRef = db.collection('users').doc(req.user.uid);
      transaction.update(userRef, {
        totalCoins: FieldValue.increment(reward),
        availableCoins: FieldValue.increment(reward),
        lifetimeEarnings: FieldValue.increment(reward),
        gamesPlayed: FieldValue.increment(1),
        totalWins: won ? FieldValue.increment(1) : FieldValue.increment(0),
        totalLosses: won ? FieldValue.increment(0) : FieldValue.increment(1),
        'statistics.totalPlayTime': FieldValue.increment(sessionData.duration),
      });
    });

    res.json({ success: true, reward });
  } catch (error) {
    console.error('End session error:', error);
    res.status(500).json({ error: 'Failed to end session' });
  }
});

// Get user game sessions
router.get('/sessions/history', authenticateToken, async (req, res) => {
  try {
    const { limit = 20 } = req.query;
    const db = getFirestore();

    const snapshot = await db.collection('game_sessions')
      .where('uid', '==', req.user.uid)
      .orderBy('startedAt', 'desc')
      .limit(parseInt(limit))
      .get();

    const sessions = snapshot.docs.map(doc => doc.data());
    res.json({ sessions, total: snapshot.size });
  } catch (error) {
    console.error('Get sessions error:', error);
    res.status(500).json({ error: 'Failed to fetch sessions' });
  }
});

module.exports = router;
