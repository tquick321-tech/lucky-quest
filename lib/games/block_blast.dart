import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class BlockBlastGame extends BaseGameScreen {
  const BlockBlastGame({
    super.key,
    String gameId = 'block_blast',
    String gameName = 'Block Blast',
    int minReward = 10,
    int maxReward = 100,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<BlockBlastGame> createState() => _BlockBlastGameState();
}

class _BlockBlastGameState extends BaseGameState<BlockBlastGame> {
  final List<List<int>> _grid = [];
  final List<BlockShape> _availableShapes = [];
  BlockShape? _selectedShape;
  final int _gridSize = 8;
  int _linesCleared = 0;

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
    
    _generateNewShapes();
    setState(() {
      _linesCleared = 0;
      score = 0;
      _selectedShape = null;
    });
  }

  void _generateNewShapes() {
    _availableShapes.clear();
    final shapeTypes = [
      _createIShape(),
      _createLShape(),
      _createSquareShape(),
      _createTShape(),
      _createLineShape(),
    ];
    
    for (int i = 0; i < 3; i++) {
      _availableShapes.add(shapeTypes[GameUtils.getRandomInt(0, shapeTypes.length - 1)]);
    }
  }

  BlockShape _createIShape() {
    return BlockShape(
      blocks: [
        [1, 1, 1, 1],
      ],
      color: AppTheme.primaryColor,
    );
  }

  BlockShape _createLShape() {
    return BlockShape(
      blocks: [
        [1, 0],
        [1, 0],
        [1, 1],
      ],
      color: AppTheme.secondaryColor,
    );
  }

  BlockShape _createSquareShape() {
    return BlockShape(
      blocks: [
        [1, 1],
        [1, 1],
      ],
      color: AppTheme.accentColor,
    );
  }

  BlockShape _createTShape() {
    return BlockShape(
      blocks: [
        [1, 1, 1],
        [0, 1, 0],
      ],
      color: AppTheme.successColor,
    );
  }

  BlockShape _createLineShape() {
    return BlockShape(
      blocks: [
        [1],
        [1],
        [1],
      ],
      color: AppTheme.warningColor,
    );
  }

  void _selectShape(BlockShape shape) {
    setState(() {
      _selectedShape = shape;
    });
  }

  void _placeShape(int gridRow, int gridCol) {
    if (_selectedShape == null) return;

    final shape = _selectedShape!;
    final blocks = shape.blocks;

    // Check if placement is valid
    if (!_canPlaceShape(blocks, gridRow, gridCol)) {
      setState(() {
        _selectedShape = null;
      });
      return;
    }

    // Place the shape
    for (int i = 0; i < blocks.length; i++) {
      for (int j = 0; j < blocks[i].length; j++) {
        if (blocks[i][j] == 1) {
          _grid[gridRow + i][gridCol + j] = 1;
        }
      }
    }

    // Remove used shape
    _availableShapes.remove(shape);
    _selectedShape = null;

    // Check for completed lines
    _checkAndClearLines();

    // Generate new shapes if all used
    if (_availableShapes.isEmpty) {
      _generateNewShapes();
    }

    // Check if game over
    if (!_canPlaceAnyShape()) {
      endGame(won: true);
    }

    setState(() {});
  }

  bool _canPlaceShape(List<List<int>> blocks, int startRow, int startCol) {
    for (int i = 0; i < blocks.length; i++) {
      for (int j = 0; j < blocks[i].length; j++) {
        if (blocks[i][j] == 1) {
          final newRow = startRow + i;
          final newCol = startCol + j;
          
          if (newRow >= _gridSize || newCol >= _gridSize) return false;
          if (_grid[newRow][newCol] != 0) return false;
        }
      }
    }
    return true;
  }

  bool _canPlaceAnyShape() {
    for (final shape in _availableShapes) {
      for (int row = 0; row < _gridSize; row++) {
        for (int col = 0; col < _gridSize; col++) {
          if (_canPlaceShape(shape.blocks, row, col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void _checkAndClearLines() {
    final rowsToClear = <int>[];
    final colsToClear = <int>[];

    // Check rows
    for (int i = 0; i < _gridSize; i++) {
      if (_grid[i].every((cell) => cell == 1)) {
        rowsToClear.add(i);
      }
    }

    // Check columns
    for (int j = 0; j < _gridSize; j++) {
      bool full = true;
      for (int i = 0; i < _gridSize; i++) {
        if (_grid[i][j] == 0) {
          full = false;
          break;
        }
      }
      if (full) {
        colsToClear.add(j);
      }
    }

    // Clear rows and columns
    for (final row in rowsToClear) {
      for (int j = 0; j < _gridSize; j++) {
        _grid[row][j] = 0;
      }
    }

    for (final col in colsToClear) {
      for (int i = 0; i < _gridSize; i++) {
        _grid[i][col] = 0;
      }
    }

    final totalCleared = rowsToClear.length + colsToClear.length;
    if (totalCleared > 0) {
      _linesCleared += totalCleared;
      score += totalCleared * 10;
    }
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
                    _buildStat('Lines', _linesCleared.toString()),
                    _buildStat('Score', score.toString()),
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
            _buildAvailableShapes(),
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridSize,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: _gridSize * _gridSize,
        itemBuilder: (context, index) {
          final row = index ~/ _gridSize;
          final col = index % _gridSize;
          return GestureDetector(
            onTap: () => _placeShape(row, col),
            child: Container(
              decoration: BoxDecoration(
                color: _grid[row][col] == 1 
                    ? AppTheme.primaryColor 
                    : Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableShapes() {
    return Container(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _availableShapes.map((shape) {
          return GestureDetector(
            onTap: () => _selectShape(shape),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedShape == shape 
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedShape == shape 
                      ? AppTheme.primaryColor 
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: _buildShapePreview(shape),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShapePreview(BlockShape shape) {
    final blocks = shape.blocks;
    return Column(
      children: blocks.map((row) {
        return Row(
          children: row.map((cell) {
            return Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: cell == 1 ? shape.color : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class BlockShape {
  final List<List<int>> blocks;
  final Color color;

  BlockShape({
    required this.blocks,
    required this.color,
  });
}
