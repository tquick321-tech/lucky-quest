import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class ColorMatchGame extends BaseGameScreen {
  const ColorMatchGame({
    super.key,
    String gameId = 'color_match',
    String gameName = 'Color Match',
    int minReward = 5,
    int maxReward = 50,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchGameState extends BaseGameState<ColorMatchGame> {
  final List<Color> _colors = [];
  Color _targetColor = Colors.transparent;
  int _round = 1;
  final int _maxRounds = 10;
  int _timeLeft = 30;
  Timer? _timer;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _startNewRound();
  }

  void _startNewRound() {
    final distinctColors = GameUtils.getRandomDistinctColors(4);
    setState(() {
      _colors.clear();
      _colors.addAll(distinctColors);
      _targetColor = _colors[GameUtils.getRandomInt(0, 3)];
      _timeLeft = 30;
      _isTimerRunning = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    setState(() {
      _isTimerRunning = false;
    });
    endGame(won: false);
  }

  void _selectColor(Color selectedColor) {
    if (!_isTimerRunning) return;

    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });

    if (selectedColor == _targetColor) {
      score += 5 + _timeLeft;
      if (_round < _maxRounds) {
        _round++;
        Future.delayed(const Duration(milliseconds: 500), () {
          _startNewRound();
        });
      } else {
        endGame(won: true);
      }
    } else {
      endGame(won: false);
    }
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      _round = 1;
      score = 0;
      isGameOver = false;
    });
    _startNewRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
                    _buildStat('Round', '$_round/$_maxRounds'),
                    _buildStat('Time', '$_timeLeft'),
                    _buildStat('Score', '$score'),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (!isGameOver) ...[
              Text(
                'Find this color:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _targetColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Select the matching color:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    return _buildColorButton(_colors[index]);
                  },
                ),
              ),
            ],
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

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => _selectColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
