import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class MemoryMatchGame extends BaseGameScreen {
  const MemoryMatchGame({
    super.key,
    String gameId = 'memory_match',
    String gameName = 'Memory Match',
    int minReward = 10,
    int maxReward = 60,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends BaseGameState<MemoryMatchGame> {
  final List<MemoryCard> _cards = [];
  List<MemoryCard> _flippedCards = [];
  bool _isChecking = false;
  int _moves = 0;
  int _matches = 0;
  final int _totalPairs = 8;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.diamond,
      Icons.circle,
      Icons.square,
      Icons.change_history,
      Icons.crop_square,
      Icons.crop_free,
    ];

    final cardValues = [...icons, ...icons];
    final shuffledValues = GameUtils.shuffleList(cardValues);

    for (int i = 0; i < shuffledValues.length; i++) {
      _cards.add(MemoryCard(
        icon: shuffledValues[i] as IconData,
        isFlipped: false,
        isMatched: false,
      ));
    }
  }

  void _flipCard(int index) {
    if (_isChecking || _cards[index].isFlipped || _cards[index].isMatched) return;
    if (_flippedCards.length >= 2) return;

    setState(() {
      _cards[index].isFlipped = true;
      _flippedCards.add(_cards[index]);
    });

    if (_flippedCards.length == 2) {
      _moves++;
      _checkMatch();
    }
  }

  void _checkMatch() {
    setState(() {
      _isChecking = true;
    });

    final card1 = _flippedCards[0];
    final card2 = _flippedCards[1];

    if (card1.icon == card2.icon) {
      // Match found
      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        _matches++;
        _flippedCards.clear();
        _isChecking = false;
        score += 10;

        if (_matches == _totalPairs) {
          endGame(won: true);
        }
      });
    } else {
      // No match
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          card1.isFlipped = false;
          card2.isFlipped = false;
          _flippedCards.clear();
          _isChecking = false;
        });
      });
    }
  }

  void _resetGame() {
    setState(() {
      _cards.clear();
      _flippedCards.clear();
      _isChecking = false;
      _moves = 0;
      _matches = 0;
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Moves', _moves.toString()),
                    _buildStat('Matches', '$_matches/$_totalPairs'),
                    _buildStat('Score', '$score'),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
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

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: card.isFlipped || card.isMatched
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade600,
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: card.isFlipped || card.isMatched
              ? Icon(
                  card.icon,
                  size: 32,
                  color: Colors.white,
                )
              : Icon(
                  Icons.help_outline,
                  size: 32,
                  color: Colors.white.withOpacity(0.5),
                ),
        ),
      ),
    );
  }
}

class MemoryCard {
  final IconData icon;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
