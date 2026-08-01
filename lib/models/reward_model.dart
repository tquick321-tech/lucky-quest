class RewardModel {
  final String id;
  final String name;
  final RewardType type;
  final int cost;
  final String icon;
  final String description;
  final bool isActive;
  final int stock;

  RewardModel({
    required this.id,
    required this.name,
    required this.type,
    required this.cost,
    required this.icon,
    required this.description,
    required this.isActive,
    required this.stock,
  });

  factory RewardModel.fromMap(Map<String, dynamic> data) {
    return RewardModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RewardType.giftCard,
      ),
      cost: data['cost'] ?? 0,
      icon: data['icon'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      stock: data['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'cost': cost,
      'icon': icon,
      'description': description,
      'isActive': isActive,
      'stock': stock,
    };
  }
}

class WithdrawalRequestModel {
  final String id;
  final String uid;
  final String rewardId;
  final String destination;
  final int amount;
  final WithdrawalStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? adminNote;

  WithdrawalRequestModel({
    required this.id,
    required this.uid,
    required this.rewardId,
    required this.destination,
    required this.amount,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.adminNote,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> data) {
    return WithdrawalRequestModel(
      id: data['id'] ?? '',
      uid: data['uid'] ?? '',
      rewardId: data['rewardId'] ?? '',
      destination: data['destination'] ?? '',
      amount: data['amount'] ?? 0,
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      requestedAt: data['requestedAt'] is DateTime
          ? data['requestedAt'] as DateTime
          : DateTime.now(),
      processedAt: data['processedAt'] is DateTime
          ? data['processedAt'] as DateTime
          : null,
      adminNote: data['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'rewardId': rewardId,
      'destination': destination,
      'amount': amount,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'adminNote': adminNote,
    };
  }
}

enum RewardType {
  giftCard,
  paypal,
  crypto,
  merchandise,
}

enum WithdrawalStatus {
  pending,
  approved,
  rejected,
  completed,
}
