import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class ScratchCardGame extends BaseGameScreen {
  const ScratchCardGame({
    super.key,
    String gameId = 'scratch_card',
    String gameName = 'Scratch Card',
    int minReward = 5,
    int maxReward = 75,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<ScratchCardGame> createState() => _ScratchCardGameState();
}

class _ScratchCardGameState extends BaseGameState<ScratchCardGame> {
  final List<ScratchCard> _cards = [];
  int _scratchedCount = 0;
  bool _allRevealed = false;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    final rewards = [5, 10, 15, 20, 25, 30, 50, 75, 0];
    final shuffledRewards = GameUtils.shuffleList(rewards);
    
    for (int i = 0; i < 9; i++) {
      _cards.add(ScratchCard(
        reward: shuffledRewards[i],
        isRevealed: false,
      ));
    }
  }

  void _revealCard(int index) {
    if (_cards[index].isRevealed || _allRevealed) return;

    setState(() {
      _cards[index].isRevealed = true;
      _scratchedCount++;
      score += _cards[index].reward;

      if (_scratchedCount == _cards.length) {
        _allRevealed = true;
        endGame(won: score > 0);
      }
    });
  }

  void _resetGame() {
    setState(() {
      _cards.clear();
      _scratchedCount = 0;
      _allRevealed = false;
      score = 0;
      isGameOver = false;
      _initializeCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isGameOver)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Revealed: $_scratchedCount/9',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total: $score LC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    
    return GestureDetector(
      onTap: () => _revealCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: card.isRevealed
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    AppTheme.secondaryColor.withOpacity(0.3),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: card.isRevealed
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      card.reward > 0 ? Icons.monetization_on : Icons.close,
                      size: 32,
                      color: card.reward > 0 ? AppTheme.warningColor : AppTheme.errorColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.reward > 0 ? '${card.reward} LC' : 'Try Again',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: card.reward > 0 ? AppTheme.warningColor : AppTheme.errorColor,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 32,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scratch',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class ScratchCard {
  int reward;
  bool isRevealed;

  ScratchCard({required this.reward, this.isRevealed = false});
}
