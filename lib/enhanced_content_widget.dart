import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:markdown/markdown.dart' as md;
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
    // Use MarkdownBody with LaTeX extension for all content
    return _buildMarkdownWithLatex(context);
  }

  Widget _buildMarkdownWithLatex(BuildContext context) {
    // Check if content has LaTeX formulas
    if (_hasLatexFormulas(content)) {
      return _buildContentWithLatexFallback(context);
    }
    
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

  bool _hasLatexFormulas(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$\n]+\$').hasMatch(text) ||     // Inline math
           RegExp(r'\\[a-zA-Z]+\{').hasMatch(text);     // LaTeX commands
  }

  Widget _buildContentWithLatexFallback(BuildContext context) {
    // For now, show LaTeX formulas as code blocks until flutter_math_fork compatibility is fixed
    String processedContent = content
        .replaceAllMapped(
          RegExp(r'\$\$([^$]+)\$\$'),
          (match) => '```latex\n${match.group(1)!}\n```',
        )
        .replaceAllMapped(
          RegExp(r'\$([^$\n]+)\$'),
          (match) => '`${match.group(1)!}`',
        );

    return MarkdownBody(
      data: processedContent,
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
          backgroundColor: Colors.lightBlue.shade50,
          fontFamily: 'monospace',
          fontSize: 14.0,
          color: Colors.blue.shade800,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.blue.shade200),
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
}