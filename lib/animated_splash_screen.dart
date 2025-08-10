import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

/// Animated Splash Screen with dotted background and AhamAI logo
class AnimatedSplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget child;

  const AnimatedSplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
    required this.child,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  
  late Animation<double> _dotsAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _dotsController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Setup animations
    _dotsAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeInOut,
    ));

    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start dots animation (continuous)
    _dotsController.repeat();
    
    // Wait for total duration, then fade out
    await Future.delayed(widget.duration - const Duration(milliseconds: 800));
    await _fadeController.forward();
    
    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => widget.child,
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final logoColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                // Animated dotted background
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _dotsAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: AnimatedDottedBackgroundPainter(
                          progress: _dotsAnimation.value,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),
                
                                // AhamAI Logo (Static, No Animation)
                Center(
                  child: Text(
                    'AhamAI',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 48,
                      fontWeight: FontWeight.w500,
                      color: logoColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for animated dotted background
class AnimatedDottedBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  AnimatedDottedBackgroundPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final dotColor = isDark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.black.withOpacity(0.05);
    
    final highlightColor = isDark 
        ? Colors.blue.withOpacity(0.3) 
        : Colors.blue.withOpacity(0.15);

    final spacing = 25.0;
    final baseSize = 2.0;
    final maxSize = 4.0;
    
    // Calculate grid
    final horizontalDots = (size.width / spacing).ceil();
    final verticalDots = (size.height / spacing).ceil();

    for (int x = 0; x < horizontalDots; x++) {
      for (int y = 0; y < verticalDots; y++) {
        final dotX = x * spacing + (spacing / 2);
        final dotY = y * spacing + (spacing / 2);

        if (dotX <= size.width && dotY <= size.height) {
          // Create wave effect
          final distance = math.sqrt(
            math.pow(dotX - size.width / 2, 2) + 
            math.pow(dotY - size.height / 2, 2)
          );
          
          final wavePhase = (distance / 100) - (progress * 4);
          final wave = math.sin(wavePhase * math.pi);
          
          // Animate dot size and opacity
          final sizeMultiplier = 1.0 + (wave * 0.5).clamp(0.0, 1.0);
          final dotSize = (baseSize + (maxSize - baseSize) * sizeMultiplier.clamp(0.0, 1.0)) / 2;
          
          // Color based on wave
          final isHighlighted = wave > 0.3;
          paint.color = isHighlighted ? highlightColor : dotColor;
          
          canvas.drawCircle(
            Offset(dotX, dotY),
            dotSize,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is AnimatedDottedBackgroundPainter) {
      return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
    }
    return true;
  }
}

/// Wrapper to easily add splash screen to any app
class SplashWrapper extends StatelessWidget {
  final Widget child;
  final Duration splashDuration;

  const SplashWrapper({
    super.key,
    required this.child,
    this.splashDuration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: splashDuration,
      child: child,
    );
  }
}