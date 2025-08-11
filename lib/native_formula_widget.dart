import 'package:flutter/material.dart';

class NativeFormulaWidget extends StatelessWidget {
  final String formula;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const NativeFormulaWidget({
    super.key,
    required this.formula,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge!;
    
    // Remove $ symbols and clean the formula
    String cleanFormula = formula
        .replaceAll(r'$$', '')
        .replaceAll(r'$', '')
        .trim();
    
    // Handle chemical formulas
    if (cleanFormula.contains(r'\ce{') || _isChemicalFormula(cleanFormula)) {
      return _buildChemicalFormula(cleanFormula, defaultStyle, context);
    }
    
    // Handle mathematical formulas
    return _buildMathFormula(cleanFormula, defaultStyle, context);
  }

  bool _isChemicalFormula(String formula) {
    // Simple heuristics to detect chemical formulas
    final chemicalPatterns = [
      RegExp(r'[A-Z][a-z]?\d*'), // Element symbols with numbers
      RegExp(r'H2O|CO2|NaCl|CH4|NH3|SO4|NO3|PO4'), // Common compounds
      RegExp(r'\b[A-Z][a-z]?(\d+)?(\+|\-|\d+\+|\d+\-)?'), // Ions
    ];
    
    return chemicalPatterns.any((pattern) => pattern.hasMatch(formula));
  }

  Widget _buildChemicalFormula(String formula, TextStyle baseStyle, BuildContext context) {
    // Clean up chemical notation
    String cleanFormula = formula
        .replaceAll(r'\ce{', '')
        .replaceAll(r'}', '')
        .trim();
    
    List<TextSpan> spans = [];
    RegExp chemPattern = RegExp(r'([A-Z][a-z]?)(\d+)?(\+|\-|\d+\+|\d+\-)?');
    
    int lastEnd = 0;
    for (Match match in chemPattern.allMatches(cleanFormula)) {
      // Add any text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: cleanFormula.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }
      
      String element = match.group(1) ?? '';
      String number = match.group(2) ?? '';
      String charge = match.group(3) ?? '';
      
      // Add element symbol
      spans.add(TextSpan(
        text: element,
        style: baseStyle.copyWith(fontWeight: FontWeight.w500),
      ));
      
      // Add subscript number
      if (number.isNotEmpty) {
        spans.add(TextSpan(
          text: number,
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 16) * 0.7,
            fontFeatures: [const FontFeature.subscripts()],
          ),
        ));
      }
      
      // Add superscript charge
      if (charge.isNotEmpty) {
        spans.add(TextSpan(
          text: charge,
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 16) * 0.7,
            fontFeatures: [const FontFeature.superscripts()],
          ),
        ));
      }
      
      lastEnd = match.end;
    }
    
    // Add any remaining text
    if (lastEnd < cleanFormula.length) {
      spans.add(TextSpan(
        text: cleanFormula.substring(lastEnd),
        style: baseStyle,
      ));
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _buildMathFormula(String formula, TextStyle baseStyle, BuildContext context) {
    // Simple math formula rendering
    List<TextSpan> spans = [];
    
    // Handle common math patterns
    String processedFormula = formula;
    
    // Handle fractions \frac{a}{b}
    processedFormula = processedFormula.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (match) => '(${match.group(1)})/(${match.group(2)})',
    );
    
    // Handle square roots \sqrt{x}
    processedFormula = processedFormula.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]+)\}'),
      (match) => '√(${match.group(1)})',
    );
    
    // Handle superscripts x^2
    processedFormula = processedFormula.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9]+)\^(\d+)'),
      (match) => '${match.group(1)}${_toSuperscript(match.group(2)!)}',
    );
    
    // Handle subscripts x_2
    processedFormula = processedFormula.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9]+)_(\d+)'),
      (match) => '${match.group(1)}${_toSubscript(match.group(2)!)}',
    );
    
    // Handle common symbols
    processedFormula = processedFormula
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\delta', 'δ')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\mu', 'μ')
        .replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\omega', 'ω')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\sum', '∑')
        .replaceAll(r'\int', '∫')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\approx', '≈');
    
    spans.add(TextSpan(
      text: processedFormula,
      style: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w400,
      ),
    ));
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(children: spans),
      ),
    );
  }

  String _toSuperscript(String text) {
    const superscriptMap = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
      '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
      '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
    };
    return text.split('').map((char) => superscriptMap[char] ?? char).join();
  }

  String _toSubscript(String text) {
    const subscriptMap = {
      '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄',
      '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
      '+': '₊', '-': '₋', '=': '₌', '(': '₍', ')': '₎',
    };
    return text.split('').map((char) => subscriptMap[char] ?? char).join();
  }
}

// Utility class for native formula handling
class NativeFormulaUtils {
  static bool containsFormula(String text) {
    return RegExp(r'\$\$[^$]+\$\$').hasMatch(text) ||  // Display math
           RegExp(r'\$[^$\n]+\$').hasMatch(text) ||     // Inline math
           RegExp(r'\\ce\{[^}]+\}').hasMatch(text) ||   // Chemistry
           _hasChemicalElements(text) ||
           _hasMathSymbols(text);
  }
  
  static bool _hasChemicalElements(String text) {
    return RegExp(r'\b[A-Z][a-z]?\d*\b').hasMatch(text) &&
           (text.contains('H2O') || text.contains('CO2') || 
            text.contains('NaCl') || text.contains('CH4') ||
            RegExp(r'[A-Z][a-z]?\d+').hasMatch(text));
  }
  
  static bool _hasMathSymbols(String text) {
    return text.contains('^') || text.contains('_') ||
           text.contains(r'\frac') || text.contains(r'\sqrt') ||
           text.contains(r'\alpha') || text.contains(r'\beta') ||
           text.contains('∑') || text.contains('∫') ||
           text.contains('π') || text.contains('±');
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