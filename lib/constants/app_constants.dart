class AppConstants {
  // App Info
  static const String appName = 'Lucky Quest';
  static const String appVersion = '1.0.0';
  
  // URLs
  static const String termsUrl = 'https://luckyquest.com/terms';
  static const String privacyUrl = 'https://luckyquest.com/privacy';
  static const String supportUrl = 'https://luckyquest.com/support';
  
  // Currency
  static const String currencySymbol = 'LC';
  static const String currencyName = 'Lucky Coins';
  
  // VIP Tiers
  static const Map<String, VIPTier> vipTiers = {
    'bronze': VIPTier(name: 'Bronze', multiplier: 1.0, threshold: 0),
    'silver': VIPTier(name: 'Silver', multiplier: 1.2, threshold: 10000),
    'gold': VIPTier(name: 'Gold', multiplier: 1.5, threshold: 50000),
    'platinum': VIPTier(name: 'Platinum', multiplier: 2.0, threshold: 100000),
    'diamond': VIPTier(name: 'Diamond', multiplier: 2.5, threshold: 250000),
  };
  
  // Chest Rarities
  static const Map<String, ChestRarity> chestRarities = {
    'common': ChestRarity(name: 'Common', color: 0xFF9E9E9E, probability: 0.5),
    'rare': ChestRarity(name: 'Rare', color: 0xFF2196F3, probability: 0.3),
    'epic': ChestRarity(name: 'Epic', color: 0xFF9C27B0, probability: 0.15),
    'legendary': ChestRarity(name: 'Legendary', color: 0xFFFF9800, probability: 0.05),
  };
  
  // Lucky Wheel Settings
  static const int wheelSpinsPerDay = 3;
  static const int wheelSegments = 8;
  
  // Daily Challenge
  static const int dailyChallengeReward = 100;
  
  // Season Pass
  static const int seasonPassLevels = 100;
  static const int seasonPassDurationDays = 90;
  
  // Withdrawal Limits
  static const int minWithdrawal = 5000;
  static const int maxWithdrawalPerDay = 50000;
  
  // Ad Frequency
  static const int maxAdsPerHour = 5;
  
  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  
  // Game Settings
  static const int maxGamesPerDay = 100;
  
  // Animation Durations
  static const int defaultAnimationDuration = 300;
  
  // Storage Keys
  static const String keyUserId = 'user_id';
  static const String keyAuthToken = 'auth_token';
  static const String keyDarkMode = 'dark_mode';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
}

class VIPTier {
  final String name;
  final double multiplier;
  final int threshold;
  
  const VIPTier({
    required this.name,
    required this.multiplier,
    required this.threshold,
  });
}

class ChestRarity {
  final String name;
  final int color;
  final double probability;
  
  const ChestRarity({
    required this.name,
    required this.color,
    required this.probability,
  });
}
