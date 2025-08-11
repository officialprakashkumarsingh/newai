import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Widget for rendering chemical formulas using ChemJAX (MathJax with mhchem)
class ChemJAXWidget extends StatefulWidget {
  final String formula;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const ChemJAXWidget({
    super.key,
    required this.formula,
    this.width,
    this.height,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  State<ChemJAXWidget> createState() => _ChemJAXWidgetState();
}

class _ChemJAXWidgetState extends State<ChemJAXWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _renderFormula();
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'Failed to load ChemJAX: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_getHtmlContent());
  }

  String _getHtmlContent() {
    final backgroundColor = widget.backgroundColor ?? 
        (Theme.of(context).brightness == Brightness.dark ? '#1A1A1A' : '#FFFFFF');
    final textColor = widget.textStyle?.color ?? 
        (Theme.of(context).brightness == Brightness.dark ? '#FFFFFF' : '#000000');
    final fontSize = widget.textStyle?.fontSize ?? 16.0;
    final fontFamily = widget.textStyle?.fontFamily ?? 'Arial, sans-serif';

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ChemJAX Formula</title>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <script>
        window.MathJax = {
            tex: {
                inlineMath: [['\\$', '\\$'], ['\\\\(', '\\\\)']],
                displayMath: [['\\$\\$', '\\$\\$'], ['\\\\[', '\\\\]']],
                packages: {'[+]': ['mhchem']}
            },
            loader: {
                load: ['[tex]/mhchem']
            },
            startup: {
                ready() {
                    console.log('MathJax is loaded and ready');
                    MathJax.startup.defaultReady();
                }
            }
        };
    </script>
    <style>
        body {
            margin: 0;
            padding: 10px;
            background-color: $backgroundColor;
            color: $textColor;
            font-family: $fontFamily;
            font-size: ${fontSize}px;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .formula-container {
            text-align: center;
            line-height: 1.2;
        }
        .mjx-container {
            display: inline-block !important;
        }
        /* Dark mode specific styles */
        .mjx-math {
            color: $textColor !important;
        }
        /* Ensure chemical formulas are properly sized */
        mjx-container[display="true"] {
            margin: 0.5em 0 !important;
        }
    </style>
</head>
<body>
    <div class="formula-container">
        <div id="formula-content"></div>
    </div>
    
    <script>
        function renderFormula(formula) {
            try {
                console.log('Rendering formula:', formula);
                const container = document.getElementById('formula-content');
                
                // Clear previous content
                container.innerHTML = '';
                
                // Create formula element
                const formulaElement = document.createElement('div');
                formulaElement.textContent = formula;
                container.appendChild(formulaElement);
                
                // Render with MathJax
                MathJax.typesetPromise([container]).then(() => {
                    console.log('Formula rendered successfully');
                    // Notify Flutter that rendering is complete
                    if (window.flutter_inappwebview) {
                        window.flutter_inappwebview.callHandler('onRenderComplete');
                    }
                }).catch((err) => {
                    console.error('MathJax rendering error:', err);
                    container.innerHTML = '<span style="color: red;">Error rendering formula</span>';
                });
            } catch (error) {
                console.error('Error in renderFormula:', error);
                document.getElementById('formula-content').innerHTML = 
                    '<span style="color: red;">Error: ' + error.message + '</span>';
            }
        }
        
        // Wait for MathJax to be ready
        MathJax.startup.promise.then(() => {
            console.log('MathJax startup complete');
            window.renderFormula = renderFormula;
        }).catch((err) => {
            console.error('MathJax startup error:', err);
        });
    </script>
</body>
</html>
''';
  }

  void _renderFormula() {
    if (widget.formula.isNotEmpty) {
      final escapedFormula = jsonEncode(widget.formula);
      _controller.runJavaScript('renderFormula($escapedFormula);');
    }
  }

  @override
  void didUpdateWidget(ChemJAXWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formula != widget.formula) {
      _renderFormula();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        width: widget.width,
        height: widget.height ?? 50,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Center(
          child: Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height ?? 50,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Utility class for common chemical formulas and reactions
class ChemJAXUtils {
  /// Common chemical formula patterns that ChemJAX can render
  static const Map<String, String> commonFormulas = {
    // Basic molecules
    'water': r'$\ce{H2O}$',
    'carbon_dioxide': r'$\ce{CO2}$',
    'methane': r'$\ce{CH4}$',
    'ammonia': r'$\ce{NH3}$',
    'sulfuric_acid': r'$\ce{H2SO4}$',
    'sodium_chloride': r'$\ce{NaCl}$',
    
    // Organic compounds
    'benzene': r'$\ce{C6H6}$',
    'ethanol': r'$\ce{C2H5OH}$',
    'glucose': r'$\ce{C6H12O6}$',
    'caffeine': r'$\ce{C8H10N4O2}$',
    
    // Reactions
    'combustion_methane': r'$\ce{CH4 + 2O2 -> CO2 + 2H2O}$',
    'acid_base': r'$\ce{HCl + NaOH -> NaCl + H2O}$',
    'photosynthesis': r'$\ce{6CO2 + 6H2O ->[light] C6H12O6 + 6O2}$',
  };

  /// Check if a string contains chemical formula patterns
  static bool containsChemicalFormula(String text) {
    // Check for mhchem patterns: \ce{}, \cf{}, chemical formulas
    final chemPatterns = [
      RegExp(r'\\ce\{[^}]+\}'),
      RegExp(r'\\cf\{[^}]+\}'),
      RegExp(r'\$\\ce\{[^}]+\}\$'),
      RegExp(r'[A-Z][a-z]?\d*(\([^)]+\)\d*)*'), // Basic chemical formula pattern
    ];
    
    return chemPatterns.any((pattern) => pattern.hasMatch(text));
  }

  /// Extract chemical formulas from text
  static List<String> extractFormulas(String text) {
    final formulas = <String>[];
    
    // Extract \ce{} patterns
    final cePattern = RegExp(r'\\ce\{([^}]+)\}');
    formulas.addAll(cePattern.allMatches(text).map((m) => m.group(0)!));
    
    // Extract $\ce{}$ patterns
    final dollarCePattern = RegExp(r'\$\\ce\{[^}]+\}\$');
    formulas.addAll(dollarCePattern.allMatches(text).map((m) => m.group(0)!));
    
    return formulas;
  }

  /// Convert simple chemical formula to mhchem format
  static String toMhchemFormat(String formula) {
    // If already in mhchem format, return as is
    if (formula.contains(r'\ce{') || formula.startsWith(r'$\ce{')) {
      return formula;
    }
    
    // Convert simple formula to mhchem format
    return r'$\ce{' + formula + r'}$';
  }
}