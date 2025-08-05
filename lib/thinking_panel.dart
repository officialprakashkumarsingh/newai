import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'theme.dart';

class ThinkingPanel extends StatefulWidget {
  final String thinkingContent;
  final String finalContent;

  const ThinkingPanel({
    super.key,
    required this.thinkingContent,
    required this.finalContent,
  });

  @override
  State<ThinkingPanel> createState() => _ThinkingPanelState();
}

class _ThinkingPanelState extends State<ThinkingPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasThinking = widget.thinkingContent.trim().isNotEmpty;
    final hasFinalContent = widget.finalContent.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thinking panel (if there's thinking content)
        if (hasThinking) ...[
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? const Color(0xFFF8F9FA)
                    : const Color(0xFF1A1D21),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isLightTheme(context) 
                      ? const Color(0xFFE9ECEF) 
                      : const Color(0xFF2D3748),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isLightTheme(context) 
                          ? Colors.grey.shade600 
                          : Colors.grey.shade400,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: isLightTheme(context) 
                        ? Colors.grey.shade500 
                        : Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded thinking content
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? const Color(0xFFFBFCFD)
                    : const Color(0xFF0F1419),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isLightTheme(context) 
                      ? const Color(0xFFE9ECEF) 
                      : const Color(0xFF2D3748),
                  width: 1,
                ),
              ),
              child: MarkdownBody(
                data: widget.thinkingContent,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(
                    fontSize: 13,
                    color: isLightTheme(context) 
                        ? Colors.grey.shade700 
                        : Colors.grey.shade300,
                    height: 1.4,
                  ),
                  code: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    backgroundColor: isLightTheme(context) 
                        ? Colors.grey.shade200 
                        : Colors.grey.shade800,
                    color: isLightTheme(context) 
                        ? Colors.grey.shade800 
                        : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
        ],
        
        // Final content (if any)
        if (hasFinalContent)
          MarkdownBody(
            data: widget.finalContent,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
          ),
      ],
    );
  }
}

class ThinkingContentParser {
  // Regex patterns for different thinking tags
  static final List<RegExp> _thinkingPatterns = [
    RegExp(r'<thoughts?>(.*?)</thoughts?>', dotAll: true, caseSensitive: false),
    RegExp(r'<think(?:ing)?>(.*?)</think(?:ing)?>', dotAll: true, caseSensitive: false),
    RegExp(r'<reason(?:ing)?>(.*?)</reason(?:ing)?>', dotAll: true, caseSensitive: false),
  ];

  /// Parse content and extract thinking/reasoning sections
  static Map<String, String> parseContent(String rawContent) {
    String thinkingContent = '';
    String finalContent = rawContent;

    // Extract thinking content from all patterns
    for (final pattern in _thinkingPatterns) {
      final matches = pattern.allMatches(rawContent);
      for (final match in matches) {
        final thinking = match.group(1)?.trim() ?? '';
        if (thinking.isNotEmpty) {
          if (thinkingContent.isNotEmpty) {
            thinkingContent += '\n\n---\n\n';
          }
          thinkingContent += thinking;
        }
        
        // Remove the thinking tags from final content
        finalContent = finalContent.replaceAll(match.group(0) ?? '', '');
      }
    }

    return {
      'thinking': thinkingContent.trim(),
      'final': finalContent.trim(),
    };
  }

  /// Check if content contains thinking tags
  static bool hasThinkingContent(String content) {
    return _thinkingPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// Extract thinking content as it streams (for partial content)
  static String extractStreamingThinking(String streamContent) {
    String thinking = '';
    
    for (final pattern in _thinkingPatterns) {
      final matches = pattern.allMatches(streamContent);
      for (final match in matches) {
        final content = match.group(1)?.trim() ?? '';
        if (content.isNotEmpty) {
          if (thinking.isNotEmpty) thinking += '\n\n';
          thinking += content;
        }
      }
    }
    
    return thinking;
  }

  /// Remove thinking tags from content (for final display)
  static String removeThinkingTags(String content) {
    String result = content;
    
    for (final pattern in _thinkingPatterns) {
      result = result.replaceAll(pattern, '').trim();
    }
    
    // Clean up multiple line breaks
    result = result.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return result.trim();
  }
}