import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceAnimationWidget extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const VoiceAnimationWidget({
    Key? key,
    required this.isListening,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  State<VoiceAnimationWidget> createState() => _VoiceAnimationWidgetState();
}

class _VoiceAnimationWidgetState extends State<VoiceAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(VoiceAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _startListeningAnimation();
      } else {
        _stopListeningAnimation();
      }
    }
  }

  void _startListeningAnimation() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _stopListeningAnimation() {
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer wave rings when listening
            if (widget.isListening) ...[
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(48, 48),
                    painter: VoiceWavePainter(
                      animationValue: _waveAnimation.value,
                      color: widget.backgroundColor?.withOpacity(0.3) ?? 
                             Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ],
            
            // Main voice button with pulse
            AnimatedBuilder(
              animation: widget.isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isListening 
                          ? Colors.red.withOpacity(0.8)
                          : (widget.backgroundColor ?? Theme.of(context).primaryColor),
                      boxShadow: [
                        BoxShadow(
                          color: widget.isListening 
                              ? Colors.red.withOpacity(0.4)
                              : Colors.black.withOpacity(0.2),
                          blurRadius: widget.isListening ? 12 : 6,
                          spreadRadius: widget.isListening ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none,
                      color: widget.iconColor ?? Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  VoiceWavePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw multiple wave rings
    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + (i * 0.3)) % 1.0;
      final radius = progress * (size.width / 2) + 20;
      final opacity = (1.0 - progress) * 0.8;
      
      paint.color = color.withOpacity(opacity);
      
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(VoiceWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
}

class VoiceLevelIndicator extends StatelessWidget {
  final double level; // 0.0 to 1.0
  final Color color;

  const VoiceLevelIndicator({
    Key? key,
    required this.level,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 20),
      painter: VoiceLevelPainter(level: level, color: color),
    );
  }
}

class VoiceLevelPainter extends CustomPainter {
  final double level;
  final Color color;

  VoiceLevelPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barCount = 5;
    final barWidth = size.width / barCount - 2;
    final maxHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      final barLevel = math.max(0.0, (level - (i * 0.2)) * 5);
      final barHeight = barLevel * maxHeight;
      
      final rect = Rect.fromLTWH(
        i * (barWidth + 2),
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VoiceLevelPainter oldDelegate) {
    return oldDelegate.level != level;
  }
}