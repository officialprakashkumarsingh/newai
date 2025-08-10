import 'package:flutter/material.dart';
import 'micro_interactions.dart';

class GeneratingIndicator extends StatefulWidget {
  final double? size;
  
  const GeneratingIndicator({Key? key, this.size}) : super(key: key);
  
  @override
  State<GeneratingIndicator> createState() => _GeneratingIndicatorState();
}

class _GeneratingIndicatorState extends State<GeneratingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingDots(
      size: (widget.size ?? 20.0) / 3,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}