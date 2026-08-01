class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int totalCoins;
  final int lifetimeEarnings;
  final int gamesPlayed;
  final int totalWins;
  final int currentStreak;
  final int maxStreak;
  final int xp;
  final int level;
  final String vipTier;
  final List<String> achievements;
  final List<String> friends;
  final String referralCode;
  final int referralsCount;
  final bool isPremium;
  final Map<String, dynamic> settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.totalCoins,
    required this.lifetimeEarnings,
    required this.gamesPlayed,
    required this.totalWins,
    required this.currentStreak,
    required this.maxStreak,
    required this.xp,
    required this.level,
    required this.vipTier,
    required this.achievements,
    required this.friends,
    required this.referralCode,
    required this.referralsCount,
    required this.isPremium,
    required this.settings,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] is DateTime
          ? data['lastLoginAt'] as DateTime
          : DateTime.now(),
      totalCoins: data['totalCoins'] ?? 0,
      lifetimeEarnings: data['lifetimeEarnings'] ?? 0,
      gamesPlayed: data['gamesPlayed'] ?? 0,
      totalWins: data['totalWins'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      vipTier: data['vipTier'] ?? 'bronze',
      achievements: List<String>.from(data['achievements'] ?? []),
      friends: List<String>.from(data['friends'] ?? []),
      referralCode: data['referralCode'] ?? '',
      referralsCount: data['referralsCount'] ?? 0,
      isPremium: data['isPremium'] ?? false,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'totalCoins': totalCoins,
      'lifetimeEarnings': lifetimeEarnings,
      'gamesPlayed': gamesPlayed,
      'totalWins': totalWins,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'xp': xp,
      'level': level,
      'vipTier': vipTier,
      'achievements': achievements,
      'friends': friends,
      'referralCode': referralCode,
      'referralsCount': referralsCount,
      'isPremium': isPremium,
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalCoins,
    int? lifetimeEarnings,
    int? gamesPlayed,
    int? totalWins,
    int? currentStreak,
    int? maxStreak,
    int? xp,
    int? level,
    String? vipTier,
    List<String>? achievements,
    List<String>? friends,
    String? referralCode,
    int? referralsCount,
    bool? isPremium,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalCoins: totalCoins ?? this.totalCoins,
      lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalWins: totalWins ?? this.totalWins,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      vipTier: vipTier ?? this.vipTier,
      achievements: achievements ?? this.achievements,
      friends: friends ?? this.friends,
      referralCode: referralCode ?? this.referralCode,
      referralsCount: referralsCount ?? this.referralsCount,
      isPremium: isPremium ?? this.isPremium,
      settings: settings ?? this.settings,
    );
  }
}
