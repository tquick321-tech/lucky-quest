import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/revenue_sharing_model.dart';

class RevenueSharingService {
  RevenueSharingService._();
  static final RevenueSharingService instance = RevenueSharingService._();

  Timer? _conversionTimer;
  static const Duration _conversionInterval = Duration(hours: 3);
  static const double _revenueSharePercentage = 0.5; // 50% of revenue

  final List<RevenuePeriod> _revenuePeriods = [];
  final List<UserRevenueShare> _userShares = [];
  final List<CoinConversion> _conversions = [];

  // Mock revenue data - in production this would come from ad networks, in-app purchases, etc.
  double _currentPeriodRevenue = 0.0;
  final Map<String, int> _userCoinEarnings = {}; // userId -> coins earned this period

  List<RevenuePeriod> get revenuePeriods => List.unmodifiable(_revenuePeriods);
  List<CoinConversion> get conversions => List.unmodifiable(_conversions);
  double get currentPeriodRevenue => _currentPeriodRevenue;

  void startRevenueTracking() {
    _conversionTimer?.cancel();
    _conversionTimer = Timer.periodic(_conversionInterval, (_) {
      processRevenuePeriod();
    });
    
    if (kDebugMode) {
      print('Revenue sharing service started. Conversions every ${_conversionInterval.inHours} hours.');
    }
  }

  void stopRevenueTracking() {
    _conversionTimer?.cancel();
    if (kDebugMode) {
      print('Revenue sharing service stopped.');
    }
  }

  // Track revenue from ads, purchases, etc.
  void addRevenue(double amount) {
    _currentPeriodRevenue += amount;
    if (kDebugMode) {
      print('Revenue added: \$${amount.toStringAsFixed(2)}. Total this period: \$${_currentPeriodRevenue.toStringAsFixed(2)}');
    }
  }

  // Track coins earned by users from games
  void trackUserCoins(String userId, int coins) {
    _userCoinEarnings[userId] = (_userCoinEarnings[userId] ?? 0) + coins;
    if (kDebugMode) {
      print('User $userId earned $coins coins. Total this period: ${_userCoinEarnings[userId]}');
    }
  }

  Future<void> processRevenuePeriod() async {
    if (_currentPeriodRevenue == 0 && _userCoinEarnings.isEmpty) {
      if (kDebugMode) {
        print('No revenue or coin earnings this period. Skipping conversion.');
      }
      return;
    }

    final now = DateTime.now();
    final startTime = now.subtract(_conversionInterval);
    final periodId = 'period_${now.millisecondsSinceEpoch}';

    // Calculate revenue share amount (50% of total revenue)
    final revenueShareAmount = _currentPeriodRevenue * _revenueSharePercentage;
    
    // Calculate total coins earned by all users
    final totalCoinsEarned = _userCoinEarnings.values.fold(0, (sum, coins) => sum + coins);
    final activeUsers = _userCoinEarnings.length;

    // Create revenue period record
    final period = RevenuePeriod(
      id: periodId,
      startTime: startTime,
      endTime: now,
      totalRevenue: _currentPeriodRevenue,
      revenueShareAmount: revenueShareAmount,
      totalCoinsEarned: totalCoinsEarned,
      activeUsers: activeUsers,
      isProcessed: true,
      processedAt: now,
    );

    _revenuePeriods.add(period);

    // Calculate and distribute shares among users
    if (totalCoinsEarned > 0 && revenueShareAmount > 0) {
      await _distributeRevenueShares(periodId, totalCoinsEarned, revenueShareAmount);
    }

    // Reset for next period
    _currentPeriodRevenue = 0.0;
    _userCoinEarnings.clear();

    if (kDebugMode) {
      print('Revenue period processed: \$${revenueShareAmount.toStringAsFixed(2)} distributed among $activeUsers users');
    }
  }

  Future<void> _distributeRevenueShares(String periodId, int totalCoins, double totalShareAmount) async {
    final conversionRate = totalCoins > 0 ? totalShareAmount / totalCoins : 0.0;

    for (final entry in _userCoinEarnings.entries) {
      final userId = entry.key;
      final coinsEarned = entry.value;
      final shareAmount = coinsEarned * conversionRate;

      // Create user revenue share record
      final userShare = UserRevenueShare(
        id: 'share_${userId}_${periodId}',
        userId: userId,
        periodId: periodId,
        coinsEarned: coinsEarned,
        shareAmount: shareAmount,
        conversionRate: conversionRate,
        createdAt: DateTime.now(),
      );

      _userShares.add(userShare);

      // Create coin conversion record
      final conversion = CoinConversion(
        id: 'conv_${userId}_${periodId}',
        userId: userId,
        coinsConverted: coinsEarned,
        moneyReceived: shareAmount,
        convertedAt: DateTime.now(),
        periodId: periodId,
      );

      _conversions.add(conversion);

      // In production, this would update the user's wallet via API
      await _updateUserWallet(userId, shareAmount);

      if (kDebugMode) {
        print('User $userId: $coinsEarned coins → \$${shareAmount.toStringAsFixed(2)} (rate: \$${conversionRate.toStringAsFixed(4)}/coin)');
      }
    }
  }

  Future<void> _updateUserWallet(String userId, double amount) async {
    try {
      // In production, call API to update wallet
      // await ApiService.instance.post('/api/wallet/add', {
      //   'userId': userId,
      //   'amount': amount,
      //   'type': 'revenue_share',
      // });
      
      if (kDebugMode) {
        print('Wallet updated for $userId: +\$${amount.toStringAsFixed(2)}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating wallet for $userId: $e');
      }
    }
  }

  List<UserRevenueShare> getUserShares(String userId) {
    return _userShares.where((share) => share.userId == userId).toList();
  }

  List<CoinConversion> getUserConversions(String userId) {
    return _conversions.where((conv) => conv.userId == userId).toList();
  }

  double getUserTotalEarnings(String userId) {
    return getUserConversions(userId).fold(0.0, (sum, conv) => sum + conv.moneyReceived);
  }

  RevenuePeriod? getCurrentPeriod() {
    if (_revenuePeriods.isEmpty) return null;
    return _revenuePeriods.last;
  }

  Map<String, dynamic> getRevenueStats() {
    final totalRevenue = _revenuePeriods.fold(0.0, (sum, period) => sum + period.totalRevenue);
    final totalShared = _revenuePeriods.fold(0.0, (sum, period) => sum + period.revenueShareAmount);
    final totalConversions = _conversions.length;
    final totalUsers = _userShares.map((share) => share.userId).toSet().length;

    return {
      'totalRevenue': totalRevenue,
      'totalShared': totalShared,
      'totalConversions': totalConversions,
      'totalUsers': totalUsers,
      'periodsProcessed': _revenuePeriods.length,
    };
  }

  void dispose() {
    stopRevenueTracking();
  }
}
