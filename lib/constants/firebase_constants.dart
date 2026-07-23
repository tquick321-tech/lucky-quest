class FirebaseConstants {
  // Project Configuration
  static const String projectId = 'lucky-quest-production';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String walletsCollection = 'wallets';
  static const String transactionsCollection = 'transactions';
  static const String gamesCollection = 'games';
  static const String gameSessionsCollection = 'game_sessions';
  static const String rewardsCollection = 'rewards';
  static const String withdrawalsCollection = 'withdrawals';
  static const String challengesCollection = 'challenges';
  static const String userChallengesCollection = 'user_challenges';
  static const String referralsCollection = 'referrals';
  static const String referralRecordsCollection = 'referral_records';
  static const String vipCollection = 'vip';
  static const String userVipCollection = 'user_vip';
  static const String achievementsCollection = 'achievements';
  static const String userAchievementsCollection = 'user_achievements';
  static const String cosmeticsCollection = 'cosmetics';
  static const String userCosmeticsCollection = 'user_cosmetics';
  static const String seasonPassCollection = 'season_pass';
  static const String userSeasonPassCollection = 'user_season_pass';
  static const String analyticsCollection = 'analytics';
  
  // Remote Config Keys
  static const String keyMaintenanceMode = 'maintenance_mode';
  static const String keyMinAppVersion = 'min_app_version';
  static const String keyForceUpdate = 'force_update';
  static const String keyAdFrequency = 'ad_frequency';
  static const String keyRewardMultipliers = 'reward_multipliers';
  
  // Storage Paths
  static const String avatarsPath = 'avatars';
  static const String framesPath = 'frames';
  static const String themesPath = 'themes';
  static const String gameAssetsPath = 'game_assets';
  static const String promotionalImagesPath = 'promotional_images';
  
  // Analytics Events
  static const String eventAppOpen = 'app_open';
  static const String eventGamePlayed = 'game_played';
  static const String eventRewardClaimed = 'reward_claimed';
  static const String eventPurchaseMade = 'purchase_made';
  static const String eventAdWatched = 'ad_watched';
  static const String eventReferralUsed = 'referral_used';
  static const String eventLevelUp = 'level_up';
  static const String eventVipUpgrade = 'vip_upgrade';
}
