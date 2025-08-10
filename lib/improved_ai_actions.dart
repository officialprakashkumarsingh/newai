import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'app_animations.dart';

/// Improved AI Message Actions - Better icons and user experience
/// Separated from main components to keep files smaller
class ImprovedAiMessageActions extends StatefulWidget {
  final String messageText;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  const ImprovedAiMessageActions({
    super.key,
    required this.messageText,
    required this.onCopy,
    required this.onRegenerate,
  });

  @override
  State<ImprovedAiMessageActions> createState() => _ImprovedAiMessageActionsState();
}

class _ImprovedAiMessageActionsState extends State<ImprovedAiMessageActions>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _copySuccess = false;
  late AnimationController _copyController;
  late AnimationController _regenerateController;
  late AnimationController _voiceController;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _copyController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _regenerateController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _voiceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = true);
        _voiceController.repeat(reverse: true);
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _voiceController.stop();
        _voiceController.reset();
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _voiceController.stop();
        _voiceController.reset();
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _copyController.dispose();
    _regenerateController.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.messageText));
    setState(() => _copySuccess = true);
    _copyController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() => _copySuccess = false);
          _copyController.reverse();
        }
      });
    });
    widget.onCopy();
  }

  Future<void> _handleRegenerate() async {
    await _flutterTts.stop();
    _regenerateController.forward().then((_) {
      _regenerateController.reverse();
    });
    widget.onRegenerate();
  }

  Future<void> _toggleSpeak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
      _voiceController.stop();
      _voiceController.reset();
    } else {
      await _flutterTts.stop();
      if (mounted) {
        await _flutterTts.speak(widget.messageText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Row(
        children: [
          // Copy button with success animation
          AnimatedScaleButton(
            onTap: _handleCopy,
            child: _ImprovedActionButton(
              child: AnimatedBuilder(
                animation: _copyController,
                builder: (context, child) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _copySuccess
                        ? Icon(
                            Icons.check_circle_outline,
                            key: const ValueKey('check'),
                            size: 20,
                            color: Colors.green[600],
                          )
                        : const Icon(
                            Icons.content_copy_outlined,
                            key: ValueKey('copy'),
                            size: 20,
                          ),
                  );
                },
              ),
            ),
          ),
          
          // Regenerate button with rotation animation
          AnimatedScaleButton(
            onTap: _handleRegenerate,
            child: _ImprovedActionButton(
              child: AnimatedBuilder(
                animation: _regenerateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _regenerateController.value * 2 * 3.14159,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Voice button with pulse animation when speaking
          AnimatedScaleButton(
            onTap: _toggleSpeak,
            child: _ImprovedActionButton(
              child: AnimatedBuilder(
                animation: _voiceController,
                builder: (context, child) {
                  if (_isSpeaking) {
                    return Transform.scale(
                      scale: 1.0 + (_voiceController.value * 0.1),
                      child: Icon(
                        Icons.stop_circle_outlined,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }
                  return const Icon(
                    Icons.volume_up_outlined,
                    size: 20,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Improved Action Button - Better styling and hover effects
class _ImprovedActionButton extends StatefulWidget {
  final Widget child;

  const _ImprovedActionButton({required this.child});

  @override
  State<_ImprovedActionButton> createState() => _ImprovedActionButtonState();
}

class _ImprovedActionButtonState extends State<_ImprovedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.lerp(
                Colors.transparent,
                isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                _hoverAnimation.value,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconTheme(
              data: IconThemeData(
                color: Color.lerp(
                  theme.iconTheme.color,
                  theme.primaryColor,
                  _hoverAnimation.value * 0.3,
                ),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Quick Action Icons - Better icon alternatives
class QuickActionIcons {
  // Better copy icon with document feel
  static const IconData copy = Icons.content_copy_outlined;
  static const IconData copySuccess = Icons.check_circle_outline;
  
  // Better regenerate icon
  static const IconData regenerate = Icons.refresh_rounded;
  
  // Better voice icons
  static const IconData voicePlay = Icons.volume_up_outlined;
  static const IconData voiceStop = Icons.stop_circle_outlined;
  
  // Additional useful icons
  static const IconData share = Icons.share_outlined;
  static const IconData bookmark = Icons.bookmark_outline;
  static const IconData download = Icons.download_outlined;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
}

/// Floating Action Button with better animations
class ImprovedFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color? backgroundColor;

  const ImprovedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.backgroundColor,
  });

  @override
  State<ImprovedFloatingActionButton> createState() => _ImprovedFloatingActionButtonState();
}

class _ImprovedFloatingActionButtonState extends State<ImprovedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: FloatingActionButton(
                onPressed: null, // Handled by GestureDetector
                backgroundColor: widget.backgroundColor,
                tooltip: widget.tooltip,
                child: Icon(widget.icon),
              ),
            ),
          );
        },
      ),
    );
  }
}