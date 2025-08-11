import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'app_animations.dart';

/// Enhanced AI Message Actions - Click to show with feedback system
class ImprovedAiMessageActions extends StatefulWidget {
  final String messageText;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;
  final Function(String)? onVariation; // New callback for variations
  final bool showActions;
  final VoidCallback? onToggleActions;

  const ImprovedAiMessageActions({
    super.key,
    required this.messageText,
    required this.onCopy,
    required this.onRegenerate,
    this.onVariation,
    this.showActions = false,
    this.onToggleActions,
  });

  @override
  State<ImprovedAiMessageActions> createState() => _ImprovedAiMessageActionsState();
}

class _ImprovedAiMessageActionsState extends State<ImprovedAiMessageActions>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _copySuccess = false;
  String? _feedback; // 'up', 'down', or null
  
  late AnimationController _copyController;
  late AnimationController _regenerateController;
  late AnimationController _voiceController;
  late AnimationController _actionsController;
  late AnimationController _thumbsUpController;
  late AnimationController _thumbsDownController;
  late AnimationController _feedbackController;

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
    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _thumbsUpController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _thumbsDownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
  void didUpdateWidget(ImprovedAiMessageActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showActions != oldWidget.showActions) {
      if (widget.showActions) {
        _actionsController.forward();
      } else {
        _actionsController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _copyController.dispose();
    _regenerateController.dispose();
    _voiceController.dispose();
    _actionsController.dispose();
    _thumbsUpController.dispose();
    _thumbsDownController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
    await _flutterTts.stop();
    _regenerateController.forward().then((_) {
      _regenerateController.reverse();
    });
    widget.onRegenerate();
  }

  Future<void> _toggleSpeak() async {
    HapticFeedback.lightImpact();
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

  Future<void> _handleThumbsUp() async {
    HapticFeedback.mediumImpact();
    if (_feedback == 'up') {
      // Remove feedback
      setState(() => _feedback = null);
      _thumbsUpController.reverse();
    } else {
      // Set thumbs up feedback
      if (_feedback == 'down') {
        _thumbsDownController.reverse();
      }
      setState(() => _feedback = 'up');
      _thumbsUpController.forward();
      
      // Realistic thumb animation sequence
      await Future.delayed(const Duration(milliseconds: 100));
      _feedbackController.forward().then((_) {
        _feedbackController.reverse();
      });
    }
  }

  Future<void> _handleThumbsDown() async {
    HapticFeedback.mediumImpact();
    if (_feedback == 'down') {
      // Remove feedback
      setState(() => _feedback = null);
      _thumbsDownController.reverse();
    } else {
      // Set thumbs down feedback
      if (_feedback == 'up') {
        _thumbsUpController.reverse();
      }
      setState(() => _feedback = 'down');
      _thumbsDownController.forward();
      
      // Realistic thumb animation sequence
      await Future.delayed(const Duration(milliseconds: 100));
      _feedbackController.forward().then((_) {
        _feedbackController.reverse();
      });
    }
  }

  Future<void> _handleShare() async {
    HapticFeedback.lightImpact();
    try {
      await Share.share(
        widget.messageText,
        subject: 'AhamAI Response',
      );
    } catch (e) {
      // Handle share error gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share message: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleVariation(String type) async {
    HapticFeedback.mediumImpact();
    if (widget.onVariation != null) {
      String prompt = _getVariationPrompt(type);
      widget.onVariation!(prompt);
    }
  }

  String _getVariationPrompt(String type) {
    switch (type) {
      case 'expand':
        return 'Please provide a more detailed and expanded response to my previous question.';
      case 'shorten':
        return 'Please provide a shorter, more concise response to my previous question.';
      case 'simplify':
        return 'Please provide a simpler response using easier language to my previous question.';
      case 'technical':
        return 'Please provide a more technical and detailed response to my previous question.';
      case 'creative':
        return 'Please provide a more creative and engaging response to my previous question.';
      case 'formal':
        return 'Please provide a more formal response to my previous question.';
      case 'casual':
        return 'Please provide a more casual, conversational response to my previous question.';
      case 'bullet':
        return 'Please provide a response in bullet-point format to my previous question.';
      default:
        return 'Please provide an alternative response to my previous question.';
    }
  }

  void _showVariationMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        _buildVariationMenuItem('expand', Icons.expand_more, 'Expand Response'),
        _buildVariationMenuItem('shorten', Icons.compress, 'Shorten Response'),
        _buildVariationMenuItem('simplify', Icons.lightbulb_outline, 'Simplify Language'),
        _buildVariationMenuItem('technical', Icons.engineering, 'More Technical'),
        _buildVariationMenuItem('creative', Icons.brush, 'More Creative'),
        _buildVariationMenuItem('formal', Icons.business, 'More Formal'),
        _buildVariationMenuItem('casual', Icons.chat_bubble_outline, 'More Casual'),
        _buildVariationMenuItem('bullet', Icons.format_list_bulleted, 'Bullet Points'),
      ],
    ).then((value) {
      if (value != null) {
        _handleVariation(value);
      }
    });
  }

  PopupMenuItem<String> _buildVariationMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _actionsController,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _actionsController,
          child: FadeTransition(
            opacity: _actionsController,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Wrap(
                spacing: 4,
                children: [
                  // Copy button with success animation
                  _AnimatedActionButton(
                    onTap: _handleCopy,
                    tooltip: 'Copy message',
                    child: AnimatedBuilder(
                      animation: _copyController,
                      builder: (context, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _copySuccess
                              ? Icon(
                                  Icons.check_circle_outline,
                                  key: const ValueKey('check'),
                                  size: 18,
                                  color: Colors.green[600],
                                )
                              : const Icon(
                                  Icons.content_copy_outlined,
                                  key: ValueKey('copy'),
                                  size: 18,
                                ),
                        );
                      },
                    ),
                  ),
                  
                  // Regenerate button with rotation animation
                  _AnimatedActionButton(
                    onTap: _handleRegenerate,
                    tooltip: 'Regenerate response',
                    child: AnimatedBuilder(
                      animation: _regenerateController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _regenerateController.value * 2 * 3.14159,
                          child: const Icon(
                            Icons.refresh_rounded,
                            size: 18,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Voice button with pulse animation when speaking
                  _AnimatedActionButton(
                    onTap: _toggleSpeak,
                    tooltip: _isSpeaking ? 'Stop speaking' : 'Read aloud',
                    child: AnimatedBuilder(
                      animation: _voiceController,
                      builder: (context, child) {
                        if (_isSpeaking) {
                          return Transform.scale(
                            scale: 1.0 + (_voiceController.value * 0.1),
                            child: Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        }
                        return const Icon(
                          Icons.volume_up_outlined,
                          size: 18,
                        );
                      },
                    ),
                  ),
                  
                  // Thumbs up button with realistic animation
                  _AnimatedActionButton(
                    onTap: _handleThumbsUp,
                    tooltip: 'Good response',
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_thumbsUpController, _feedbackController]),
                      builder: (context, child) {
                        final isActive = _feedback == 'up';
                        return Transform.scale(
                          scale: 1.0 + (_feedbackController.value * 0.2),
                          child: Transform.rotate(
                            angle: isActive ? _thumbsUpController.value * 0.1 : 0,
                            child: Icon(
                              isActive ? Icons.thumb_up : Icons.thumb_up_outlined,
                              size: 18,
                              color: isActive ? Colors.green[600] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Thumbs down button with realistic animation
                  _AnimatedActionButton(
                    onTap: _handleThumbsDown,
                    tooltip: 'Poor response',
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_thumbsDownController, _feedbackController]),
                      builder: (context, child) {
                        final isActive = _feedback == 'down';
                        return Transform.scale(
                          scale: 1.0 + (_feedbackController.value * 0.2),
                          child: Transform.rotate(
                            angle: isActive ? _thumbsDownController.value * -0.1 : 0,
                            child: Icon(
                              isActive ? Icons.thumb_down : Icons.thumb_down_outlined,
                              size: 18,
                              color: isActive ? Colors.red[600] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Share button
                  _AnimatedActionButton(
                    onTap: _handleShare,
                    tooltip: 'Share message',
                    child: const Icon(
                      Icons.share,
                      size: 18,
                    ),
                  ),
                  
                  // Variation button with menu
                  if (widget.onVariation != null)
                    Builder(
                      builder: (context) => _AnimatedActionButton(
                        onTap: () => _showVariationMenu(context),
                        tooltip: 'Modify response',
                        child: const Icon(
                          Icons.tune,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Action Button with better animations and tooltip
class _AnimatedActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;

  const _AnimatedActionButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.black.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: theme.iconTheme.color?.withOpacity(0.8),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Quick Action Icons - Better icon alternatives
class QuickActionIcons {
  // Better copy icon with document feel
  static const IconData copy = Icons.file_copy_outlined;
  static const IconData copySuccess = Icons.check_circle_outline;
  
  // Better regenerate icon
  static const IconData regenerate = Icons.replay_outlined;
  
  // Better voice icons
  static const IconData voicePlay = Icons.record_voice_over_outlined;
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