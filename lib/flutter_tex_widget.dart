import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class FlutterTexWidget extends StatelessWidget {
  final String content;
  final bool isUserMessage;
  final TextStyle? textStyle;

  const FlutterTexWidget({
    super.key,
    required this.content,
    this.isUserMessage = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge!;
    final color = isUserMessage ? Colors.white : defaultStyle.color;
    
    // Clean content and detect formula types
    String cleanContent = content.trim();
    
    // Check if it's a display math formula ($$...$$)
    if (RegExp(r'^\$\$(.+)\$\$$', dotAll: true).hasMatch(cleanContent)) {
      return _buildDisplayMath(cleanContent, color, context);
    }
    
    // Check if it's inline math ($...$) or chemistry (\ce{...})
    if (RegExp(r'^\$(.+)\$$', dotAll: true).hasMatch(cleanContent) ||
        RegExp(r'^\\ce\{.+\}$', dotAll: true).hasMatch(cleanContent)) {
      return _buildInlineMath(cleanContent, color, context);
    }
    
    // For mixed content with formulas
    if (_containsFormulas(cleanContent)) {
      return _buildMixedContent(cleanContent, color, context);
    }
    
    // Fallback to regular text
    return Text(cleanContent, style: defaultStyle);
  }

  bool _containsFormulas(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$\n]+\$').hasMatch(text) ||     // Inline math
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text);     // Chemistry
  }

  Widget _buildDisplayMath(String content, Color? color, BuildContext context) {
    // Extract math from $$...$$ or use as-is
    String mathContent = content;
    final match = RegExp(r'^\$\$(.+)\$\$$', dotAll: true).firstMatch(content);
    if (match != null) {
      mathContent = '\$\$${match.group(1)!}\$\$';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: TeXView(
        child: TeXViewDocument(mathContent),
        style: TeXViewStyle(
          textAlign: TeXViewTextAlign.center,
          fontStyle: TeXViewFontStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMath(String content, Color? color, BuildContext context) {
    // Clean up the content
    String mathContent = content;
    
    // Handle chemistry notation
    if (content.startsWith(r'\ce{') && content.endsWith('}')) {
      mathContent = '\$\\ce{${content.substring(4, content.length - 1)}}\$';
    }
    
    // Handle inline math that might not have $ symbols
    else if (!content.startsWith('\$')) {
      mathContent = '\$$content\$';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.05) ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: TeXView(
        child: TeXViewDocument(mathContent),
        style: TeXViewStyle(
          textAlign: TeXViewTextAlign.center,
          fontStyle: TeXViewFontStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildMixedContent(String content, Color? color, BuildContext context) {
    // For mixed content, use TeXView which can handle both text and formulas
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: TeXView(
        child: TeXViewDocument(content),
        style: TeXViewStyle(
          fontStyle: TeXViewFontStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// Utility class for Flutter TeX
class FlutterTexUtils {
  static bool containsFormula(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$\n]+\$').hasMatch(text) ||     // Inline math
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text) ||   // Chemistry
           _hasChemicalElements(text) ||
           _hasMathSymbols(text);
  }
  
  static bool _hasChemicalElements(String text) {
    // Common chemistry patterns
    final chemPatterns = [
      r'\bH2O\b', r'\bCO2\b', r'\bNaCl\b', r'\bCH4\b', r'\bNH3\b',
      r'\bSO4\b', r'\bNO3\b', r'\bPO4\b', r'\bOH\b', r'\bCa\+\+\b',
      r'\b[A-Z][a-z]?\d*[\+\-]*\b' // General chemical formula pattern
    ];
    
    return chemPatterns.any((pattern) => RegExp(pattern).hasMatch(text));
  }
  
  static bool _hasMathSymbols(String text) {
    return text.contains('^') || text.contains('_') ||
           text.contains(r'\frac') || text.contains(r'\sqrt') ||
           text.contains(r'\alpha') || text.contains(r'\beta') ||
           text.contains(r'\sum') || text.contains(r'\int') ||
           text.contains('π') || text.contains('±') ||
           text.contains('∞') || text.contains('≤') || text.contains('≥');
  }
  
  static List<String> extractFormulas(String text) {
    List<String> formulas = [];
    
    // Extract display math
    formulas.addAll(RegExp(r'\$\$([^$]+)\$\$').allMatches(text)
        .map((m) => m.group(0)!));
    
    // Extract inline math
    formulas.addAll(RegExp(r'\$([^$\n]+)\$').allMatches(text)
        .map((m) => m.group(0)!));
    
    // Extract chemistry
    formulas.addAll(RegExp(r'\\ce\{[^}]+\}').allMatches(text)
        .map((m) => m.group(0)!));
    
    return formulas;
  }
}