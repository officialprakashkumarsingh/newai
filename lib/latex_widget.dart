import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
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
        child: Math.tex(
          latex,
          textStyle: TextStyle(
            fontSize: fontSize ?? (isDisplayMode ? 18 : 16),
            color: isDark ? Colors.white : Colors.black87,
          ),
          mathStyle: isDisplayMode ? MathStyle.display : MathStyle.text,
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

  /// Parse content into LaTeX and non-LaTeX parts
  static List<ContentPart> parseContent(String text) {
    final parts = <ContentPart>[];
    var currentIndex = 0;

    // Find all math expressions
    final allMatches = <_MathMatch>[];
    
    // Add display math
    for (final match in _displayMathRegex.allMatches(text)) {
      allMatches.add(_MathMatch(
        start: match.start,
        end: match.end,
        latex: match.group(1)!,
        isDisplay: true,
      ));
    }
    
    // Add inline math (skip if inside display math)
    for (final match in _inlineMathRegex.allMatches(text)) {
      bool insideDisplay = false;
      for (final displayMatch in _displayMathRegex.allMatches(text)) {
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

    // Sort by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Create content parts
    for (final match in allMatches) {
      // Add text before math
      if (currentIndex < match.start) {
        final beforeText = text.substring(currentIndex, match.start);
        if (beforeText.trim().isNotEmpty) {
          parts.add(ContentPart(
            content: beforeText,
            isLatex: false,
            isDisplayMode: false,
          ));
        }
      }

      // Add LaTeX part
      parts.add(ContentPart(
        content: match.latex,
        isLatex: true,
        isDisplayMode: match.isDisplay,
      ));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      final remainingText = text.substring(currentIndex);
      if (remainingText.trim().isNotEmpty) {
        parts.add(ContentPart(
          content: remainingText,
          isLatex: false,
          isDisplayMode: false,
        ));
      }
    }

    // If no LaTeX found, return the original text as one part
    if (parts.isEmpty) {
      parts.add(ContentPart(
        content: text,
        isLatex: false,
        isDisplayMode: false,
      ));
    }

    return parts;
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

/// Represents a part of content that can be either LaTeX or regular text
class ContentPart {
  final String content;
  final bool isLatex;
  final bool isDisplayMode;

  ContentPart({
    required this.content,
    required this.isLatex,
    required this.isDisplayMode,
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