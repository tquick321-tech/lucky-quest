import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class WordSearchGame extends BaseGameScreen {
  const WordSearchGame({
    super.key,
    String gameId = 'word_search',
    String gameName = 'Word Search',
    int minReward = 10,
    int maxReward = 60,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends BaseGameState<WordSearchGame> {
  final List<List<String>> _grid = [];
  final List<WordToFind> _wordsToFind = [];
  final List<List<int>> _selectedCells = [];
  final int _gridSize = 10;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _grid.clear();
    _wordsToFind.clear();
    _selectedCells.clear();
    
    // Initialize empty grid
    for (int i = 0; i < _gridSize; i++) {
      _grid.add(List<String>.filled(_gridSize, ''));
    }

    // Define words to find
    final words = ['LUCKY', 'QUEST', 'GAME', 'PLAY', 'WIN', 'COIN', 'REWARD'];
    
    // Place words in grid
    for (final word in words) {
      _placeWord(word);
    }

    // Fill empty cells with random letters
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_grid[i][j].isEmpty) {
          _grid[i][j] = String.fromCharCode(GameUtils.getRandomInt(65, 90));
        }
      }
    }

    setState(() {
      score = 0;
    });
  }

  void _placeWord(String word) {
    final directions = [
      [0, 1],   // horizontal
      [1, 0],   // vertical
      [1, 1],   // diagonal down-right
      [1, -1],  // diagonal down-left
    ];

    bool placed = false;
    int attempts = 0;

    while (!placed && attempts < 100) {
      final direction = directions[GameUtils.getRandomInt(0, directions.length - 1)];
      final startRow = GameUtils.getRandomInt(0, _gridSize - 1);
      final startCol = GameUtils.getRandomInt(0, _gridSize - 1);

      if (_canPlaceWord(word, startRow, startCol, direction)) {
        for (int i = 0; i < word.length; i++) {
          final row = startRow + i * direction[0];
          final col = startCol + i * direction[1];
          _grid[row][col] = word[i];
        }
        
        _wordsToFind.add(WordToFind(
          word: word,
          found: false,
          startRow: startRow,
          startCol: startCol,
          direction: direction,
        ));
        
        placed = true;
      }
      attempts++;
    }
  }

  bool _canPlaceWord(String word, int startRow, int startCol, List<int> direction) {
    for (int i = 0; i < word.length; i++) {
      final row = startRow + i * direction[0];
      final col = startCol + i * direction[1];

      if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) {
        return false;
      }

      if (_grid[row][col].isNotEmpty && _grid[row][col] != word[i]) {
        return false;
      }
    }
    return true;
  }

  void _handleCellTap(int row, int col) {
    if (isGameOver) return;

    if (!_isSelecting) {
      setState(() {
        _isSelecting = true;
        _selectedCells.clear();
        _selectedCells.add([row, col]);
      });
    } else {
      setState(() {
        _isSelecting = false;
        _checkSelectedWord();
      });
    }
  }

  void _handleCellDrag(int row, int col) {
    if (!_isSelecting || isGameOver) return;

    // Check if cell is adjacent to last selected cell
    if (_selectedCells.isNotEmpty) {
      final lastCell = _selectedCells.last;
      final rowDiff = (row - lastCell[0]).abs();
      final colDiff = (col - lastCell[1]).abs();
      
      if ((rowDiff <= 1 && colDiff <= 1) && (rowDiff + colDiff > 0)) {
        // Check if already selected
        if (!_selectedCells.any((cell) => cell[0] == row && cell[1] == col)) {
          setState(() {
            _selectedCells.add([row, col]);
          });
        }
      }
    }
  }

  void _checkSelectedWord() {
    final selectedWord = _selectedCells.map((cell) => _grid[cell[0]][cell[1]]).join();
    
    for (final wordToFind in _wordsToFind) {
      if (!wordToFind.found && 
          (selectedWord == wordToFind.word || selectedWord == wordToFind.word.split('').reversed.join())) {
        setState(() {
          wordToFind.found = true;
          score += 10;
        });
        
        // Check if all words found
        if (_wordsToFind.every((w) => w.found)) {
          endGame(won: true);
        }
        break;
      }
    }

    setState(() {
      _selectedCells.clear();
    });
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
                    _buildStat('Found', '${_wordsToFind.where((w) => w.found).length}/${_wordsToFind.length}'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _buildWordsToFind(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _buildGrid(),
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

  Widget _buildWordsToFind() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wordsToFind.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: word.found ? AppTheme.successColor.withOpacity(0.3) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: word.found ? AppTheme.successColor : Colors.grey,
            ),
          ),
          child: Text(
            word.word,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: word.found ? TextDecoration.lineThrough : null,
              color: word.found ? AppTheme.successColor : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
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
          final row = (index ~/ _gridSize).toInt();
          final col = (index % _gridSize).toInt();
          final isSelected = _selectedCells.any((cell) => cell[0] == row && cell[1] == col);
          
          return GestureDetector(
            onTapDown: (_) => _handleCellTap(row.toInt(), col.toInt()),
            onPanUpdate: (details) {
              // Calculate which cell based on position (simplified)
              _handleCellDrag(row.toInt(), col.toInt());
            },
            onPanEnd: (_) {
              if (_isSelecting) {
                _checkSelectedWord();
                setState(() {
                  _isSelecting = false;
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  _grid[row][col],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class WordToFind {
  final String word;
  bool found;
  final int startRow;
  final int startCol;
  final List<int> direction;

  WordToFind({
    required this.word,
    required this.found,
    required this.startRow,
    required this.startCol,
    required this.direction,
  });
}
