import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class WaterColorSortGame extends BaseGameScreen {
  const WaterColorSortGame({
    super.key,
    String gameId = 'water_color_sort',
    String gameName = 'Water Color Sort',
    int minReward = 10,
    int maxReward = 80,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<WaterColorSortGame> createState() => _WaterColorSortGameState();
}

class _WaterColorSortGameState extends BaseGameState<WaterColorSortGame> {
  final List<List<Color>> _tubes = [];
  int _selectedTubeIndex = -1;
  int _moves = 0;
  final int _tubeCapacity = 4;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];

    _tubes.clear();
    
    // Create initial tubes with mixed colors
    for (int i = 0; i < 5; i++) {
      final tubeColors = List<Color>.filled(_tubeCapacity, Colors.transparent);
      final color = colors[i % colors.length];
      
      for (int j = 0; j < _tubeCapacity; j++) {
        tubeColors[j] = gameColorMap[color] ?? color;
      }
      
      // Shuffle the tube
      final shuffled = GameUtils.shuffleList(tubeColors);
      _tubes.add(shuffled);
    }

    // Add empty tube
    _tubes.add(List<Color>.filled(_tubeCapacity, Colors.transparent));
    
    setState(() {
      _moves = 0;
      _selectedTubeIndex = -1;
      score = 0;
    });
  }

  Map<Color, Color> get gameColorMap => {
    AppTheme.primaryColor: const Color(0xFF6366F1),
    AppTheme.secondaryColor: const Color(0xFF8B5CF6),
    AppTheme.accentColor: const Color(0xFFEC4899),
    AppTheme.successColor: const Color(0xFF10B981),
    AppTheme.warningColor: const Color(0xFFF59E0B),
  };

  void _handleTubeTap(int index) {
    if (isGameOver) return;

    if (_selectedTubeIndex == -1) {
      // Select tube if it has colors
      if (_tubes[index].any((c) => c != Colors.transparent)) {
        setState(() {
          _selectedTubeIndex = index;
        });
      }
    } else {
      if (_selectedTubeIndex == index) {
        // Deselect
        setState(() {
          _selectedTubeIndex = -1;
        });
      } else {
        // Try to pour
        if (_canPour(_selectedTubeIndex, index)) {
          _pourColor(_selectedTubeIndex, index);
          setState(() {
            _moves++;
            _selectedTubeIndex = -1;
          });

          if (_checkWin()) {
            score = max(0, 100 - _moves * 2);
            endGame(won: true);
          }
        } else {
          setState(() {
            _selectedTubeIndex = -1;
          });
        }
      }
    }
  }

  bool _canPour(int fromIndex, int toIndex) {
    final fromTube = _tubes[fromIndex];
    final toTube = _tubes[toIndex];

    if (fromTube.every((c) => c == Colors.transparent)) return false;
    if (toTube.every((c) => c != Colors.transparent)) return false;

    final topColor = fromTube.lastWhere((c) => c != Colors.transparent);
    final targetColor = toTube.lastWhere((c) => c != Colors.transparent, orElse: () => Colors.transparent);

    return targetColor == Colors.transparent || targetColor == topColor;
  }

  void _pourColor(int fromIndex, int toIndex) {
    final fromTube = _tubes[fromIndex];
    final toTube = _tubes[toIndex];
    
    final topColor = fromTube.lastWhere((c) => c != Colors.transparent);
    
    // Find first empty slot in target tube
    int targetIndex = toTube.length - 1;
    while (targetIndex >= 0 && toTube[targetIndex] != Colors.transparent) {
      targetIndex--;
    }

    // Pour all matching colors
    for (int i = fromTube.length - 1; i >= 0; i--) {
      if (fromTube[i] == topColor && targetIndex >= 0) {
        toTube[targetIndex] = fromTube[i];
        fromTube[i] = Colors.transparent;
        targetIndex--;
      } else {
        break;
      }
    }
  }

  bool _checkWin() {
    for (final tube in _tubes) {
      if (tube.every((c) => c == Colors.transparent)) continue;
      
      final firstColor = tube.firstWhere((c) => c != Colors.transparent);
      if (!tube.every((c) => c == Colors.transparent || c == firstColor)) {
        return false;
      }
    }
    return true;
  }

  void _resetGame() {
    setState(() {
      isGameOver = false;
    });
    _initializeGame();
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
                    _buildStat('Score', score.toString()),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: List.generate(_tubes.length, (index) {
                    return _buildTube(index);
                  }),
                ),
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

  Widget _buildTube(int index) {
    final tube = _tubes[index];
    final isSelected = _selectedTubeIndex == index;

    return GestureDetector(
      onTap: () => _handleTubeTap(index),
      child: Container(
        width: 60,
        height: 240,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(_tubeCapacity, (i) {
            final color = tube[i];
            return Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: color == Colors.transparent ? Colors.white70 : color,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }
}
