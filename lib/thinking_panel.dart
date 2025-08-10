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

class _ThinkingPanelState extends State<ThinkingPanel> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

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
            onTap: _toggleExpanded,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLightTheme(context) 
                      ? [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)]
                      : [const Color(0xFF2A1B3D), const Color(0xFF44318D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 20,
                    color: isLightTheme(context) 
                        ? Colors.purple.shade700
                        : Colors.purple.shade200,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Thinking Process',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isLightTheme(context) 
                          ? Colors.purple.shade800
                          : Colors.purple.shade100,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: isLightTheme(context) 
                          ? Colors.purple.shade600
                          : Colors.purple.shade200,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded thinking content with animation
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isLightTheme(context) 
                    ? Colors.purple.shade50.withOpacity(0.5)
                    : Colors.purple.shade900.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLightTheme(context)
                      ? Colors.purple.shade200
                      : Colors.purple.shade700,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: isLightTheme(context)
                            ? Colors.purple.shade600
                            : Colors.purple.shade300,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Reasoning:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isLightTheme(context)
                              ? Colors.purple.shade700
                              : Colors.purple.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: widget.thinkingContent,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(
                        fontSize: 13,
                        color: isLightTheme(context) 
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        fontSize: 12,
                        backgroundColor: isLightTheme(context)
                            ? Colors.purple.shade100
                            : Colors.purple.shade900.withOpacity(0.5),
                        color: isLightTheme(context)
                            ? Colors.purple.shade900
                            : Colors.purple.shade100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Final content (if any)
        if (hasFinalContent)
          MarkdownBody(
            data: widget.finalContent,
            selectable: true,
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
    RegExp(r'<reflection>(.*?)</reflection>', dotAll: true, caseSensitive: false),
    RegExp(r'<inner_thoughts?>(.*?)</inner_thoughts?>', dotAll: true, caseSensitive: false),
  ];
  
  // Patterns for detecting incomplete/open thinking tags during streaming
  static final List<RegExp> _openThinkingPatterns = [
    RegExp(r'<thoughts?>([^<]*?)$', dotAll: true, caseSensitive: false),
    RegExp(r'<think(?:ing)?>([^<]*?)$', dotAll: true, caseSensitive: false),
    RegExp(r'<reason(?:ing)?>([^<]*?)$', dotAll: true, caseSensitive: false),
    RegExp(r'<reflection>([^<]*?)$', dotAll: true, caseSensitive: false),
    RegExp(r'<inner_thoughts?>([^<]*?)$', dotAll: true, caseSensitive: false),
  ];

  /// Parse content and extract thinking/reasoning sections
  static Map<String, String> parseContent(String rawContent) {
    String thinkingContent = '';
    String finalContent = rawContent;

    // First, try to extract complete thinking tags
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
    
    // If no complete tags found, check for open tags (streaming)
    if (thinkingContent.isEmpty) {
      for (final pattern in _openThinkingPatterns) {
        final match = pattern.firstMatch(rawContent);
        if (match != null) {
          final thinking = match.group(1)?.trim() ?? '';
          if (thinking.isNotEmpty) {
            thinkingContent = thinking + '...';
            // Remove the partial thinking tag from final content
            finalContent = finalContent.replaceAll(match.group(0) ?? '', '');
          }
          break; // Use first match only
        }
      }
    }

    return {
      'thinking': thinkingContent.trim(),
      'final': finalContent.trim(),
    };
  }

  /// Check if content contains thinking tags
  static bool hasThinkingContent(String content) {
    // Check for complete tags
    if (_thinkingPatterns.any((pattern) => pattern.hasMatch(content))) {
      return true;
    }
    // Check for open tags (streaming)
    return _openThinkingPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// Extract thinking content as it streams (for partial content)
  static String extractStreamingThinking(String streamContent) {
    String thinking = '';
    
    // First check for complete tags
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
    
    // If no complete tags, check for open tags
    if (thinking.isEmpty) {
      for (final pattern in _openThinkingPatterns) {
        final match = pattern.firstMatch(streamContent);
        if (match != null) {
          final content = match.group(1)?.trim() ?? '';
          if (content.isNotEmpty) {
            thinking = content + '...';
          }
          break;
        }
      }
    }
    
    return thinking;
  }

  /// Remove thinking tags from content (for final display)
  static String removeThinkingTags(String content) {
    String result = content;
    
    // Remove complete tags
    for (final pattern in _thinkingPatterns) {
      result = result.replaceAll(pattern, '').trim();
    }
    
    // Remove partial/open tags
    for (final pattern in _openThinkingPatterns) {
      result = result.replaceAll(pattern, '').trim();
    }
    
    // Clean up multiple line breaks
    result = result.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return result.trim();
  }
}