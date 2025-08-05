import 'package:flutter/material.dart';
import 'dart:math' as math;

class UniverseLogo extends StatefulWidget {
  final double size;
  final bool isDarkMode;

  const UniverseLogo({
    Key? key,
    this.size = 120.0,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<UniverseLogo> createState() => _UniverseLogoState();
}

class _UniverseLogoState extends State<UniverseLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: UniverseLogoPainter(
                rotationAngle: _rotationAnimation.value,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          ),
        );
      },
    );
  }
}

class UniverseLogoPainter extends CustomPainter {
  final double rotationAngle;
  final bool isDarkMode;

  UniverseLogoPainter({
    required this.rotationAngle,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Colors based on theme
    final primaryColor = isDarkMode ? Colors.white : const Color(0xFF202124);
    final accentColor = isDarkMode ? const Color(0xFF1A73E8) : const Color(0xFF4285F4);
    final universeColor = isDarkMode ? const Color(0xFF9966CC) : const Color(0xFF7B4397);

    // Draw outer universe ring with stars
    _drawUniverseRing(canvas, center, radius, accentColor);

    // Draw central energy core
    _drawEnergyCore(canvas, center, radius * 0.3, primaryColor);

    // Draw orbiting particles
    _drawOrbitingParticles(canvas, center, radius, universeColor);
  }

  void _drawUniverseRing(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Main orbit ring
    canvas.drawCircle(center, radius * 0.85, paint);

    // Draw stars around the ring
    final starPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + rotationAngle;
      final starX = center.dx + math.cos(angle) * radius * 0.85;
      final starY = center.dy + math.sin(angle) * radius * 0.85;
      
      _drawStar(canvas, Offset(starX, starY), 3.0, starPaint);
    }
  }

  void _drawEnergyCore(Canvas canvas, Offset center, double radius, Color color) {
    // Central pulsing energy sphere
    final corePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.3, corePaint);

    // Energy rings
    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final ringRadius = radius * (0.5 + i * 0.2);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    // Central glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawCircle(center, radius * 0.4, glowPaint);
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Inner orbit particles
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + rotationAngle * 1.5;
      final particleX = center.dx + math.cos(angle) * radius * 0.6;
      final particleY = center.dy + math.sin(angle) * radius * 0.6;
      
      canvas.drawCircle(Offset(particleX, particleY), 2.0, paint);
    }

    // Outer orbit particles (counter-rotating)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - rotationAngle * 0.8;
      final particleX = center.dx + math.cos(angle) * radius * 0.95;
      final particleY = center.dy + math.sin(angle) * radius * 0.95;
      
      canvas.drawCircle(Offset(particleX, particleY), 1.5, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const numPoints = 5;
    final angleStep = math.pi / numPoints;
    
    for (int i = 0; i < numPoints * 2; i++) {
      final angle = i * angleStep - math.pi / 2;
      final radius = i.isEven ? size : size * 0.5;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(UniverseLogoPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}