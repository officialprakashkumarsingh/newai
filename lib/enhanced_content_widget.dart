import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'native_formula_widget.dart';

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
    // Check if content contains formulas
    if (_containsFormulas(content)) {
      return _buildEnhancedContent(context);
    }
    
    // For simple content, use HTML widget with markdown conversion
    return _buildHtmlContent(context);
  }

  bool _containsFormulas(String text) {
    // Use native formula detection
    return NativeFormulaUtils.containsFormula(text);
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
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: NativeFormulaWidget(
            formula: displayMathMatch.group(0)!,
            textStyle: TextStyle(
              fontSize: 18,
              color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ));
        remaining = remaining.substring(displayMathMatch.end);
        continue;
      }
      
      // Look for inline math/chemistry ($...$)
      final inlineMathMatch = RegExp(r'\$([^$\n]+)\$').firstMatch(remaining);
      if (inlineMathMatch != null && inlineMathMatch.start == 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: NativeFormulaWidget(
            formula: inlineMathMatch.group(0)!,
            textStyle: TextStyle(
              fontSize: 16,
              color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ));
        remaining = remaining.substring(inlineMathMatch.end);
        continue;
      }
      
      // Look for chemical formulas without $ symbols
      final chemMatch = RegExp(r'\\ce\{([^}]+)\}').firstMatch(remaining);
      if (chemMatch != null && chemMatch.start == 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: NativeFormulaWidget(
            formula: chemMatch.group(0)!,
            textStyle: TextStyle(
              fontSize: 16,
              color: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
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
          widgets.add(_buildHtmlFromText(context, textContent));
        }
        remaining = remaining.substring(nextFormulaIndex);
      } else {
        // No more formulas, add remaining text
        if (remaining.trim().isNotEmpty) {
          widgets.add(_buildHtmlFromText(context, remaining));
        }
        break;
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