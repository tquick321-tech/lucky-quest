const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Generate referral code
router.post('/generate', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();

    if (userData.referralCode) {
      return res.json({ referralCode: userData.referralCode });
    }

    // Generate new referral code
    const referralCode = generateReferralCode();

    await db.collection('users').doc(req.user.uid).update({
      referralCode: referralCode,
    });

    res.json({ referralCode });
  } catch (error) {
    console.error('Generate referral code error:', error);
    res.status(500).json({ error: 'Failed to generate referral code' });
  }
});

// Apply referral code
router.post('/apply', authenticateToken, [
  body('referralCode').notEmpty().isLength({ min: 6, max: 10 }),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { referralCode } = req.body;
    const db = require('../config/firebase').getFirestore();

    // Check if user already used a referral
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    const userData = userDoc.data();

    if (userData.referredBy) {
      return res.status(400).json({ error: 'Already used a referral code' });
    }

    // Find referrer
    const referrerSnapshot = await db.collection('users')
      .where('referralCode', '==', referralCode)
      .limit(1)
      .get();

    if (referrerSnapshot.empty) {
      return res.status(404).json({ error: 'Invalid referral code' });
    }

    const referrerDoc = referrerSnapshot.docs[0];
    const referrerId = referrerDoc.id;

    if (referrerId === req.user.uid) {
      return res.status(400).json({ error: 'Cannot use your own referral code' });
    }

    await db.runTransaction(async (transaction) => {
      const referrerBonus = 500;
      const refereeBonus = 250;

      // Update referrer
      const referrerRef = db.collection('users').doc(referrerId);
      transaction.update(referrerRef, {
        referralsCount: FieldValue.increment(1),
        totalReferralEarnings: FieldValue.increment(referrerBonus),
      });

      // Add coins to referrer wallet
      const referrerWalletRef = db.collection('wallets').doc(referrerId);
      const referrerWalletDoc = await transaction.get(referrerWalletRef);

      if (referrerWalletDoc.exists) {
        const walletData = referrerWalletDoc.data();
        const newBalance = walletData.availableBalance + referrerBonus;
        transaction.update(referrerWalletRef, {
          availableBalance: newBalance,
          lastUpdated: new Date(),
        });

        // Create transaction for referrer
        const transactionRef = db.collection('transactions').doc();
        transaction.set(transactionRef, {
          id: transactionRef.id,
          uid: referrerId,
          type: 'credit',
          amount: referrerBonus,
          balanceAfter: newBalance,
          transactionType: 'referral_bonus',
          description: 'Referral bonus',
          relatedId: req.user.uid,
          relatedType: 'referral',
          status: 'completed',
          createdAt: new Date(),
          metadata: {},
        });
      }

      // Update referee
      const refereeRef = db.collection('users').doc(req.user.uid);
      transaction.update(refereeRef, {
        referredBy: referrerId,
        referredAt: new Date(),
      });

      // Add coins to referee wallet
      const refereeWalletRef = db.collection('wallets').doc(req.user.uid);
      const refereeWalletDoc = await transaction.get(refereeWalletRef);

      if (refereeWalletDoc.exists) {
        const walletData = refereeWalletDoc.data();
        const newBalance = walletData.availableBalance + refereeBonus;
        transaction.update(refereeWalletRef, {
          availableBalance: newBalance,
          lastUpdated: new Date(),
        });

        // Create transaction for referee
        const transactionRef = db.collection('transactions').doc();
        transaction.set(transactionRef, {
          id: transactionRef.id,
          uid: req.user.uid,
          type: 'credit',
          amount: refereeBonus,
          balanceAfter: newBalance,
          transactionType: 'referral_bonus',
          description: 'Referral welcome bonus',
          relatedId: referrerId,
          relatedType: 'referral',
          status: 'completed',
          createdAt: new Date(),
          metadata: {},
        });
      }

      // Create referral record
      const referralRecordRef = db.collection('referral_records').doc();
      transaction.set(referralRecordRef, {
        id: referralRecordRef.id,
        referrerId: referrerId,
        refereeId: req.user.uid,
        referralCode: referralCode,
        referrerBonus: referrerBonus,
        refereeBonus: refereeBonus,
        status: 'completed',
        completedAt: new Date(),
        metadata: {},
      });
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Apply referral code error:', error);
    res.status(500).json({ error: 'Failed to apply referral code' });
  }
});

// Get referral records
router.get('/records', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    
    // Get referrals made by user
    const referrerSnapshot = await db.collection('referral_records')
      .where('referrerId', '==', req.user.uid)
      .orderBy('completedAt', 'desc')
      .get();

    // Get referral used by user
    const refereeSnapshot = await db.collection('referral_records')
      .where('refereeId', '==', req.user.uid)
      .limit(1)
      .get();

    const referrals = referrerSnapshot.docs.map(doc => doc.data());
    const usedReferral = refereeSnapshot.docs.length > 0 ? refereeSnapshot.docs[0].data() : null;

    res.json({
      referrals,
      usedReferral,
      totalEarnings: referrals.reduce((sum, r) => sum + r.referrerBonus, 0),
    });
  } catch (error) {
    console.error('Get referral records error:', error);
    res.status(500).json({ error: 'Failed to fetch referral records' });
  }
});

// Get referral stats
router.get('/stats', authenticateToken, async (req, res) => {
  try {
    const db = require('../config/firebase').getFirestore();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();

    res.json({
      referralCode: userData.referralCode,
      referralsCount: userData.referralsCount,
      totalReferralEarnings: userData.totalReferralEarnings,
      referredBy: userData.referredBy,
      referredAt: userData.referredAt,
    });
  } catch (error) {
    console.error('Get referral stats error:', error);
    res.status(500).json({ error: 'Failed to fetch referral stats' });
  }
});

function generateReferralCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const random = Date.now();
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars[(random + i) % chars.length];
  }
  return code;
}

module.exports = router;
