import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'theme.dart';

/// Widget for rendering LaTeX mathematical expressions
class LaTeXWidget extends StatefulWidget {
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
  State<LaTeXWidget> createState() => _LaTeXWidgetState();
}

class _LaTeXWidgetState extends State<LaTeXWidget> {
  static const platform = MethodChannel('com.ahamai.latex');
  
  Future<Widget>? _latexFuture;
  
  @override
  void initState() {
    super.initState();
    _latexFuture = _renderLatex();
  }
  
  @override
  void didUpdateWidget(LaTeXWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex || 
        oldWidget.isDisplayMode != widget.isDisplayMode) {
      _latexFuture = _renderLatex();
    }
  }

  Future<Widget> _renderLatex() async {
    final isDark = !isLightTheme(context);
    
    try {
      final result = await platform.invokeMethod('renderLatex', {
        'latex': widget.latex,
        'isDisplayMode': widget.isDisplayMode,
        'isDarkTheme': isDark,
      });
      
      if (result['success'] == true && result['image'] != null) {
        final imageBytes = base64Decode(result['image']);
        
        return Container(
          margin: widget.isDisplayMode 
            ? const EdgeInsets.symmetric(vertical: 12, horizontal: 4)
            : const EdgeInsets.symmetric(vertical: 4),
          padding: widget.isDisplayMode 
            ? const EdgeInsets.all(16)
            : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: widget.isDisplayMode ? BoxDecoration(
            color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ) : null,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Unknown rendering error');
      }
    } catch (e) {
      // Fallback for invalid LaTeX or rendering errors
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'LaTeX Error: ${widget.latex}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _latexFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Rendering LaTeX...', style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Failed to render: ${widget.latex}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          );
        } else {
          return snapshot.data ?? const SizedBox.shrink();
        }
      },
    );
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
      final parts = LaTeXProcessor.parseContent(text);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts.map((part) {
          if (part.isLatex) {
            return LaTeXWidget(
              latex: part.content,
              isDisplayMode: part.isDisplayMode,
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                part.content,
                style: style ?? Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
        }).toList(),
      );
    }

    return Text(text, style: style);
  }
}