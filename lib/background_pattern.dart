import 'package:flutter/material.dart';
import 'dart:math' as math;

class BackgroundPattern extends StatelessWidget {
  final Widget child;
  final bool isDarkMode;

  const BackgroundPattern({
    Key? key,
    required this.child,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: isDarkMode ? const Color(0xFF202124) : const Color(0xFFF1F3F4),
        ),
        
        // Pattern overlay (only in dark mode)
        if (isDarkMode) ...[
          // Subtle dot pattern
          CustomPaint(
            size: Size.infinite,
            painter: DotPatternPainter(
              isDarkMode: isDarkMode,
            ),
          ),
          
          // Subtle grid lines
          CustomPaint(
            size: Size.infinite,
            painter: GridPatternPainter(
              isDarkMode: isDarkMode,
            ),
          ),
        ],
        
        // Content
        child,
      ],
    );
  }
}

class DotPatternPainter extends CustomPainter {
  final bool isDarkMode;

  DotPatternPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDarkMode) return;

    final paint = Paint()
      ..color = const Color(0xFF2C2C2E).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const dotSize = 1.0;
    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Add some randomness to make it more organic
        final offsetX = (math.sin(x * 0.01 + y * 0.01) * 8);
        final offsetY = (math.cos(x * 0.01 + y * 0.01) * 8);
        
        canvas.drawCircle(
          Offset(x + offsetX, y + offsetY),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPatternPainter extends CustomPainter {
  final bool isDarkMode;

  GridPatternPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDarkMode) return;

    final paint = Paint()
      ..color = const Color(0xFF333438).withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 120.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add some diagonal accent lines
    final accentPaint = Paint()
      ..color = const Color(0xFF1A73E8).withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Diagonal lines every 240px
    for (double i = -size.height; i < size.width + size.height; i += 240) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}