/// Economy tuned so user payouts stay below estimated ad revenue.
/// 1000 LC = $1.00 USD redeemable value.
class EconomyConstants {
  static const int coinsPerDollar = 1000;
  static const double payoutRatio = 0.45;

  // Coin rewards (mirrors backend/src/config/economy.js)
  static const int rewardedAdCoins = 7;
  static const int dailyBonusCoins = 25;
  static const int coinsPerMinute = 2;
  static const int minSessionSeconds = 30;

  // Limits
  static const int maxAdsPerHour = 5;
  static const int maxAdsPerDay = 20;
  static const int minWithdrawal = 5000;
  static const int maxWithdrawalPerDay = 50000;

  /// Format coins as USD string, e.g. "5.00"
  static String coinsToUsd(int coins) {
    return (coins / coinsPerDollar).toStringAsFixed(2);
  }

  /// Format coins with thousands separator
  static String formatCoins(int coins) {
    return coins.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
