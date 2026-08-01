import 'package:flutter/material.dart';
import '../services/revenue_sharing_service.dart';

abstract class BaseGameScreen extends StatefulWidget {
  final String gameId;
  final String gameName;
  final int minReward;
  final int maxReward;

  const BaseGameScreen({
    super.key,
    required this.gameId,
    required this.gameName,
    this.minReward = 5,
    this.maxReward = 50,
  });

  @override
  State<BaseGameScreen> createState();
}

abstract class BaseGameState<T extends BaseGameScreen> extends State<T> {
  int score = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  int reward = 0;
  DateTime? startTime;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  void _initializeUserId() {
    // In production, get current user from AuthService
    currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      startTime = DateTime.now();
    });
  }

  void endGame({bool won = true}) {
    if (!isPlaying) return;
    
    final duration = startTime != null 
        ? DateTime.now().difference(startTime!).inSeconds 
        : 0;
    
    // Calculate reward based on score and duration
    reward = calculateReward(score, duration, won);
    
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });

    // Track coin earnings for revenue sharing
    if (won && reward > 0 && currentUserId != null) {
      RevenueSharingService.instance.trackUserCoins(currentUserId!, reward);
    }

    // Show result dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showResultDialog(won);
    });
  }

  int calculateReward(int score, int duration, bool won) {
    if (!won) return 0;
    
    final baseReward = widget.minReward + (score * 2);
    final timeBonus = (duration > 0) ? (10 ~/ duration) : 0;
    final calculatedReward = baseReward + timeBonus;
    
    return calculatedReward.clamp(widget.minReward, widget.maxReward);
  }

  void _showResultDialog(bool won) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? 'Congratulations!' : 'Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score'),
            const SizedBox(height: 8),
            Text('Reward: $reward LC'),
            const SizedBox(height: 4),
            Text(
              'Coins will be converted to cash every 3 hours',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }
}
