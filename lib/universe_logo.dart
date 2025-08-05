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

class _UniverseLogoState extends State<UniverseLogo> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: UniverseLogoPainter(
          rotationAngle: 0, // Static, no rotation
          isDarkMode: widget.isDarkMode,
        ),
      ),
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

    // Draw the static letter 'A' in the center
    _drawStaticLetterA(canvas, center, radius * 0.4, primaryColor);

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

  void _drawStaticLetterA(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Letter 'A' coordinates (static, no animation)
    final topPoint = Offset(center.dx, center.dy - radius);
    final bottomLeft = Offset(center.dx - radius * 0.7, center.dy + radius * 0.8);
    final bottomRight = Offset(center.dx + radius * 0.7, center.dy + radius * 0.8);
    final crossLeft = Offset(center.dx - radius * 0.35, center.dy + radius * 0.2);
    final crossRight = Offset(center.dx + radius * 0.35, center.dy + radius * 0.2);

    // Draw the 'A' shape
    path.moveTo(bottomLeft.dx, bottomLeft.dy);
    path.lineTo(topPoint.dx, topPoint.dy);
    path.lineTo(bottomRight.dx, bottomRight.dy);
    
    canvas.drawPath(path, paint);

    // Draw the crossbar
    canvas.drawLine(crossLeft, crossRight, paint);
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