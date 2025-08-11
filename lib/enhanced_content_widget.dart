import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_tex/flutter_tex.dart';
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
    // Debug: Log the content being processed
    print('🔍 ENHANCED WIDGET: Processing content: "${content.substring(0, content.length > 100 ? 100 : content.length)}..."');
    
    // Check if content contains chemical formulas or LaTeX
    final hasChemical = _containsChemicalFormulas(content);
    final hasLatex = _containsLatex(content);
    
    print('🔍 ENHANCED WIDGET: Has chemical formulas: $hasChemical');
    print('🔍 ENHANCED WIDGET: Has LaTeX: $hasLatex');
    
    if (hasChemical || hasLatex) {
      print('🔍 ENHANCED WIDGET: Using enhanced content rendering');
      return _buildEnhancedContent(context);
    }
    
    // For simple content, use HTML widget with markdown conversion
    print('🔍 ENHANCED WIDGET: Using simple HTML rendering');
    return _buildHtmlContent(context);
  }

  bool _containsChemicalFormulas(String text) {
    // Check for ChemJAX patterns (try both single and double backslash)
    final pattern1 = RegExp(r'\$\\ce\{[^}]+\}\$').hasMatch(text);  // Double backslash: $\\ce{...}$
    final pattern2 = RegExp(r'\$\\\\ce\{[^}]+\}\$').hasMatch(text); // Escaped backslash: $\\ce{...}$  
    final pattern3 = RegExp(r'\\ce\{[^}]+\}').hasMatch(text);       // Just \ce{...}
    final pattern4 = ChemJAXUtils.containsChemicalFormula(text);
    
    print('🔍 CHEMICAL CHECK: Pattern \$\\ce{...}\$: $pattern1');
    print('🔍 CHEMICAL CHECK: Pattern \$\\\\ce{...}\$: $pattern2');
    print('🔍 CHEMICAL CHECK: Pattern \\ce{...}: $pattern3');
    print('🔍 CHEMICAL CHECK: ChemJAXUtils check: $pattern4');
    
    return pattern1 || pattern2 || pattern3 || pattern4;
  }

  bool _containsLatex(String text) {
    // Check for LaTeX math patterns
    final displayMath = RegExp(r'\$\$[^$]+\$\$').hasMatch(text);
    final inlineMath = RegExp(r'\$[^$]+\$').hasMatch(text);
    final latexEnv = RegExp(r'\\begin\{[^}]+\}').hasMatch(text);
    final latexCmd = RegExp(r'\\[a-zA-Z]+\{').hasMatch(text);
    
    print('🔍 LATEX CHECK: Display math \$\$...\$\$: $displayMath');
    print('🔍 LATEX CHECK: Inline math \$...\$: $inlineMath');
    print('🔍 LATEX CHECK: LaTeX environments: $latexEnv');
    print('🔍 LATEX CHECK: LaTeX commands: $latexCmd');
    
    return displayMath || inlineMath || latexEnv || latexCmd;
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
    
    print('🔍 PARSING: Starting to parse content: "${remaining.substring(0, remaining.length > 100 ? 100 : remaining.length)}..."');
    
    while (remaining.isNotEmpty) {
      // Look for ChemJAX formulas first (highest priority) - try multiple patterns
      RegExpMatch? chemjaxMatch;
      String? matchedFormula;
      
      // Pattern 1: $\ce{...}$ (single backslash)
      chemjaxMatch = RegExp(r'\$\\ce\{([^}]+)\}\$').firstMatch(remaining);
      if (chemjaxMatch != null && chemjaxMatch.start == 0) {
        matchedFormula = chemjaxMatch.group(0)!;
      }
      
      // Pattern 2: $\\ce{...}$ (double backslash) 
      if (chemjaxMatch == null) {
        chemjaxMatch = RegExp(r'\$\\\\ce\{([^}]+)\}\$').firstMatch(remaining);
        if (chemjaxMatch != null && chemjaxMatch.start == 0) {
          matchedFormula = chemjaxMatch.group(0)!;
        }
      }
      
      if (chemjaxMatch != null && chemjaxMatch.start == 0 && matchedFormula != null) {
        print('🔍 PARSING: Found ChemJAX formula: $matchedFormula');
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
        print('🔍 PARSING: Found display math: ${displayMathMatch.group(0)}');
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: TeXView(
              child: TeXViewDocument(r'$$' + displayMathMatch.group(1)! + r'$$'),
              style: TeXViewStyle(
                elevation: 0,
                backgroundColor: Colors.transparent,
                contentColor: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                margin: const TeXViewMargin.all(0),
                padding: const TeXViewPadding.all(0),
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
        print('🔍 PARSING: Found inline math: ${inlineMathMatch.group(0)}');
        widgets.add(TeXView(
          child: TeXViewDocument(r'$' + inlineMathMatch.group(1)! + r'$'),
          style: TeXViewStyle(
            elevation: 0,
            backgroundColor: Colors.transparent,
            contentColor: isUserMessage ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            margin: const TeXViewMargin.all(0),
            padding: const TeXViewPadding.all(0),
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