import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'agent_types.dart';

/// Advanced web view for agent automation with visual feedback and error recovery
class AgentWebView {
  late WebViewController _controller;
  GlobalKey _webViewKey = GlobalKey();
  bool _isInitialized = false;
  String _currentUrl = '';
  String _lastError = '';
  String _pageTitle = '';
  double _loadingProgress = 0.0;
  bool _isLoading = false;

  // Visual feedback
  final ValueNotifier<String> _statusNotifier = ValueNotifier<String>('Ready');
  final ValueNotifier<bool> _isExecutingNotifier = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 AhamAI-Agent/1.0')
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              _loadingProgress = progress / 100.0;
              _statusNotifier.value = 'Loading... ${progress}%';
            },
            onPageStarted: (String url) {
              _isLoading = true;
              _currentUrl = url;
              _statusNotifier.value = 'Navigating to $url';
              print('🌐 Agent navigating to: $url');
            },
            onPageFinished: (String url) {
              _isLoading = false;
              _currentUrl = url;
              _statusNotifier.value = 'Page loaded: $url';
              print('✅ Agent page loaded: $url');
              _injectAgentHelpers();
            },
            onWebResourceError: (WebResourceError error) {
              _lastError = error.description;
              _statusNotifier.value = 'Error: ${error.description}';
              print('❌ Agent web error: ${error.description}');
            },
          ),
        );

      // Inject agent helper scripts
      await _injectAgentHelpers();
      
      _isInitialized = true;
      _statusNotifier.value = 'Agent WebView initialized';
      print('🤖 Agent WebView initialized');
    } catch (e) {
      print('❌ Agent WebView initialization failed: $e');
      rethrow;
    }
  }

  /// Navigate to a URL with retry and error handling
  Future<StepResult> navigate(String url) async {
    if (!_isInitialized) {
      return StepResult.error('WebView not initialized');
    }

    try {
      _isExecutingNotifier.value = true;
      _statusNotifier.value = 'Navigating to $url';

      print('🌐 Agent navigating to: $url');
      await _controller.loadRequest(Uri.parse(url));

      // Wait for page to load with timeout
      int attempts = 0;
      while (_isLoading && attempts < 30) { // 30 seconds timeout
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }

      if (_isLoading) {
        _isExecutingNotifier.value = false;
        return StepResult.error('Navigation timeout after 30 seconds');
      }

      if (_lastError.isNotEmpty) {
        final error = _lastError;
        _lastError = '';
        _isExecutingNotifier.value = false;
        return StepResult.error('Navigation failed: $error');
      }

      _isExecutingNotifier.value = false;
      _statusNotifier.value = 'Navigation completed';
      
      return StepResult.success('Successfully navigated to $url', {
        'url': _currentUrl,
        'title': _pageTitle,
      });

    } catch (e) {
      _isExecutingNotifier.value = false;
      _statusNotifier.value = 'Navigation failed';
      print('❌ Navigation failed: $e');
      return StepResult.error('Navigation failed: $e');
    }
  }

  /// Take a screenshot for visual verification
  Future<StepResult> takeScreenshot() async {
    try {
      _isExecutingNotifier.value = true;
      _statusNotifier.value = 'Taking screenshot...';

      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = _webViewKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _isExecutingNotifier.value = false;
        return StepResult.error('Could not find render boundary for screenshot');
      }

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _isExecutingNotifier.value = false;
        return StepResult.error('Failed to convert screenshot to bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String base64Image = base64Encode(pngBytes);

      _isExecutingNotifier.value = false;
      _statusNotifier.value = 'Screenshot captured';
      
      print('📸 Agent screenshot captured (${pngBytes.length} bytes)');

      return StepResult.success('Screenshot captured successfully', {
        'screenshot': base64Image,
        'size': pngBytes.length.toString(),
        'url': _currentUrl,
      });

    } catch (e) {
      _isExecutingNotifier.value = false;
      _statusNotifier.value = 'Screenshot failed';
      print('❌ Screenshot failed: $e');
      return StepResult.error('Screenshot failed: $e');
    }
  }

  /// Get page information for AI analysis
  Future<StepResult> getPageInfo() async {
    try {
      _statusNotifier.value = 'Analyzing page...';

      final String script = '''
        (function() {
          return {
            title: document.title,
            url: window.location.href,
            forms: Array.from(document.forms).map(form => ({
              id: form.id,
              action: form.action,
              method: form.method,
              elements: Array.from(form.elements).length
            })),
            buttons: Array.from(document.querySelectorAll('button, input[type="submit"], input[type="button"]')).map(btn => ({
              text: btn.textContent || btn.value,
              id: btn.id,
              class: btn.className,
              type: btn.type
            })),
            links: Array.from(document.querySelectorAll('a[href]')).slice(0, 10).map(link => ({
              text: link.textContent.trim(),
              href: link.href,
              id: link.id
            })),
            inputs: Array.from(document.querySelectorAll('input, textarea, select')).map(input => ({
              type: input.type,
              id: input.id,
              name: input.name,
              placeholder: input.placeholder,
              required: input.required
            })),
            errors: Array.from(document.querySelectorAll('.error, .alert-danger, [role="alert"]')).map(error => error.textContent.trim()),
            headings: Array.from(document.querySelectorAll('h1, h2, h3')).slice(0, 5).map(h => h.textContent.trim())
          };
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      final pageInfo = json.decode(result.toString());

      _statusNotifier.value = 'Page analyzed';
      
      return StepResult.success('Page information extracted', {
        'pageInfo': json.encode(pageInfo),
        'url': _currentUrl,
      });

    } catch (e) {
      _statusNotifier.value = 'Page analysis failed';
      print('❌ Page analysis failed: $e');
      return StepResult.error('Page analysis failed: $e');
    }
  }

  /// Check if element exists and is visible
  Future<bool> isElementVisible(String selector) async {
    try {
      final String script = '''
        (function() {
          const element = document.querySelector('$selector');
          if (!element) return false;
          
          const rect = element.getBoundingClientRect();
          const style = window.getComputedStyle(element);
          
          return rect.width > 0 && 
                 rect.height > 0 && 
                 style.visibility !== 'hidden' && 
                 style.display !== 'none' &&
                 element.offsetParent !== null;
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(script);
      return result == true;
    } catch (e) {
      print('❌ Element visibility check failed: $e');
      return false;
    }
  }

  /// Wait for element to appear with timeout
  Future<StepResult> waitForElement(String selector, {int timeoutSeconds = 10}) async {
    _statusNotifier.value = 'Waiting for element: $selector';
    
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsedMilliseconds < timeoutSeconds * 1000) {
      if (await isElementVisible(selector)) {
        _statusNotifier.value = 'Element found: $selector';
        return StepResult.success('Element found: $selector');
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _statusNotifier.value = 'Element not found: $selector';
    return StepResult.error('Element not found after ${timeoutSeconds}s: $selector');
  }

  /// Inject helper JavaScript for better element interaction
  Future<void> _injectAgentHelpers() async {
    try {
      final String helperScript = '''
        // Agent helper functions
        window.agentHelpers = {
          // Highlight element for visual feedback
          highlightElement: function(selector) {
            const element = document.querySelector(selector);
            if (element) {
              element.style.outline = '3px solid #ff4444';
              element.style.backgroundColor = 'rgba(255, 68, 68, 0.1)';
              setTimeout(() => {
                element.style.outline = '';
                element.style.backgroundColor = '';
              }, 2000);
              return true;
            }
            return false;
          },
          
          // Smart click that handles various element types
          smartClick: function(selector) {
            const element = document.querySelector(selector);
            if (!element) return false;
            
            // Scroll into view first
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            // Highlight before clicking
            this.highlightElement(selector);
            
            // Wait a bit then click
            setTimeout(() => {
              element.click();
            }, 500);
            
            return true;
          },
          
          // Smart type that clears field first
          smartType: function(selector, text) {
            const element = document.querySelector(selector);
            if (!element) return false;
            
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            this.highlightElement(selector);
            
            setTimeout(() => {
              element.focus();
              element.value = '';
              element.value = text;
              element.dispatchEvent(new Event('input', { bubbles: true }));
              element.dispatchEvent(new Event('change', { bubbles: true }));
            }, 500);
            
            return true;
          },
          
          // Get all clickable elements
          getClickableElements: function() {
            return Array.from(document.querySelectorAll('a, button, input[type="submit"], input[type="button"], [onclick], [role="button"]'))
              .map(el => ({
                tag: el.tagName,
                text: el.textContent.trim(),
                id: el.id,
                class: el.className,
                href: el.href
              }));
          }
        };
        
        console.log('🤖 Agent helpers injected');
      ''';

      await _controller.runJavaScript(helperScript);
    } catch (e) {
      print('⚠️ Failed to inject agent helpers: $e');
    }
  }

  /// Get the web view widget with visual feedback overlay
  Widget getWidget() {
    return Stack(
      children: [
        RepaintBoundary(
          key: _webViewKey,
          child: WebViewWidget(controller: _controller),
        ),
        
        // Status overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<String>(
            valueListenable: _statusNotifier,
            builder: (context, status, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _isExecutingNotifier,
                      builder: (context, isExecuting, child) {
                        return Icon(
                          isExecuting ? Icons.sync : Icons.check_circle,
                          color: isExecuting ? Colors.orange : Colors.green,
                          size: 16,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Loading indicator
        if (_isLoading)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
      ],
    );
  }

  /// Get current page URL
  String get currentUrl => _currentUrl;

  /// Get current page title
  String get pageTitle => _pageTitle;

  /// Check if web view is loading
  bool get isLoading => _isLoading;

  /// Get status stream
  ValueNotifier<String> get statusStream => _statusNotifier;

  void dispose() {
    _statusNotifier.dispose();
    _isExecutingNotifier.dispose();
    _isInitialized = false;
  }
}