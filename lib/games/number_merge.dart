import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class NumberMergeGame extends BaseGameScreen {
  const NumberMergeGame({
    super.key,
    String gameId = 'number_merge',
    String gameName = 'Number Merge',
    int minReward = 10,
    int maxReward = 80,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<NumberMergeGame> createState() => _NumberMergeGameState();
}

class _NumberMergeGameState extends BaseGameState<NumberMergeGame> {
  final List<List<int>> _grid = [];
  final int _gridSize = 4;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _grid.clear();
    for (int i = 0; i < _gridSize; i++) {
      _grid.add(List<int>.filled(_gridSize, 0));
    }
    
    _addRandomTile();
    _addRandomTile();
    
    setState(() {
      score = 0;
    });
  }

  void _addRandomTile() {
    final emptyCells = <List<int>>[];
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == 0) {
          emptyCells.add([i, j]);
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final randomCell = emptyCells[GameUtils.getRandomInt(0, emptyCells.length - 1)];
      _grid[randomCell[0]][randomCell[1]] = GameUtils.getRandomInt(1, 2) == 1 ? 2 : 4;
    }
  }

  void _moveLeft() {
    bool moved = false;
    for (int i = 0; i < _gridSize; i++) {
      final row = _grid[i].where((cell) => cell != 0).toList();
      
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          score += row[j];
          row.removeAt(j + 1);
        }
      }

      while (row.length < _gridSize) {
        row.add(0);
      }

      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] != row[j]) {
          moved = true;
        }
        _grid[i][j] = row[j];
      }
    }

    if (moved) {
      _addRandomTile();
      _checkGameState();
    }
    setState(() {});
  }

  void _moveRight() {
    bool moved = false;
    for (int i = 0; i < _gridSize; i++) {
      final row = _grid[i].where((cell) => cell != 0).toList();
      row.reversed.toList();
      
      for (int j = row.length - 1; j > 0; j--) {
        if (row[j] == row[j - 1]) {
          row[j] *= 2;
          score += row[j];
          row.removeAt(j - 1);
        }
      }

      while (row.length < _gridSize) {
        row.insert(0, 0);
      }

      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] != row[j]) {
          moved = true;
        }
        _grid[i][j] = row[j];
      }
    }

    if (moved) {
      _addRandomTile();
      _checkGameState();
    }
    setState(() {});
  }

  void _moveUp() {
    bool moved = false;
    for (int j = 0; j < _gridSize; j++) {
      final col = <int>[];
      for (int i = 0; i < _gridSize; i++) {
        if (_grid[i][j] != 0) {
          col.add(_grid[i][j]);
        }
      }

      for (int i = 0; i < col.length - 1; i++) {
        if (col[i] == col[i + 1]) {
          col[i] *= 2;
          score += col[i];
          col.removeAt(i + 1);
        }
      }

      while (col.length < _gridSize) {
        col.add(0);
      }

      for (int i = 0; i < _gridSize; i++) {
        if (_grid[i][j] != col[i]) {
          moved = true;
        }
        _grid[i][j] = col[i];
      }
    }

    if (moved) {
      _addRandomTile();
      _checkGameState();
    }
    setState(() {});
  }

  void _moveDown() {
    bool moved = false;
    for (int j = 0; j < _gridSize; j++) {
      final col = <int>[];
      for (int i = 0; i < _gridSize; i++) {
        if (_grid[i][j] != 0) {
          col.add(_grid[i][j]);
        }
      }
      col.reversed.toList();

      for (int i = col.length - 1; i > 0; i--) {
        if (col[i] == col[i - 1]) {
          col[i] *= 2;
          score += col[i];
          col.removeAt(i - 1);
        }
      }

      while (col.length < _gridSize) {
        col.insert(0, 0);
      }

      for (int i = 0; i < _gridSize; i++) {
        if (_grid[i][j] != col[i]) {
          moved = true;
        }
        _grid[i][j] = col[i];
      }
    }

    if (moved) {
      _addRandomTile();
      _checkGameState();
    }
    setState(() {});
  }

  void _checkGameState() {
    if (score > _highScore) {
      _highScore = score;
    }

    // Check for 2048 tile
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == 2048) {
          endGame(won: true);
          return;
        }
      }
    }

    // Check if no moves available
    if (!_canMove()) {
      endGame(won: false);
    }
  }

  bool _canMove() {
    // Check for empty cells
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j] == 0) return true;
      }
    }

    // Check for possible merges
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (j < _gridSize - 1 && _grid[i][j] == _grid[i][j + 1]) return true;
        if (i < _gridSize - 1 && _grid[i][j] == _grid[i + 1][j]) return true;
      }
    }

    return false;
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
                    _buildStat('Score', score.toString()),
                    _buildStat('Best', _highScore.toString()),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: _buildGrid(),
              ),
            ),
            const SizedBox(height: 24),
            _buildControls(),
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

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _gridSize * _gridSize,
        itemBuilder: (context, index) {
          final row = index ~/ _gridSize;
          final col = index % _gridSize;
          return _buildTile(_grid[row][col]);
        },
      ),
    );
  }

  Widget _buildTile(int value) {
    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(value),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          value > 0 ? value.toString() : '',
          style: TextStyle(
            fontSize: value > 100 ? 20 : 28,
            fontWeight: FontWeight.bold,
            color: value > 4 ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0: return Colors.grey.shade200;
      case 2: return const Color(0xFFEEE4DA);
      case 4: return const Color(0xFFEDE0C8);
      case 8: return const Color(0xFFF2B179);
      case 16: return const Color(0xFFF59563);
      case 32: return const Color(0xFFF67C5F);
      case 64: return const Color(0xFFF65E3B);
      case 128: return const Color(0xFFEDCF72);
      case 256: return const Color(0xFFEDCC61);
      case 512: return const Color(0xFFEDC850);
      case 1024: return const Color(0xFFEDC53F);
      case 2048: return const Color(0xFFEDC22E);
      default: return AppTheme.primaryColor;
    }
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(Icons.arrow_upward, _moveUp),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(Icons.arrow_back, _moveLeft),
            const SizedBox(width: 16),
            _buildControlButton(Icons.arrow_forward, _moveRight),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(Icons.arrow_downward, _moveDown),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: const CircleBorder(),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
