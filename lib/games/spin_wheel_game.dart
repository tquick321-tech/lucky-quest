import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'base_game.dart';
import 'game_utils.dart';

class SpinWheelGame extends BaseGameScreen {
  const SpinWheelGame({
    super.key,
    String gameId = 'spin_wheel',
    String gameName = 'Lucky Spin',
    int minReward = 5,
    int maxReward = 100,
  }) : super(gameId: gameId, gameName: gameName, minReward: minReward, maxReward: maxReward);

  @override
  State<SpinWheelGame> createState() => _SpinWheelGameState();
}

class _SpinWheelGameState extends BaseGameState<SpinWheelGame> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<WheelSegment> _segments = [];
  double _currentAngle = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _initializeSegments();
  }

  void _initializeSegments() {
    final rewards = [5, 10, 15, 20, 25, 30, 50, 100];
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      Colors.purple,
      Colors.orange,
    ];
    
    for (int i = 0; i < rewards.length; i++) {
      _segments.add(WheelSegment(
        reward: rewards[i],
        color: colors[i % colors.length],
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning) return;
    
    setState(() {
      _isSpinning = true;
      isPlaying = true;
      startTime = DateTime.now();
    });

    final randomSpins = GameUtils.getRandomInt(5, 10);
    final randomAngle = GameUtils.getRandomDouble(0, 360);
    final targetAngle = _currentAngle + (randomSpins * 360) + randomAngle;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0).then((_) {
      setState(() {
        _currentAngle = targetAngle % 360;
        _isSpinning = false;
        
        // Calculate which segment won
        final normalizedAngle = (360 - _currentAngle) % 360;
        final segmentAngle = 360 / _segments.length;
        final winningIndex = (normalizedAngle / segmentAngle).floor();
        final winningSegment = _segments[winningIndex % _segments.length];
        
        score = winningSegment.reward;
        endGame(won: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: _currentAngle * 3.14159 / 180,
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: WheelPainter(_segments),
                    ),
                  ),
                  Positioned(
                    top: -20,
                    child: Container(
                      width: 0,
                      height: 0,
                      child: CustomPaint(
                        size: const Size(40, 40),
                        painter: PointerPainter(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 40,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSpinning ? null : _spinWheel,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                _isSpinning ? 'Spinning...' : 'SPIN!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (isGameOver)
              Text(
                'You won $reward LC!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WheelSegment {
  final int reward;
  final Color color;

  WheelSegment({required this.reward, required this.color});
}

class WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  WheelPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * 3.14159 / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle;
      final endAngle = (i + 1) * segmentAngle;

      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${segments[i].reward}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      final textAngle = startAngle + segmentAngle / 2;
      final textX = center.dx + (radius * 0.65) * cos(textAngle);
      final textY = center.dy + (radius * 0.65) * sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + 3.14159 / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.15, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
