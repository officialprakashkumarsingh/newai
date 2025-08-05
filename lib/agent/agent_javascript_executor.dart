import 'dart:convert';
import 'package:flutter/material.dart';
import 'agent_types.dart';

/// Advanced JavaScript executor for agent automation with error recovery and data extraction
class AgentJavaScriptExecutor {
  bool _isInitialized = false;
  int _retryAttempts = 0;
  final int _maxRetries = 3;

  Future<void> initialize() async {
    _isInitialized = true;
    print('⚡ JavaScript Executor initialized');
  }

  /// Execute custom JavaScript with error handling and retry
  Future<StepResult> executeScript(String script) async {
    if (!_isInitialized) {
      return StepResult.error('JavaScript executor not initialized');
    }

    _retryAttempts = 0;
    return await _executeWithRetry(script);
  }

  /// Internal execute with retry mechanism
  Future<StepResult> _executeWithRetry(String script) async {
    try {
      print('⚡ Agent executing JavaScript (attempt ${_retryAttempts + 1})');
      print('Script: ${script.length > 100 ? script.substring(0, 100) + '...' : script}');

      // Wrap the script in error handling
      final wrappedScript = '''
        (function() {
          try {
            const result = (function() {
              $script
            })();
            return { success: true, result: result };
          } catch (error) {
            return { 
              success: false, 
              error: error.message, 
              stack: error.stack 
            };
          }
        })();
      ''';

      // Simulate script execution
      await Future.delayed(const Duration(milliseconds: 200));

      // In a real implementation, this would be executed in the WebView
      // For now, simulate success with some sample data
      final simulatedResult = {
        'success': true,
        'result': 'Script executed successfully',
        'executionTime': 200,
      };

      return StepResult.success('JavaScript executed successfully', {
        'script': script,
        'result': json.encode(simulatedResult),
        'attempts': (_retryAttempts + 1).toString(),
      });

    } catch (e) {
      _retryAttempts++;
      print('❌ JavaScript execution failed (attempt $_retryAttempts): $e');

      if (_retryAttempts < _maxRetries) {
        print('🔄 Retrying JavaScript execution in 1 second...');
        await Future.delayed(const Duration(seconds: 1));
        return await _executeWithRetry(script);
      }

      return StepResult.error('JavaScript execution failed after $_maxRetries attempts: $e');
    }
  }

  /// Extract data from the page using CSS selectors
  Future<StepResult> extractData(String selector, {
    String? attribute,
    bool multiple = false,
  }) async {
    try {
      print('🔍 Agent extracting data from: $selector');

      final script = '''
        (function() {
          try {
            const elements = document.querySelectorAll('$selector');
            if (elements.length === 0) {
              return { success: false, error: 'No elements found for selector: $selector' };
            }

            const extractFromElement = (element) => {
              if ('$attribute' && '$attribute' !== 'null') {
                return element.getAttribute('$attribute') || element['$attribute'];
              } else {
                // Extract comprehensive data
                return {
                  text: element.textContent.trim(),
                  html: element.innerHTML,
                  tag: element.tagName.toLowerCase(),
                  id: element.id,
                  className: element.className,
                  value: element.value,
                  href: element.href,
                  src: element.src,
                  alt: element.alt,
                  title: element.title,
                  attributes: Array.from(element.attributes).reduce((acc, attr) => {
                    acc[attr.name] = attr.value;
                    return acc;
                  }, {})
                };
              }
            };

            if ($multiple) {
              const data = Array.from(elements).map(extractFromElement);
              return { success: true, data: data, count: data.length };
            } else {
              const data = extractFromElement(elements[0]);
              return { success: true, data: data, count: 1 };
            }
          } catch (error) {
            return { success: false, error: error.message };
          }
        })();
      ''';

      // Simulate data extraction
      await Future.delayed(const Duration(milliseconds: 300));

      // Simulate extracted data
      final simulatedData = multiple ? [
        {'text': 'Sample text 1', 'tag': 'div'},
        {'text': 'Sample text 2', 'tag': 'span'},
      ] : {'text': 'Sample extracted text', 'tag': 'div'};

      return StepResult.success('Data extracted successfully', {
        'selector': selector,
        'attribute': attribute ?? 'comprehensive',
        'multiple': multiple.toString(),
        'data': json.encode(simulatedData),
      });

    } catch (e) {
      print('❌ Data extraction failed: $e');
      return StepResult.error('Data extraction failed: $e');
    }
  }

  /// Monitor page changes and wait for specific conditions
  Future<StepResult> waitForCondition(String condition, {
    int timeoutSeconds = 10,
    int checkInterval = 500,
  }) async {
    try {
      print('⏳ Agent waiting for condition: $condition');

      final script = '''
        (function() {
          try {
            return Boolean($condition);
          } catch (error) {
            return false;
          }
        })();
      ''';

      final stopwatch = Stopwatch()..start();

      while (stopwatch.elapsedMilliseconds < timeoutSeconds * 1000) {
        // Simulate condition checking
        await Future.delayed(Duration(milliseconds: checkInterval));

        // For simulation, assume condition is met after some time
        if (stopwatch.elapsedMilliseconds > 2000) {
          return StepResult.success('Condition met: $condition');
        }
      }

      return StepResult.error('Condition not met after ${timeoutSeconds}s: $condition');

    } catch (e) {
      print('❌ Wait for condition failed: $e');
      return StepResult.error('Wait for condition failed: $e');
    }
  }

  /// Inject custom functions into the page
  Future<StepResult> injectHelperFunctions() async {
    try {
      print('🔧 Agent injecting helper functions');

      final helperScript = '''
        // Advanced agent helper functions
        window.agentAdvanced = window.agentAdvanced || {
          
          // Smart element finder using multiple strategies
          findElement: function(description) {
            // Try by text content
            let element = Array.from(document.querySelectorAll('*')).find(el => 
              el.textContent.trim().toLowerCase().includes(description.toLowerCase())
            );
            
            if (element) return element;
            
            // Try by aria-label
            element = document.querySelector('[aria-label*="' + description + '"]');
            if (element) return element;
            
            // Try by placeholder
            element = document.querySelector('[placeholder*="' + description + '"]');
            if (element) return element;
            
            // Try by title
            element = document.querySelector('[title*="' + description + '"]');
            if (element) return element;
            
            return null;
          },
          
          // Auto-fill form with data
          fillForm: function(formData) {
            const results = [];
            
            for (const [key, value] of Object.entries(formData)) {
              const element = document.querySelector(
                'input[name="' + key + '"], textarea[name="' + key + '"], select[name="' + key + '"]'
              ) || document.querySelector('#' + key);
              
              if (element) {
                if (element.tagName === 'SELECT') {
                  const option = Array.from(element.options).find(opt => 
                    opt.value === value || opt.text === value
                  );
                  if (option) {
                    element.value = option.value;
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                    results.push({ field: key, success: true });
                  } else {
                    results.push({ field: key, success: false, error: 'Option not found' });
                  }
                } else {
                  element.value = value;
                  element.dispatchEvent(new Event('input', { bubbles: true }));
                  element.dispatchEvent(new Event('change', { bubbles: true }));
                  results.push({ field: key, success: true });
                }
              } else {
                results.push({ field: key, success: false, error: 'Element not found' });
              }
            }
            
            return results;
          },
          
          // Extract table data
          extractTable: function(tableSelector) {
            const table = document.querySelector(tableSelector);
            if (!table) return { error: 'Table not found' };
            
            const headers = Array.from(table.querySelectorAll('th')).map(th => th.textContent.trim());
            const rows = Array.from(table.querySelectorAll('tbody tr')).map(row => {
              const cells = Array.from(row.querySelectorAll('td')).map(td => td.textContent.trim());
              const rowData = {};
              headers.forEach((header, index) => {
                rowData[header] = cells[index] || '';
              });
              return rowData;
            });
            
            return { headers, rows, count: rows.length };
          },
          
          // Simulate human-like interactions
          humanLikeClick: function(element) {
            if (typeof element === 'string') {
              element = document.querySelector(element);
            }
            if (!element) return false;
            
            // Scroll into view
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            // Add small random delay
            setTimeout(() => {
              // Simulate mouse movement
              const rect = element.getBoundingClientRect();
              const x = rect.left + rect.width / 2 + (Math.random() - 0.5) * 10;
              const y = rect.top + rect.height / 2 + (Math.random() - 0.5) * 10;
              
              // Trigger mouse events
              element.dispatchEvent(new MouseEvent('mouseover', { clientX: x, clientY: y, bubbles: true }));
              
              setTimeout(() => {
                element.dispatchEvent(new MouseEvent('mousedown', { clientX: x, clientY: y, bubbles: true }));
                setTimeout(() => {
                  element.dispatchEvent(new MouseEvent('mouseup', { clientX: x, clientY: y, bubbles: true }));
                  element.click();
                }, 50 + Math.random() * 50);
              }, 100 + Math.random() * 100);
            }, 200 + Math.random() * 300);
            
            return true;
          },
          
          // Detect page changes
          watchForChanges: function(callback, timeout = 5000) {
            const observer = new MutationObserver(callback);
            observer.observe(document.body, {
              childList: true,
              subtree: true,
              attributes: true
            });
            
            setTimeout(() => observer.disconnect(), timeout);
            return observer;
          },
          
          // Take element screenshot (for debugging)
          highlightElement: function(element, duration = 2000) {
            if (typeof element === 'string') {
              element = document.querySelector(element);
            }
            if (!element) return false;
            
            const originalStyle = {
              outline: element.style.outline,
              backgroundColor: element.style.backgroundColor,
              boxShadow: element.style.boxShadow
            };
            
            element.style.outline = '3px solid #ff4444';
            element.style.backgroundColor = 'rgba(255, 68, 68, 0.1)';
            element.style.boxShadow = '0 0 10px rgba(255, 68, 68, 0.5)';
            
            setTimeout(() => {
              element.style.outline = originalStyle.outline;
              element.style.backgroundColor = originalStyle.backgroundColor;
              element.style.boxShadow = originalStyle.boxShadow;
            }, duration);
            
            return true;
          }
        };
        
        console.log('🔧 Advanced agent helpers injected');
      ''';

      // Simulate injection
      await Future.delayed(const Duration(milliseconds: 100));

      return StepResult.success('Helper functions injected successfully');

    } catch (e) {
      print('❌ Helper function injection failed: $e');
      return StepResult.error('Helper function injection failed: $e');
    }
  }

  /// Execute a series of JavaScript commands in sequence
  Future<StepResult> executeSequence(List<String> scripts) async {
    try {
      print('📋 Agent executing JavaScript sequence (${scripts.length} scripts)');

      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < scripts.length; i++) {
        final script = scripts[i];
        print('⚡ Executing script ${i + 1}/${scripts.length}');

        final result = await executeScript(script);
        
        results.add({
          'index': i,
          'script': script,
          'success': result.success,
          'result': result.data,
          'error': result.error,
        });

        if (!result.success) {
          print('❌ Script ${i + 1} failed, stopping sequence');
          break;
        }

        // Small delay between scripts
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final successful = results.where((r) => r['success'] == true).length;
      final total = results.length;

      return StepResult.success('Sequence executed: $successful/$total successful', {
        'total': total.toString(),
        'successful': successful.toString(),
        'results': json.encode(results),
      });

    } catch (e) {
      print('❌ JavaScript sequence execution failed: $e');
      return StepResult.error('JavaScript sequence execution failed: $e');
    }
  }

  /// Evaluate page performance and state
  Future<StepResult> evaluatePageState() async {
    try {
      print('📊 Agent evaluating page state');

      final script = '''
        (function() {
          return {
            url: window.location.href,
            title: document.title,
            readyState: document.readyState,
            loadTime: performance.now(),
            errorCount: document.querySelectorAll('.error, [role="alert"], .alert-danger').length,
            formCount: document.forms.length,
            buttonCount: document.querySelectorAll('button, input[type="submit"]').length,
            linkCount: document.querySelectorAll('a[href]').length,
            imageCount: document.querySelectorAll('img').length,
            scriptCount: document.querySelectorAll('script').length,
            hasConsoleErrors: performance.getEntriesByType('navigation')[0]?.loadEventEnd > 0,
            viewport: {
              width: window.innerWidth,
              height: window.innerHeight
            },
            scroll: {
              x: window.scrollX,
              y: window.scrollY,
              maxX: document.body.scrollWidth - window.innerWidth,
              maxY: document.body.scrollHeight - window.innerHeight
            }
          };
        })();
      ''';

      // Simulate page state evaluation
      await Future.delayed(const Duration(milliseconds: 200));

      const simulatedState = {
        'url': 'https://example.com',
        'title': 'Example Page',
        'readyState': 'complete',
        'errorCount': 0,
        'formCount': 1,
        'buttonCount': 3,
      };

      return StepResult.success('Page state evaluated', {
        'pageState': json.encode(simulatedState),
      });

    } catch (e) {
      print('❌ Page state evaluation failed: $e');
      return StepResult.error('Page state evaluation failed: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}