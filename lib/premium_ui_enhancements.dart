import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium UI Enhancement System
/// Provides smooth animations, premium interactions, and performance optimizations
class PremiumUIEnhancements {
  
  // Animation durations for consistency
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  // Curves for premium feel
  static const Curve premiumCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.fastOutSlowIn;
  
  // Haptic feedback for premium interactions
  static void lightHaptic() => HapticFeedback.lightImpact();
  static void mediumHaptic() => HapticFeedback.mediumImpact();
  static void heavyHaptic() => HapticFeedback.heavyImpact();
  static void selectionHaptic() => HapticFeedback.selectionClick();
}

/// Enhanced AnimatedContainer with premium animations
class PremiumAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;
  final bool enableHaptic;

  const PremiumAnimatedContainer({
    super.key,
    required this.child,
    this.duration = PremiumUIEnhancements.mediumDuration,
    this.curve = PremiumUIEnhancements.premiumCurve,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
    this.alignment,
    this.onTap,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () {
        if (enableHaptic) PremiumUIEnhancements.lightHaptic();
        onTap!();
      } : null,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        padding: padding,
        margin: margin,
        decoration: decoration,
        width: width,
        height: height,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// Smooth fade-in animation for messages
class SmoothFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double offsetY;

  const SmoothFadeIn({
    super.key,
    required this.child,
    this.duration = PremiumUIEnhancements.mediumDuration,
    this.delay = Duration.zero,
    this.curve = PremiumUIEnhancements.smoothCurve,
    this.offsetY = 20.0,
  });

  @override
  State<SmoothFadeIn> createState() => _SmoothFadeInState();
}

class _SmoothFadeInState extends State<SmoothFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Premium Button with enhanced interactions
class PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool isLoading;

  const PremiumButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.elevation = 2.0,
    this.isLoading = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumUIEnhancements.fastDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PremiumUIEnhancements.premiumCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PremiumUIEnhancements.premiumCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    PremiumUIEnhancements.lightHaptic();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              color: widget.backgroundColor ?? Theme.of(context).primaryColor,
              child: Container(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            widget.foregroundColor ?? Colors.white,
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: TextStyle(
                          color: widget.foregroundColor ?? Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        child: widget.child,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Smooth loading indicator
class SmoothLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const SmoothLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  State<SmoothLoadingIndicator> createState() => _SmoothLoadingIndicatorState();
}

class _SmoothLoadingIndicatorState extends State<SmoothLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CircularProgressIndicator(
            value: null,
            strokeWidth: widget.strokeWidth,
            valueColor: AlwaysStoppedAnimation(
              widget.color ?? Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced TextField with smooth animations
class PremiumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool enabled;
  final TextInputType? keyboardType;

  const PremiumTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PremiumUIEnhancements.fastDuration,
      vsync: this,
    );
    _focusNode = FocusNode();

    _borderColorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: Theme.of(context).primaryColor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PremiumUIEnhancements.premiumCurve,
    ));

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColorAnimation.value ?? Colors.grey.shade300,
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            onSubmitted: (value) {
              if (widget.onSubmitted != null) {
                PremiumUIEnhancements.selectionHaptic();
                widget.onSubmitted!();
              }
            },
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        );
      },
    );
  }
}

/// Staggered animation for list items
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final Duration staggerDelay;

  const StaggeredListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return SmoothFadeIn(
          delay: Duration(milliseconds: index * staggerDelay.inMilliseconds),
          child: children[index],
        );
      },
    );
  }
}

/// Enhanced Card with premium styling
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = 4.0,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        elevation: elevation,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        color: backgroundColor ?? Theme.of(context).cardColor,
        child: InkWell(
          onTap: onTap != null ? () {
            PremiumUIEnhancements.lightHaptic();
            onTap!();
          } : null,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Smooth page transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SmoothPageRoute({
    required this.page,
    this.duration = PremiumUIEnhancements.mediumDuration,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = PremiumUIEnhancements.premiumCurve;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: animation.drive(tween),
                child: child,
              ),
            );
          },
        );
}

/// Premium App Bar with smooth animations
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: foregroundColor,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}