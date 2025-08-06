import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'theme.dart';

class HtmlMarkdownWidget extends StatefulWidget {
  final String data;
  final bool selectable;

  const HtmlMarkdownWidget({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  State<HtmlMarkdownWidget> createState() => _HtmlMarkdownWidgetState();
}

class _HtmlMarkdownWidgetState extends State<HtmlMarkdownWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  double _height = 200; // Initial height

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _updateHeight();
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterHeight',
        onMessageReceived: (JavaScriptMessage message) {
          final height = double.tryParse(message.message) ?? 200;
          if (mounted) {
            setState(() {
              _height = height;
              _isLoading = false;
            });
          }
        },
      )
      ..loadHtmlString(_generateHtml());
  }

  @override
  void didUpdateWidget(HtmlMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      setState(() {
        _isLoading = true;
      });
      _controller.loadHtmlString(_generateHtml());
    }
  }

  String _generateHtml() {
    final isDark = !isLightTheme(context);
    final escapedMarkdown = widget.data
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n');

    final htmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <!-- Marked.js for Markdown parsing -->
    <script src="https://cdn.jsdelivr.net/npm/marked@11.1.1/marked.min.js"></script>
    
    <!-- Highlight.js for syntax highlighting -->
    <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/${isDark ? 'github-dark' : 'github'}.min.css">
    
    <!-- MathJax for LaTeX -->
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 16px;
            background-color: ${isDark ? '#1a202c' : '#ffffff'};
            color: ${isDark ? '#e2e8f0' : '#1a202c'};
            line-height: 1.6;
            word-wrap: break-word;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2em; }
        h2 { font-size: 1.5em; }
        h3 { font-size: 1.25em; }
        
        p {
            margin-bottom: 16px;
        }
        
        ul, ol {
            margin-bottom: 16px;
            padding-left: 30px;
        }
        
        li {
            margin-bottom: 4px;
        }
        
        blockquote {
            margin: 16px 0;
            padding: 0 16px;
            border-left: 4px solid ${isDark ? '#4a5568' : '#e2e8f0'};
            color: ${isDark ? '#a0aec0' : '#4a5568'};
        }
        
        code {
            background-color: ${isDark ? '#2d3748' : '#f7fafc'};
            padding: 2px 4px;
            border-radius: 3px;
            font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace;
            font-size: 85%;
        }
        
        pre {
            background-color: ${isDark ? '#2d3748' : '#f7fafc'};
            padding: 16px;
            border-radius: 6px;
            overflow-x: auto;
            margin: 16px 0;
        }
        
        pre code {
            background-color: transparent;
            padding: 0;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 16px 0;
        }
        
        th, td {
            border: 1px solid ${isDark ? '#4a5568' : '#e2e8f0'};
            padding: 8px 12px;
            text-align: left;
        }
        
        th {
            background-color: ${isDark ? '#2d3748' : '#f7fafc'};
            font-weight: 600;
        }
        
        a {
            color: ${isDark ? '#63b3ed' : '#3182ce'};
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
            margin: 8px 0;
        }
        
        hr {
            border: none;
            height: 2px;
            background-color: ${isDark ? '#4a5568' : '#e2e8f0'};
            margin: 24px 0;
        }
        
        /* MathJax styling */
        .MathJax {
            font-size: 1.1em !important;
        }
        
        mjx-container[display="block"] {
            margin: 16px 0 !important;
        }
        
        /* Make content selectable if needed */
        ${widget.selectable ? '''
        * {
            -webkit-user-select: text;
            -moz-user-select: text;
            -ms-user-select: text;
            user-select: text;
        }
        ''' : ''}
    </style>
</head>
<body>
    <div id="content"></div>
    
    <script>
        // Configure MathJax
        window.MathJax = {
            tex: {
                inlineMath: [['DOLLAR', 'DOLLAR'], ['\\\\(', '\\\\)']],
                displayMath: [['DOLLARDOLLAR', 'DOLLARDOLLAR'], ['\\\\[', '\\\\]']],
                processEscapes: true,
                processEnvironments: true
            },
            options: {
                ignoreHtmlClass: 'tex2jax_ignore',
                processHtmlClass: 'tex2jax_process'
            }
        };
        
        // Configure Marked.js
        marked.setOptions({
            highlight: function(code, lang) {
                if (lang && hljs.getLanguage(lang)) {
                    try {
                        return hljs.highlight(code, {language: lang}).value;
                    } catch (err) {}
                }
                return hljs.highlightAuto(code).value;
            },
            breaks: true,
            gfm: true
        });
        
                 function renderContent() {
             const markdown = `$escapedMarkdown`;
             const content = document.getElementById('content');
            
            // Convert markdown to HTML
            content.innerHTML = marked.parse(markdown);
            
            // Process LaTeX
            if (window.MathJax && window.MathJax.typesetPromise) {
                MathJax.typesetPromise([content]).then(() => {
                    updateHeight();
                }).catch((err) => {
                    console.error('MathJax error:', err);
                    updateHeight();
                });
            } else {
                updateHeight();
            }
        }
        
        function updateHeight() {
            const body = document.body;
            const height = Math.max(
                body.scrollHeight,
                body.offsetHeight,
                document.documentElement.clientHeight,
                document.documentElement.scrollHeight,
                document.documentElement.offsetHeight
            );
            
            // Send height to Flutter
            if (window.FlutterHeight && window.FlutterHeight.postMessage) {
                window.FlutterHeight.postMessage(height.toString());
            }
        }
        
        // Wait for all scripts to load
        document.addEventListener('DOMContentLoaded', function() {
            // Small delay to ensure MathJax is ready
            setTimeout(renderContent, 100);
        });
        
        // Fallback if DOMContentLoaded already fired
        if (document.readyState === 'loading') {
            // Do nothing, wait for DOMContentLoaded
        } else {
            setTimeout(renderContent, 100);
        }
    </script>
 </body>
 </html>
     ''';
     
     // Replace placeholders with actual dollar signs after string interpolation
     return htmlTemplate
         .replaceAll('DOLLARDOLLAR', '\$\$')
         .replaceAll('DOLLAR', '\$');
   }

  void _updateHeight() {
    _controller.runJavaScript('updateHeight();');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _isLoading ? 100 : _height,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Rendering...', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}