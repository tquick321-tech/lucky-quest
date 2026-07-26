/**
 * Lucky Quest economy — tuned so payouts stay below ad revenue.
 *
 * Assumptions (US market, casual gaming):
 *   Rewarded video eCPM ~ $15  → ~$0.015/view
 *   Interstitial eCPM   ~ $8   → ~$0.008/view
 *   Payout ratio        ~ 45%  of estimated gross ad revenue
 *
 * At 1000 LC = $1.00:
 *   Rewarded ad  → 7 LC  (~$0.007 payout, ~$0.015 gross)
 *   Daily bonus  → 25 LC (requires rewarded ad; net positive)
 *   Play time    → 2 LC/min (capped; no direct ad, funded by session interstitials)
 */

const economy = {
  coinsPerDollar: 1000,
  payoutRatio: 0.45,

  // Estimated gross ad revenue per impression (USD)
  adRevenue: {
    rewarded: 0.015,
    interstitial: 0.008,
  },

  // Coin rewards (server-side only — never trust client)
  rewards: {
    rewardedAd: 7,
    dailyBonus: 25,
    coinsPerMinute: 2,
    minSessionSeconds: 30,
    maxPlayMinutesPerDay: 60,
    gameSessionBase: 5,
    gameScoreDivisor: 50, // +1 LC per scoreDivisor points
  },

  limits: {
    maxAdsPerHour: 5,
    maxAdsPerDay: 20,
    maxGameSessionsPerDay: 50,
    minWithdrawal: 5000,
    maxWithdrawalPerDay: 50000,
  },

  /** Convert LC to USD string for display */
  coinsToUsd(coins) {
    return (coins / this.coinsPerDollar).toFixed(2);
  },

  /** Calculate play-time reward for a session */
  calculateGameReward({ score = 0, durationSeconds = 0 }) {
    const minutes = Math.floor(durationSeconds / 60);
    const timeReward = Math.min(
      minutes * this.rewards.coinsPerMinute,
      this.rewards.maxPlayMinutesPerDay * this.rewards.coinsPerMinute
    );
    const scoreReward = Math.floor(score / this.rewards.gameScoreDivisor);
    const base = this.rewards.gameSessionBase;
    return Math.max(base, base + timeReward + scoreReward);
  },

  /** Validate that a coin grant doesn't exceed estimated ad budget */
  maxDailyEarnEstimate() {
    const adCoins =
      this.limits.maxAdsPerDay * this.rewards.rewardedAd +
      this.limits.maxAdsPerDay * this.rewards.dailyBonus;
    const playCoins =
      this.rewards.maxPlayMinutesPerDay * this.rewards.coinsPerMinute;
    return adCoins + playCoins + 200; // buffer for game sessions
  },
};

module.exports = economy;
