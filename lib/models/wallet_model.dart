class WalletModel {
  final String uid;
  final int availableBalance;
  final int pendingBalance;
  final int frozenBalance;
  final DateTime lastUpdated;

  WalletModel({
    required this.uid,
    required this.availableBalance,
    required this.pendingBalance,
    required this.frozenBalance,
    required this.lastUpdated,
  });

  factory WalletModel.fromMap(Map<String, dynamic> data) {
    return WalletModel(
      uid: data['uid'] ?? '',
      availableBalance: data['availableBalance'] ?? 0,
      pendingBalance: data['pendingBalance'] ?? 0,
      frozenBalance: data['frozenBalance'] ?? 0,
      lastUpdated: data['lastUpdated'] is DateTime
          ? data['lastUpdated'] as DateTime
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'availableBalance': availableBalance,
      'pendingBalance': pendingBalance,
      'frozenBalance': frozenBalance,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  WalletModel copyWith({
    String? uid,
    int? availableBalance,
    int? pendingBalance,
    int? frozenBalance,
    DateTime? lastUpdated,
  }) {
    return WalletModel(
      uid: uid ?? this.uid,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      frozenBalance: frozenBalance ?? this.frozenBalance,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class TransactionModel {
  final String id;
  final String uid;
  final TransactionType type;
  final int amount;
  final TransactionStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? relatedId;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.status,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.relatedId,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data) {
    return TransactionModel(
      id: data['id'] ?? '',
      uid: data['uid'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.other,
      ),
      amount: data['amount'] ?? 0,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: data['description'],
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.now(),
      completedAt: data['completedAt'] is DateTime
          ? data['completedAt'] as DateTime
          : null,
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type.name,
      'amount': amount,
      'status': status.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'relatedId': relatedId,
    };
  }
}

enum TransactionType {
  earned,
  spent,
  withdrawal,
  deposit,
  bonus,
  referral,
  other,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}
