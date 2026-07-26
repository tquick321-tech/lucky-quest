import 'api_service.dart';

class WalletData {
  final int availableBalance;
  final int pendingBalance;
  final int frozenBalance;

  WalletData({
    required this.availableBalance,
    this.pendingBalance = 0,
    this.frozenBalance = 0,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      availableBalance: json['availableBalance'] as int? ?? 0,
      pendingBalance: json['pendingBalance'] as int? ?? 0,
      frozenBalance: json['frozenBalance'] as int? ?? 0,
    );
  }
}

class TransactionData {
  final String id;
  final String type;
  final int amount;
  final String transactionType;
  final String description;
  final String status;
  final DateTime? createdAt;

  TransactionData({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      transactionType: json['transactionType'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  Future<WalletData> getWallet() async {
    final response = await ApiService.instance.get('/api/wallet');
    return WalletData.fromJson(response);
  }

  Future<List<TransactionData>> getTransactions({int limit = 20}) async {
    final response = await ApiService.instance.get('/api/wallet/transactions?limit=$limit');
    final list = response['transactions'] as List<dynamic>? ?? [];
    return list.map((e) => TransactionData.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> claimAdReward(String adType) async {
    final response = await ApiService.instance.post('/api/ads/reward', {'adType': adType});
    return response['amount'] as int? ?? 0;
  }

  Future<void> redeemReward({
    required String rewardId,
    required String destination,
  }) async {
    await ApiService.instance.post('/api/rewards/redeem', {
      'rewardId': rewardId,
      'destination': destination,
    });
  }
}
