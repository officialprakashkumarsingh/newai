import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'theme.dart';

/// Widget for rendering LaTeX mathematical expressions
class LaTeXWidget extends StatelessWidget {
  final String latex;
  final bool isDisplayMode;
  final double? fontSize;

  const LaTeXWidget({
    super.key,
    required this.latex,
    this.isDisplayMode = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = !isLightTheme(context);
    
    try {
      return Container(
        margin: isDisplayMode 
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 4)
          : EdgeInsets.zero,
        padding: isDisplayMode 
          ? const EdgeInsets.all(16)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: isDisplayMode ? BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ) : null,
        child: TeXView(
          child: TeXViewDocument(latex),
          style: TeXViewStyle(
            backgroundColor: Colors.transparent,
            contentColor: isDark ? Colors.white : Colors.black87,
            fontSize: (fontSize ?? (isDisplayMode ? 18 : 16)).toInt(),
          ),
        ),
      );
    } catch (e) {
      // Fallback for invalid LaTeX
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          'LaTeX Error: $latex',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.red[700],
          ),
        ),
      );
    }
  }
}

/// Processes text to find and render LaTeX expressions
class LaTeXProcessor {
  static final RegExp _displayMathRegex = RegExp(r'\$\$(.*?)\$\$', multiLine: true, dotAll: true);
  static final RegExp _inlineMathRegex = RegExp(r'\$(.*?)\$');

  /// Converts text with LaTeX to a list of widgets
  static List<Widget> processText(String text, BuildContext context) {
    final widgets = <Widget>[];
    var currentIndex = 0;

    // Find all display math expressions first
    final displayMatches = _displayMathRegex.allMatches(text);
    final inlineMatches = _inlineMathRegex.allMatches(text);

    // Combine and sort all matches by position
    final allMatches = <_MathMatch>[];
    
    for (final match in displayMatches) {
      allMatches.add(_MathMatch(
        start: match.start,
        end: match.end,
        latex: match.group(1)!,
        isDisplay: true,
      ));
    }
    
    for (final match in inlineMatches) {
      // Skip if this inline match is inside a display match
      bool insideDisplay = false;
      for (final displayMatch in displayMatches) {
        if (match.start >= displayMatch.start && match.end <= displayMatch.end) {
          insideDisplay = true;
          break;
        }
      }
      if (!insideDisplay) {
        allMatches.add(_MathMatch(
          start: match.start,
          end: match.end,
          latex: match.group(1)!,
          isDisplay: false,
        ));
      }
    }

    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Process text and create widgets
    for (final match in allMatches) {
      // Add text before the match
      if (currentIndex < match.start) {
        final beforeText = text.substring(currentIndex, match.start);
        if (beforeText.trim().isNotEmpty) {
          widgets.add(_createTextWidget(beforeText, context));
        }
      }

      // Add the LaTeX widget
      widgets.add(LaTeXWidget(
        latex: match.latex,
        isDisplayMode: match.isDisplay,
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);
      if (remainingText.trim().isNotEmpty) {
        widgets.add(_createTextWidget(remainingText, context));
      }
    }

    // If no LaTeX was found, return the original text
    if (widgets.isEmpty) {
      widgets.add(_createTextWidget(text, context));
    }

    return widgets;
  }

  static Widget _createTextWidget(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  /// Check if text contains LaTeX expressions
  static bool containsLaTeX(String text) {
    return _displayMathRegex.hasMatch(text) || _inlineMathRegex.hasMatch(text);
  }

  /// Extract LaTeX expressions from text for preview
  static List<String> extractLaTeX(String text) {
    final expressions = <String>[];
    
    for (final match in _displayMathRegex.allMatches(text)) {
      expressions.add('\$\$${match.group(1)!}\$\$');
    }
    
    for (final match in _inlineMathRegex.allMatches(text)) {
      // Skip if inside display math
      bool insideDisplay = false;
      for (final displayMatch in _displayMathRegex.allMatches(text)) {
        if (match.start >= displayMatch.start && match.end <= displayMatch.end) {
          insideDisplay = true;
          break;
        }
      }
      if (!insideDisplay) {
        expressions.add('\$${match.group(1)!}\$');
      }
    }
    
    return expressions;
  }
}

class _MathMatch {
  final int start;
  final int end;
  final String latex;
  final bool isDisplay;

  _MathMatch({
    required this.start,
    required this.end,
    required this.latex,
    required this.isDisplay,
  });
}

/// Enhanced text widget that supports both markdown and LaTeX
class EnhancedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const EnhancedTextWidget({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (LaTeXProcessor.containsLaTeX(text)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: LaTeXProcessor.processText(text, context),
      );
    }

    return Text(text, style: style);
  }
}