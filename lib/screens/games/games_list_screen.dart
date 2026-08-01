import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../games/spin_wheel_game.dart';
import '../../games/scratch_card_game.dart';
import '../../games/memory_match_game.dart';
import '../../games/number_guess_game.dart';
import '../../games/color_match_game.dart';
import '../../games/water_color_sort.dart';
import '../../games/block_blast.dart';
import '../../games/number_merge.dart';
import '../../games/word_search.dart';
import '../../games/tile_connect.dart';

class GameInfo {
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final int minReward;
  final int maxReward;
  final Widget Function() gameScreen;

  GameInfo({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.minReward,
    required this.maxReward,
    required this.gameScreen,
  });
}

class GamesListScreen extends StatelessWidget {
  GamesListScreen({super.key});

  final List<GameInfo> _games = [
    GameInfo(
      name: 'Water Color Sort',
      description: 'Sort colors into matching tubes',
      category: 'Puzzle',
      icon: Icons.water_drop,
      minReward: 10,
      maxReward: 80,
      gameScreen: () => const WaterColorSortGame(),
    ),
    GameInfo(
      name: 'Block Blast',
      description: 'Place blocks to clear lines',
      category: 'Puzzle',
      icon: Icons.crop_square,
      minReward: 10,
      maxReward: 100,
      gameScreen: () => const BlockBlastGame(),
    ),
    GameInfo(
      name: 'Number Merge',
      description: 'Merge numbers to reach 2048',
      category: 'Puzzle',
      icon: Icons.grid_on,
      minReward: 10,
      maxReward: 80,
      gameScreen: () => const NumberMergeGame(),
    ),
    GameInfo(
      name: 'Word Search',
      description: 'Find hidden words in grid',
      category: 'Puzzle',
      icon: Icons.text_fields,
      minReward: 10,
      maxReward: 60,
      gameScreen: () => const WordSearchGame(),
    ),
    GameInfo(
      name: 'Tile Connect',
      description: 'Connect matching tiles',
      category: 'Puzzle',
      icon: Icons.extension,
      minReward: 10,
      maxReward: 70,
      gameScreen: () => const TileConnectGame(),
    ),
    GameInfo(
      name: 'Lucky Spin',
      description: 'Spin the wheel to win rewards',
      category: 'Casino',
      icon: Icons.rotate_right,
      minReward: 5,
      maxReward: 100,
      gameScreen: () => const SpinWheelGame(),
    ),
    GameInfo(
      name: 'Scratch Card',
      description: 'Scratch cards to reveal prizes',
      category: 'Casino',
      icon: Icons.credit_card,
      minReward: 5,
      maxReward: 75,
      gameScreen: () => const ScratchCardGame(),
    ),
    GameInfo(
      name: 'Memory Match',
      description: 'Match pairs to earn coins',
      category: 'Puzzle',
      icon: Icons.grid_view,
      minReward: 10,
      maxReward: 60,
      gameScreen: () => const MemoryMatchGame(),
    ),
    GameInfo(
      name: 'Number Guess',
      description: 'Guess the hidden number',
      category: 'Puzzle',
      icon: Icons.question_mark,
      minReward: 5,
      maxReward: 40,
      gameScreen: () => const NumberGuessGame(),
    ),
    GameInfo(
      name: 'Color Match',
      description: 'Find the matching color',
      category: 'Arcade',
      icon: Icons.palette,
      minReward: 5,
      maxReward: 50,
      gameScreen: () => const ColorMatchGame(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Games',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Categories
            _buildCategories(context),
            const SizedBox(height: 24),
            // Games grid
            _buildGamesGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    final categories = ['All', 'Puzzle', 'Arcade', 'Casino'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
              child: Text(
                categories[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGamesGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        return _buildGameCard(context, _games[index]);
      },
    );
  }

  Widget _buildGameCard(BuildContext context, GameInfo game) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => game.gameScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.3),
                      AppTheme.secondaryColor.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    game.icon,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        size: 14,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.minReward} - ${game.maxReward}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
