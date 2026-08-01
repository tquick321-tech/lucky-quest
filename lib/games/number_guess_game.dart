import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class NumberGuessGame extends BaseGameScreen {
  const NumberGuessGame({
    super.key,
    String gameId = 'number_guess',
    String gameName = 'Number Guess',
    int minReward = 5,
    int maxReward = 40,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<NumberGuessGame> createState() => _NumberGuessGameState();
}

class _NumberGuessGameState extends BaseGameState<NumberGuessGame> {
  int _targetNumber = 0;
  int _currentGuess = 50;
  int _attempts = 0;
  final int _maxAttempts = 7;
  String _feedback = 'Guess a number between 1 and 100';
  List<int> _previousGuesses = [];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _targetNumber = GameUtils.getRandomInt(1, 100);
      _currentGuess = 50;
      _attempts = 0;
      _previousGuesses.clear();
      _feedback = 'Guess a number between 1 and 100';
      score = 0;
      isGameOver = false;
    });
  }

  void _makeGuess() {
    if (isGameOver) return;

    setState(() {
      _attempts++;
      _previousGuesses.add(_currentGuess);

      if (_currentGuess == _targetNumber) {
        score = (_maxAttempts - _attempts + 1) * 5;
        _feedback = '🎉 Correct! You found it in $_attempts attempts!';
        endGame(won: true);
      } else if (_attempts >= _maxAttempts) {
        _feedback = '❌ Game over! The number was $_targetNumber';
        endGame(won: false);
      } else if (_currentGuess < _targetNumber) {
        _feedback = '📈 Too low! Try higher';
      } else {
        _feedback = '📉 Too high! Try lower';
      }
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
            onPressed: _startNewGame,
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
                    _buildStat('Attempts', '$_attempts/$_maxAttempts'),
                    _buildStat('Score', '$score'),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.secondaryColor.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    _feedback,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$_currentGuess',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!isGameOver) ...[
              Slider(
                value: _currentGuess.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '$_currentGuess',
                onChanged: (value) {
                  setState(() {
                    _currentGuess = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentGuess = (_currentGuess - 10).clamp(1, 100);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                    ),
                    child: const Text('-10'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentGuess = (_currentGuess - 1).clamp(1, 100);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                    ),
                    child: const Text('-1'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentGuess = (_currentGuess + 1).clamp(1, 100);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: const Text('+1'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentGuess = (_currentGuess + 10).clamp(1, 100);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    child: const Text('+10'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _makeGuess,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text(
                  'GUESS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_previousGuesses.isNotEmpty)
              Column(
                children: [
                  const Text(
                    'Previous Guesses:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _previousGuesses.map((guess) {
                      final isCorrect = guess == _targetNumber;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppTheme.successColor
                              : AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$guess',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.white : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
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
            fontSize: 18,
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
}
