const db = require('../config/firebase').getFirestore();

class FraudDetectionService {
  constructor() {
    this.suspiciousActivities = new Map();
  }

  async checkSuspiciousActivity(uid, activityType, metadata = {}) {
    const now = Date.now();
    const key = `${uid}_${activityType}`;
    
    const recentActivity = this.suspiciousActivities.get(key) || [];
    const recent = recentActivity.filter(t => now - t < 60000); // Last minute
    
    if (recent.length > 10) {
      // Flag as suspicious
      await this.flagUser(uid, activityType, 'High frequency activity', metadata);
      return true;
    }

    recent.push(now);
    this.suspiciousActivities.set(key, recent);

    return false;
  }

  async checkDeviceFingerprint(uid, deviceFingerprint) {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;

    const userData = userDoc.data();
    const storedFingerprint = userData.deviceFingerprint;

    if (storedFingerprint && storedFingerprint !== deviceFingerprint) {
      await this.flagUser(uid, 'device_mismatch', 'Device fingerprint changed', {
        old: storedFingerprint,
        new: deviceFingerprint,
      });
      return true;
    }

    return false;
  }

  async checkIPChange(uid, ipAddress) {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;

    const userData = userDoc.data();
    const lastIP = userData.lastIpAddress;

    if (lastIP && lastIP !== ipAddress) {
      await this.flagUser(uid, 'ip_change', 'IP address changed', {
        old: lastIP,
        new: ipAddress,
      });
      return true;
    }

    return false;
  }

  async flagUser(uid, flagType, reason, metadata = {}) {
    await db.collection('fraud_reports').add({
      uid,
      flagType,
      reason,
      metadata,
      timestamp: new Date(),
      status: 'pending',
    });

    // Auto-ban for severe violations
    if (this.isSevereViolation(flagType)) {
      await db.collection('users').doc(uid).update({
        isBanned: true,
        banReason: reason,
        bannedAt: new Date(),
      });
    }
  }

  isSevereViolation(flagType) {
    const severeTypes = ['device_mismatch', 'ip_change', 'account_takeover'];
    return severeTypes.includes(flagType);
  }

  async getUserFraudScore(uid) {
    const snapshot = await db
      .collection('fraud_reports')
      .where('uid', '==', uid)
      .where('status', '==', 'pending')
      .get();

    return snapshot.size;
  }
}

module.exports = new FraudDetectionService();
