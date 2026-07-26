import 'api_service.dart';

class GameData {
  final String id;
  final String name;
  final String description;
  final String category;
  final int minReward;
  final int maxReward;

  GameData({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.minReward = 5,
    this.maxReward = 50,
  });

  factory GameData.fromJson(Map<String, dynamic> json) {
    return GameData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Game',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'arcade',
      minReward: json['minReward'] as int? ?? 5,
      maxReward: json['maxReward'] as int? ?? 50,
    );
  }
}

class RewardData {
  final String id;
  final String name;
  final String category;
  final int cost;
  final double value;
  final String description;

  RewardData({
    required this.id,
    required this.name,
    required this.category,
    required this.cost,
    required this.value,
    required this.description,
  });

  factory RewardData.fromJson(Map<String, dynamic> json) {
    return RewardData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      cost: json['cost'] as int? ?? 0,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

class GameService {
  GameService._();
  static final GameService instance = GameService._();

  Future<List<GameData>> getGames() async {
    final response = await ApiService.instance.get('/api/games');
    final list = response['games'] as List<dynamic>? ?? [];
    return list.map((e) => GameData.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> startSession(String gameId) async {
    final response = await ApiService.instance.post('/api/games/session/start', {
      'gameId': gameId,
    });
    return response['sessionId'] as String;
  }

  Future<void> updateSession(String sessionId, {required int score, required int duration}) async {
    await ApiService.instance.put('/api/games/session/$sessionId', {
      'score': score,
      'duration': duration,
    });
  }

  Future<int> endSession(String sessionId, {bool won = true}) async {
    final response = await ApiService.instance.post('/api/games/session/$sessionId/end', {
      'won': won,
    });
    return response['reward'] as int? ?? 0;
  }

  Future<List<RewardData>> getRewards({String? category}) async {
    final path = category != null ? '/api/rewards?category=$category' : '/api/rewards';
    final response = await ApiService.instance.get(path);
    final list = response['rewards'] as List<dynamic>? ?? [];
    return list.map((e) => RewardData.fromJson(e as Map<String, dynamic>)).toList();
  }
}
