import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'theme.dart';
import 'latex_widget.dart';


/// Custom code highlight widget for markdown
class CodeHighlightWidget extends StatelessWidget {
  final String code;
  final String? language;

  const CodeHighlightWidget({
    super.key,
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = !isLightTheme(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with language and copy button
          if (language != null && language!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A202C) : const Color(0xFFEDF2F7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language!.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyToClipboard(context),
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ),
          
          // Code content with syntax highlighting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                code.trim(),
                language: _getHighlightLanguage(language),
                theme: isDark ? vs2015Theme : githubTheme,
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.grey[100] : Colors.grey[800],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHighlightLanguage(String? lang) {
    if (lang == null || lang.isEmpty) return 'plaintext';
    
    // Map common language aliases to flutter_highlight supported languages
    final languageMap = {
      'js': 'javascript',
      'jsx': 'javascript',
      'ts': 'typescript',
      'tsx': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'md': 'markdown',
      'yml': 'yaml',
      'sh': 'bash',
      'shell': 'bash',
      'cmd': 'batch',
      'ps1': 'powershell',
      'kt': 'kotlin',
      'cs': 'csharp',
      'cpp': 'cpp',
      'c++': 'cpp',
      'cc': 'cpp',
      'h': 'cpp',
      'hpp': 'cpp',
      'cxx': 'cpp',
    };

    return languageMap[lang.toLowerCase()] ?? lang.toLowerCase();
  }

  void _copyToClipboard(BuildContext context) {
    // This would copy the code to clipboard
    // Implementation would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Code highlighting temporarily removed for compatibility

/// Enhanced MarkdownBody with code highlighting and LaTeX support
class EnhancedMarkdownBody extends StatelessWidget {
  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  const EnhancedMarkdownBody({
    super.key,
    required this.data,
    this.selectable = true,
    this.styleSheet,
  });

  @override
  Widget build(BuildContext context) {
    // Check if content contains LaTeX
    if (LaTeXProcessor.containsLaTeX(data)) {
      return _buildContentWithLatex(context);
    }
    
    return MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet,
      // Code highlighting temporarily disabled for compatibility
      syntaxHighlighter: CustomSyntaxHighlighter(),
    );
  }

  Widget _buildContentWithLatex(BuildContext context) {
    // Split content into LaTeX and non-LaTeX parts
    final parts = LaTeXProcessor.parseContent(data);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isLatex) {
          return LaTeXWidget(
            latex: part.content,
            isDisplayMode: part.isDisplayMode,
          );
        } else {
          // Regular markdown content
                     return MarkdownBody(
             data: part.content,
             selectable: selectable,
             styleSheet: styleSheet,
             // Code highlighting temporarily disabled for compatibility
             syntaxHighlighter: CustomSyntaxHighlighter(),
           );
        }
      }).toList(),
    );
  }
}

/// Custom syntax highlighter for inline code and code blocks
class CustomSyntaxHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    return TextSpan(
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      text: source,
    );
  }
}

/// Enhanced inline code styling
TextStyle getInlineCodeStyle(BuildContext context) {
  final isDark = !isLightTheme(context);
  
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    backgroundColor: isDark 
      ? const Color(0xFF2D3748).withOpacity(0.8)
      : const Color(0xFFF7FAFC).withOpacity(0.8),
    color: isDark 
      ? const Color(0xFFE53E3E)  // Red for dark theme
      : const Color(0xFFD53F8C), // Pink for light theme
    fontWeight: FontWeight.w500,
  );
}