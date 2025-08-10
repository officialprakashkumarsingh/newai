import 'package:flutter/material.dart';

/// Dotted Background Pattern - Adds subtle dots to the background
class DottedBackground extends StatelessWidget {
  final Widget child;
  final double dotSize;
  final double spacing;
  final Color? dotColor;

  const DottedBackground({
    super.key,
    required this.child,
    this.dotSize = 2.0,
    this.spacing = 20.0,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultDotColor = isDark 
        ? Colors.white.withOpacity(0.05) 
        : Colors.black.withOpacity(0.03);

    return Stack(
      children: [
        // Dotted pattern background
        Positioned.fill(
          child: CustomPaint(
            painter: DottedPatternPainter(
              dotSize: dotSize,
              spacing: spacing,
              dotColor: dotColor ?? defaultDotColor,
            ),
          ),
        ),
        // Child content on top
        child,
      ],
    );
  }
}

/// Custom painter for creating the dotted pattern
class DottedPatternPainter extends CustomPainter {
  final double dotSize;
  final double spacing;
  final Color dotColor;

  DottedPatternPainter({
    required this.dotSize,
    required this.spacing,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Calculate number of dots that fit in each direction
    final int horizontalDots = (size.width / spacing).ceil();
    final int verticalDots = (size.height / spacing).ceil();

    // Draw dots in a grid pattern
    for (int x = 0; x < horizontalDots; x++) {
      for (int y = 0; y < verticalDots; y++) {
        final double dotX = x * spacing + (spacing / 2);
        final double dotY = y * spacing + (spacing / 2);

        // Only draw dots that are within the canvas bounds
        if (dotX <= size.width && dotY <= size.height) {
          canvas.drawCircle(
            Offset(dotX, dotY),
            dotSize / 2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DottedPatternPainter) {
      return oldDelegate.dotSize != dotSize ||
             oldDelegate.spacing != spacing ||
             oldDelegate.dotColor != dotColor;
    }
    return true;
  }
}

/// Alternative diagonal dots pattern
class DiagonalDottedBackground extends StatelessWidget {
  final Widget child;
  final double dotSize;
  final double spacing;
  final Color? dotColor;

  const DiagonalDottedBackground({
    super.key,
    required this.child,
    this.dotSize = 1.5,
    this.spacing = 25.0,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultDotColor = isDark 
        ? Colors.white.withOpacity(0.04) 
        : Colors.black.withOpacity(0.025);

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: DiagonalDottedPatternPainter(
              dotSize: dotSize,
              spacing: spacing,
              dotColor: dotColor ?? defaultDotColor,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Diagonal dotted pattern painter
class DiagonalDottedPatternPainter extends CustomPainter {
  final double dotSize;
  final double spacing;
  final Color dotColor;

  DiagonalDottedPatternPainter({
    required this.dotSize,
    required this.spacing,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Create a diagonal grid pattern
    final int maxSteps = ((size.width + size.height) / spacing * 2).ceil();

    for (int i = 0; i < maxSteps; i++) {
      for (int j = 0; j < maxSteps; j++) {
        // Offset every other row for a better pattern
        final double offsetX = (j % 2) * (spacing / 2);
        final double dotX = i * spacing + offsetX;
        final double dotY = j * spacing;

        // Only draw dots that are within bounds
        if (dotX >= 0 && dotX <= size.width && dotY >= 0 && dotY <= size.height) {
          canvas.drawCircle(
            Offset(dotX, dotY),
            dotSize / 2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DiagonalDottedPatternPainter) {
      return oldDelegate.dotSize != dotSize ||
             oldDelegate.spacing != spacing ||
             oldDelegate.dotColor != dotColor;
    }
    return true;
  }
}