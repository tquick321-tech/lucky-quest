import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class TileConnectGame extends BaseGameScreen {
  const TileConnectGame({
    super.key,
    String gameId = 'tile_connect',
    String gameName = 'Tile Connect',
    int minReward = 10,
    int maxReward = 70,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<TileConnectGame> createState() => _TileConnectGameState();
}

class _TileConnectGameState extends BaseGameState<TileConnectGame> {
  final List<Tile> _tiles = [];
  final List<Tile> _selectedTiles = [];
  final int _maxSelection = 3;
  int _pairsFound = 0;
  final int _totalPairs = 15;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _tiles.clear();
    _selectedTiles.clear();
    _pairsFound = 0;

    final icons = [
      Icons.star,
      Icons.favorite,
      Icons.diamond,
      Icons.circle,
      Icons.square,
      Icons.change_history,
      Icons.crop_square,
      Icons.crop_free,
      Icons.cloud,
      Icons.wb_sunny,
      Icons.dark_mode,
      Icons.local_florist,
      Icons.park,
      Icons.water_drop,
      Icons.whatshot,
    ];

    // Create pairs
    final tilePairs = <Tile>[];
    for (int i = 0; i < _totalPairs; i++) {
      final icon = icons[i % icons.length];
      tilePairs.add(Tile(icon: icon, id: i * 2));
      tilePairs.add(Tile(icon: icon, id: i * 2 + 1));
    }

    // Shuffle and add to grid
    final shuffledTiles = GameUtils.shuffleList(tilePairs);
    _tiles.addAll(shuffledTiles);

    setState(() {
      score = 0;
    });
  }

  void _selectTile(Tile tile) {
    if (isGameOver) return;
    if (_selectedTiles.length >= _maxSelection) return;
    if (_selectedTiles.any((t) => t.id == tile.id)) return;

    setState(() {
      _selectedTiles.add(tile);
    });

    if (_selectedTiles.length == _maxSelection) {
      _checkForMatch();
    }
  }

  void _checkForMatch() {
    final icons = _selectedTiles.map((t) => t.icon).toSet();
    
    if (icons.length == 1) {
      // All selected tiles match
      setState(() {
        _tiles.removeWhere((t) => _selectedTiles.any((st) => st.id == t.id));
        _selectedTiles.clear();
        _pairsFound++;
        score += 10;

        if (_pairsFound == _totalPairs) {
          endGame(won: true);
        } else if (_tiles.length < _maxSelection) {
          endGame(won: true);
        }
      });
    } else {
      // No match, clear selection after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _selectedTiles.clear();
        });
      });
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
                    _buildStat('Pairs', '$_pairsFound/$_totalPairs'),
                    _buildStat('Score', score.toString()),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            _buildSelectedTiles(),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _buildTileGrid(),
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

  Widget _buildSelectedTiles() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_maxSelection, (index) {
          final isSelected = index < _selectedTiles.length;
          return Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: isSelected
                ? Icon(
                    _selectedTiles[index].icon,
                    size: 32,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.help_outline,
                    size: 32,
                    color: Colors.grey,
                  ),
          );
        }),
      ),
    );
  }

  Widget _buildTileGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _tiles.length,
      itemBuilder: (context, index) {
        final tile = _tiles[index];
        final isSelected = _selectedTiles.any((t) => t.id == tile.id);
        
        return GestureDetector(
          onTap: () => _selectTile(tile),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              tile.icon,
              size: 28,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        );
      },
    );
  }
}

class Tile {
  final IconData icon;
  final int id;

  Tile({required this.icon, required this.id});
}
