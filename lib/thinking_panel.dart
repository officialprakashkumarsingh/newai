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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? Colors.grey.shade100 
                    : Colors.grey.shade800.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLightTheme(context) 
                      ? Colors.grey.shade300 
                      : Colors.grey.shade600,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: isLightTheme(context) 
                        ? Colors.grey.shade600 
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.psychology,
                    size: 16,
                    color: isLightTheme(context) 
                        ? Colors.blue.shade600 
                        : Colors.blue.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isLightTheme(context) 
                          ? Colors.grey.shade700 
                          : Colors.grey.shade300,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isExpanded ? 'Hide' : 'Show',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLightTheme(context) 
                          ? Colors.blue.shade600 
                          : Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded thinking content
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? Colors.grey.shade50 
                    : Colors.grey.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLightTheme(context) 
                      ? Colors.grey.shade200 
                      : Colors.grey.shade700,
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