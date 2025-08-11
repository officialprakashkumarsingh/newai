import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'chemjax_widget.dart';

class EnhancedContentWidget extends StatelessWidget {
  final String content;
  final bool isUserMessage;

  const EnhancedContentWidget({
    super.key,
    required this.content,
    this.isUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if content contains chemical formulas or LaTeX
    if (_containsChemicalFormulas(content) || _containsLatex(content)) {
      return _buildEnhancedContent(context);
    }
    
    // For simple content, use HTML widget with markdown conversion
    return _buildHtmlContent(context);
  }

  bool _containsChemicalFormulas(String text) {
    // Check for ChemJAX patterns
    return RegExp(r'\$\\ce\{[^}]+\}\$').hasMatch(text) ||
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text) ||
           ChemJAXUtils.containsChemicalFormula(text);
  }

  bool _containsLatex(String text) {
    // Check for LaTeX math patterns
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$]+\$').hasMatch(text) ||       // Inline math (excluding ChemJAX)
           RegExp(r'\\begin\{[^}]+\}').hasMatch(text) || // LaTeX environments
           RegExp(r'\\[a-zA-Z]+\{').hasMatch(text);     // LaTeX commands
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
      // Look for ChemJAX formulas first (highest priority)
      final chemjaxMatch = RegExp(r'\$\\ce\{([^}]+)\}\$').firstMatch(remaining);
      if (chemjaxMatch != null && chemjaxMatch.start == 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: ChemJAXWidget(
            formula: r'$\ce{' + chemjaxMatch.group(1)! + r'}$',
            textStyle: TextStyle(
              fontSize: 16,
              color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ));
        remaining = remaining.substring(chemjaxMatch.end);
        continue;
      }
      
      // Look for display math ($$...$$)
      final displayMathMatch = RegExp(r'\$\$([^$]+)\$\$').firstMatch(remaining);
      if (displayMathMatch != null && displayMathMatch.start == 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: ChemJAXWidget(
              formula: r'$$' + displayMathMatch.group(1)! + r'$$',
              width: double.infinity,
              height: 80,
              backgroundColor: isUserMessage 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface,
              textStyle: TextStyle(
                color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 18,
              ),
            ),
          ),
        ));
        remaining = remaining.substring(displayMathMatch.end);
        continue;
      }
      
      // Look for inline math ($...$) but exclude ChemJAX
      final inlineMathMatch = RegExp(r'\$([^$]+)\$').firstMatch(remaining);
      if (inlineMathMatch != null && 
          inlineMathMatch.start == 0 && 
          !inlineMathMatch.group(1)!.startsWith(r'\ce{')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: ChemJAXWidget(
            formula: r'$' + inlineMathMatch.group(1)! + r'$',
            width: double.infinity,
            height: 40,
            backgroundColor: isUserMessage 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.surface,
            textStyle: TextStyle(
              color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
          ),
        ));
        remaining = remaining.substring(inlineMathMatch.end);
        continue;
      }
      
      // Find the next special content
      int nextSpecialIndex = remaining.length;
      
      final nextChemjax = RegExp(r'\$\\ce\{[^}]+\}\$').firstMatch(remaining);
      if (nextChemjax != null) {
        nextSpecialIndex = nextChemjax.start;
      }
      
      final nextDisplayMath = RegExp(r'\$\$[^$]+\$\$').firstMatch(remaining);
      if (nextDisplayMath != null && nextDisplayMath.start < nextSpecialIndex) {
        nextSpecialIndex = nextDisplayMath.start;
      }
      
      final nextInlineMath = RegExp(r'\$[^$]+\$').firstMatch(remaining);
      if (nextInlineMath != null && 
          nextInlineMath.start < nextSpecialIndex &&
          !nextInlineMath.group(0)!.contains(r'\ce{')) {
        nextSpecialIndex = nextInlineMath.start;
      }
      
      // Extract text before next special content
      String textPart = remaining.substring(0, nextSpecialIndex);
      if (textPart.isNotEmpty) {
        widgets.add(_buildHtmlFromText(context, textPart));
      }
      
      remaining = remaining.substring(nextSpecialIndex);
      
      // Safety break to prevent infinite loops
      if (nextSpecialIndex == 0 && remaining.isNotEmpty) {
        // If we can't parse something, add it as text and move on
        widgets.add(_buildHtmlFromText(context, remaining.substring(0, 1)));
        remaining = remaining.substring(1);
      }
    }
    
    return widgets;
  }

  Widget _buildHtmlContent(BuildContext context) {
    final htmlContent = md.markdownToHtml(content);
    
    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        ),
        "p": Style(
          margin: Margins.only(bottom: 8),
        ),
        "code": Style(
          backgroundColor: Theme.of(context).cardColor,
          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
          fontFamily: 'Courier',
        ),
        "pre": Style(
          backgroundColor: Theme.of(context).cardColor,
          padding: HtmlPaddings.all(12),
          margin: Margins.symmetric(vertical: 8),
        ),
        "blockquote": Style(
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
          padding: HtmlPaddings.only(left: 16),
          margin: Margins.symmetric(vertical: 8),
        ),
      },
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _buildHtmlFromText(BuildContext context, String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    
    final htmlContent = md.markdownToHtml(text);
    
    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
        ),
        "p": Style(
          margin: Margins.zero,
        ),
      },
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
           ChemJAXUtils.containsChemicalFormula(text);
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