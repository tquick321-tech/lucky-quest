class RevenuePeriod {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double totalRevenue;
  final double revenueShareAmount;
  final int totalCoinsEarned;
  final int activeUsers;
  final bool isProcessed;
  final DateTime? processedAt;

  RevenuePeriod({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.totalRevenue,
    required this.revenueShareAmount,
    required this.totalCoinsEarned,
    required this.activeUsers,
    required this.isProcessed,
    this.processedAt,
  });

  factory RevenuePeriod.fromMap(Map<String, dynamic> data) {
    return RevenuePeriod(
      id: data['id'] ?? '',
      startTime: data['startTime'] is DateTime
          ? data['startTime'] as DateTime
          : DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] is DateTime
          ? data['endTime'] as DateTime
          : DateTime.parse(data['endTime'] as String),
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      revenueShareAmount: (data['revenueShareAmount'] as num).toDouble(),
      totalCoinsEarned: data['totalCoinsEarned'] as int? ?? 0,
      activeUsers: data['activeUsers'] as int? ?? 0,
      isProcessed: data['isProcessed'] as bool? ?? false,
      processedAt: data['processedAt'] is DateTime
          ? data['processedAt'] as DateTime
          : (data['processedAt'] != null ? DateTime.parse(data['processedAt'] as String) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalRevenue': totalRevenue,
      'revenueShareAmount': revenueShareAmount,
      'totalCoinsEarned': totalCoinsEarned,
      'activeUsers': activeUsers,
      'isProcessed': isProcessed,
      'processedAt': processedAt?.toIso8601String(),
    };
  }
}

class UserRevenueShare {
  final String id;
  final String userId;
  final String periodId;
  final int coinsEarned;
  final double shareAmount;
  final double conversionRate;
  final DateTime createdAt;

  UserRevenueShare({
    required this.id,
    required this.userId,
    required this.periodId,
    required this.coinsEarned,
    required this.shareAmount,
    required this.conversionRate,
    required this.createdAt,
  });

  factory UserRevenueShare.fromMap(Map<String, dynamic> data) {
    return UserRevenueShare(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      periodId: data['periodId'] ?? '',
      coinsEarned: data['coinsEarned'] as int? ?? 0,
      shareAmount: (data['shareAmount'] as num).toDouble(),
      conversionRate: (data['conversionRate'] as num).toDouble(),
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'periodId': periodId,
      'coinsEarned': coinsEarned,
      'shareAmount': shareAmount,
      'conversionRate': conversionRate,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CoinConversion {
  final String id;
  final String userId;
  final int coinsConverted;
  final double moneyReceived;
  final DateTime convertedAt;
  final String periodId;

  CoinConversion({
    required this.id,
    required this.userId,
    required this.coinsConverted,
    required this.moneyReceived,
    required this.convertedAt,
    required this.periodId,
  });

  factory CoinConversion.fromMap(Map<String, dynamic> data) {
    return CoinConversion(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      coinsConverted: data['coinsConverted'] as int? ?? 0,
      moneyReceived: (data['moneyReceived'] as num).toDouble(),
      convertedAt: data['convertedAt'] is DateTime
          ? data['convertedAt'] as DateTime
          : DateTime.parse(data['convertedAt'] as String),
      periodId: data['periodId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'coinsConverted': coinsConverted,
      'moneyReceived': moneyReceived,
      'convertedAt': convertedAt.toIso8601String(),
      'periodId': periodId,
    };
  }
}
