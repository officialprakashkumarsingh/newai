import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Check if content contains LaTeX formulas
    if (_containsLatexFormulas(content)) {
      return _buildMixedContent(context);
    }
    
    // For simple markdown without formulas
    return _buildMarkdownContent(context);
  }

  bool _containsLatexFormulas(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$\n]+\$').hasMatch(text) ||     // Inline math
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text);     // Chemistry
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

  Widget _buildMixedContent(BuildContext context) {
    List<Widget> widgets = [];
    String remaining = content;
    
    while (remaining.isNotEmpty) {
      // Look for display math first ($$...$$)
      final displayMatch = RegExp(r'\$\$([^$]+)\$\$').firstMatch(remaining);
      if (displayMatch != null && displayMatch.start == 0) {
        widgets.add(_buildDisplayMath(displayMatch.group(1)!, context));
        remaining = remaining.substring(displayMatch.end);
        continue;
      }
      
      // Look for inline math ($...$)
      final inlineMatch = RegExp(r'\$([^$\n]+)\$').firstMatch(remaining);
      if (inlineMatch != null && inlineMatch.start == 0) {
        widgets.add(_buildInlineMath(inlineMatch.group(1)!, context));
        remaining = remaining.substring(inlineMatch.end);
        continue;
      }
      
      // Find next formula
      int nextFormulaIndex = remaining.length;
      
      final nextDisplay = RegExp(r'\$\$[^$]+\$\$').firstMatch(remaining);
      if (nextDisplay != null && nextDisplay.start < nextFormulaIndex) {
        nextFormulaIndex = nextDisplay.start;
      }
      
      final nextInline = RegExp(r'\$[^$\n]+\$').firstMatch(remaining);
      if (nextInline != null && nextInline.start < nextFormulaIndex) {
        nextFormulaIndex = nextInline.start;
      }
      
      // Add text before next formula
      if (nextFormulaIndex > 0) {
        String textPart = remaining.substring(0, nextFormulaIndex);
        if (textPart.trim().isNotEmpty) {
          widgets.add(MarkdownBody(
            data: textPart,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 16.0,
                color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ));
        }
        remaining = remaining.substring(nextFormulaIndex);
      } else {
        // No more formulas, add remaining text
        if (remaining.trim().isNotEmpty) {
          widgets.add(MarkdownBody(
            data: remaining,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 16.0,
                color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ));
        }
        break;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildDisplayMath(String latex, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Math.tex(
          latex,
          textStyle: TextStyle(
            fontSize: 20.0,
            color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMath(String latex, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Math.tex(
        latex,
        textStyle: TextStyle(
          fontSize: 16.0,
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}