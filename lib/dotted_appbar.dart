import 'package:flutter/material.dart';
import 'dotted_background.dart';

/// Custom AppBar with dotted background pattern
class DottedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final IconThemeData? iconTheme;
  final TextStyle? titleTextStyle;
  final Color? foregroundColor;

  const DottedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.iconTheme,
    this.titleTextStyle,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      elevation: elevation,
      iconTheme: iconTheme,
      titleTextStyle: titleTextStyle,
      foregroundColor: foregroundColor,
      flexibleSpace: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: DottedPatternPainter(
            dotSize: 2.0,
            spacing: 16.0,
            dotColor: theme.brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.12) 
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Flexible AppBar that can be used anywhere
class FlexibleDottedAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final IconThemeData? iconTheme;
  final TextStyle? titleTextStyle;
  final Color? foregroundColor;
  final double height;

  const FlexibleDottedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
    this.iconTheme,
    this.titleTextStyle,
    this.foregroundColor,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      child: Stack(
        children: [
          // Dotted background
          Positioned.fill(
            child: DottedBackground(
              dotSize: 1.5,
              spacing: 18.0,
              child: Container(
                color: backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
              ),
            ),
          ),
          // AppBar content
          SafeArea(
            bottom: false,
            child: Container(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: NavigationToolbar(
                leading: automaticallyImplyLeading && leading == null 
                    ? _defaultLeading(context) 
                    : leading,
                middle: title,
                trailing: actions != null && actions!.isNotEmpty 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ) 
                    : null,
                centerMiddle: centerTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _defaultLeading(BuildContext context) {
    final parentRoute = ModalRoute.of(context);
    final hasDrawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    final canPop = parentRoute?.canPop ?? false;

    if (hasDrawer) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    } else if (canPop) {
      return const BackButton();
    }
    return null;
  }
}