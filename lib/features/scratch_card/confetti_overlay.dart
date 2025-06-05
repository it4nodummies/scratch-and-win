import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a confetti animation overlay.
class ConfettiOverlay extends StatefulWidget {
  /// Whether the confetti animation is playing.
  final bool isPlaying;

  /// The number of confetti particles to display.
  final int particleCount;

  /// The duration of the animation.
  final Duration duration;

  const ConfettiOverlay({
    Key? key,
    required this.isPlaying,
    this.particleCount = 100,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        if (widget.isPlaying) {
          _controller.forward();
        }
      }
    });
    _initializeParticles();
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _initializeParticles();
        _controller.forward();
      } else {
        _controller.reset();
      }
    }
  }

  void _initializeParticles() {
    _particles = List.generate(
      widget.particleCount,
      (_) => ConfettiParticle(
        color: _randomColor(),
        position: Offset(_random.nextDouble(), -0.2),
        speed: 0.2 + _random.nextDouble() * 0.8,
        size: 5.0 + _random.nextDouble() * 10.0,
        angle: _random.nextDouble() * pi,
      ),
    );
  }

  Color _randomColor() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying && _controller.value == 0.0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// A confetti particle.
class ConfettiParticle {
  /// The color of the particle.
  final Color color;

  /// The initial position of the particle (normalized coordinates).
  final Offset position;

  /// The speed of the particle.
  final double speed;

  /// The size of the particle.
  final double size;

  /// The initial angle of the particle.
  final double angle;

  ConfettiParticle({
    required this.color,
    required this.position,
    required this.speed,
    required this.size,
    required this.angle,
  });
}

/// A custom painter that draws the confetti particles.
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      // Calculate the current position of the particle
      final x = particle.position.dx * size.width;
      final y = particle.position.dy * size.height + progress * size.height * particle.speed;

      // Draw the particle
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.angle + progress * 2 * pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}