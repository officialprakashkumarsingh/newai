import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'flutter_tex_widget.dart';

class EnhancedContentWidget extends StatelessWidget {
  final String content;
  final bool isUserMessage;
  final bool isThinkingMode;

  const EnhancedContentWidget({
    super.key,
    required this.content,
    this.isUserMessage = false,
    this.isThinkingMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Process formulas in BOTH thinking mode AND normal mode
    if (_containsFormulas(content)) {
      return _buildEnhancedContent(context);
    }
    
    // For simple content without formulas, use MarkdownBody widget
    return _buildMarkdownContent(context);
  }

  bool _containsFormulas(String text) {
    // Use flutter_tex formula detection
    return FlutterTexUtils.containsFormula(text);
  }

  Widget _buildEnhancedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _parseAndRenderContent(context),
    );
  }

  List<Widget> _parseAndRenderContent(BuildContext context) {
    List<Widget> widgets = [];
    String remaining = content;
    
    while (remaining.isNotEmpty) {
      // Look for display math ($$...$$) first
      final displayMathMatch = RegExp(r'\$\$([^$]+)\$\$').firstMatch(remaining);
      if (displayMathMatch != null && displayMathMatch.start == 0) {
        widgets.add(FlutterTexWidget(
          content: displayMathMatch.group(0)!,
          isUserMessage: isUserMessage,
          textStyle: TextStyle(
            fontSize: 18,
            color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ));
        remaining = remaining.substring(displayMathMatch.end);
        continue;
      }
      
      // Look for inline math/chemistry ($...$)
      final inlineMathMatch = RegExp(r'\$([^$\n]+)\$').firstMatch(remaining);
      if (inlineMathMatch != null && inlineMathMatch.start == 0) {
        widgets.add(FlutterTexWidget(
          content: inlineMathMatch.group(0)!,
          isUserMessage: isUserMessage,
          textStyle: TextStyle(
            fontSize: 16,
            color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ));
        remaining = remaining.substring(inlineMathMatch.end);
        continue;
      }
      
      // Look for chemical formulas without $ symbols
      final chemMatch = RegExp(r'\\ce\{([^}]+)\}').firstMatch(remaining);
      if (chemMatch != null && chemMatch.start == 0) {
        widgets.add(FlutterTexWidget(
          content: chemMatch.group(0)!,
          isUserMessage: isUserMessage,
          textStyle: TextStyle(
            fontSize: 16,
            color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ));
        remaining = remaining.substring(chemMatch.end);
        continue;
      }
      

      

      
      // Find the next formula
      int nextFormulaIndex = remaining.length;
      
      final nextDisplayMath = RegExp(r'\$\$[^$]+\$\$').firstMatch(remaining);
      if (nextDisplayMath != null && nextDisplayMath.start < nextFormulaIndex) {
        nextFormulaIndex = nextDisplayMath.start;
      }
      
      final nextInlineMath = RegExp(r'\$[^$\n]+\$').firstMatch(remaining);
      if (nextInlineMath != null && nextInlineMath.start < nextFormulaIndex) {
        nextFormulaIndex = nextInlineMath.start;
      }
      
      final nextChem = RegExp(r'\\ce\{[^}]+\}').firstMatch(remaining);
      if (nextChem != null && nextChem.start < nextFormulaIndex) {
        nextFormulaIndex = nextChem.start;
      }
      
      // Add text before the next formula
      if (nextFormulaIndex > 0) {
        String textContent = remaining.substring(0, nextFormulaIndex);
        if (textContent.trim().isNotEmpty) {
          widgets.add(_buildMarkdownFromText(context, textContent));
        }
        remaining = remaining.substring(nextFormulaIndex);
      } else {
        // No more formulas, add remaining text
        if (remaining.trim().isNotEmpty) {
          widgets.add(_buildMarkdownFromText(context, remaining));
        }
        break;
      }
    }
    
    return widgets;
  }

  Widget _buildMarkdownContent(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 16.0,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.4,
        ),
        h1: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineLarge?.color,
        ),
        h2: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineMedium?.color,
        ),
        h3: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.headlineSmall?.color,
        ),
        code: TextStyle(
          backgroundColor: Theme.of(context).cardColor,
          fontFamily: 'monospace',
          fontSize: 14.0,
        ),
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        codeblockPadding: const EdgeInsets.all(12.0),
        blockquote: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.grey.shade400,
              width: 4.0,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16.0),
        listBullet: TextStyle(
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _buildMarkdownFromText(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 16.0,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.4,
        ),
        code: TextStyle(
          backgroundColor: Theme.of(context).cardColor,
          fontFamily: 'monospace',
          fontSize: 14.0,
        ),
        listBullet: TextStyle(
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}

// Enhanced utility class for detecting various content types
class ContentUtils {
  static bool containsChemicalFormulas(String text) {
    return RegExp(r'\$\\ce\{[^}]+\}\$').hasMatch(text) ||
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text) ||
           RegExp(r'\b[A-Z][a-z]?\d*\b').hasMatch(text);
  }
  
  static bool containsLatex(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||
           RegExp(r'\$[^$]+\$').hasMatch(text) ||
           RegExp(r'\\begin\{[^}]+\}').hasMatch(text) ||
           RegExp(r'\\[a-zA-Z]+\{').hasMatch(text);
  }
  
  static bool containsMarkdown(String text) {
    return text.contains('**') || 
           text.contains('*') || 
           text.contains('```') ||
           text.contains('`') ||
           text.contains('#') ||
           text.contains('[') && text.contains('](');
  }
}