import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int minReward;
  final int maxReward;
  final Difficulty difficulty;
  final bool isActive;
  final int playCount;

  GameModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.minReward,
    required this.maxReward,
    required this.difficulty,
    required this.isActive,
    required this.playCount,
  });

  factory GameModel.fromMap(Map<String, dynamic> data) {
    return GameModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      icon: data['icon'] ?? '',
      minReward: data['minReward'] ?? 0,
      maxReward: data['maxReward'] ?? 0,
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => Difficulty.easy,
      ),
      isActive: data['isActive'] ?? true,
      playCount: data['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'minReward': minReward,
      'maxReward': maxReward,
      'difficulty': difficulty.name,
      'isActive': isActive,
      'playCount': playCount,
    };
  }
}

class GameSessionModel {
  final String id;
  final String uid;
  final String gameId;
  final int score;
  final int reward;
  final DateTime startedAt;
  final DateTime completedAt;
  final bool isWin;

  GameSessionModel({
    required this.id,
    required this.uid,
    required this.gameId,
    required this.score,
    required this.reward,
    required this.startedAt,
    required this.completedAt,
    required this.isWin,
  });

  factory GameSessionModel.fromMap(Map<String, dynamic> data) {
    return GameSessionModel(
      id: data['id'] ?? '',
      uid: data['uid'] ?? '',
      gameId: data['gameId'] ?? '',
      score: data['score'] ?? 0,
      reward: data['reward'] ?? 0,
      startedAt: data['startedAt']?.toDate() ?? DateTime.now(),
      completedAt: data['completedAt']?.toDate() ?? DateTime.now(),
      isWin: data['isWin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'gameId': gameId,
      'score': score,
      'reward': reward,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': Timestamp.fromDate(completedAt),
      'isWin': isWin,
    };
  }
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert,
}
