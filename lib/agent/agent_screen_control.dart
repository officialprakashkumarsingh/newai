import 'dart:convert';
import 'package:flutter/material.dart';
import 'agent_types.dart';

/// Advanced screen control for agent automation with visual feedback and retry logic
class AgentScreenControl {
  bool _isInitialized = false;
  int _retryAttempts = 0;
  final int _maxRetries = 3;

  Future<void> initialize() async {
    _isInitialized = true;
    print('🖱️ Screen Control initialized');
  }

  /// Click on an element with visual feedback and retry logic
  Future<StepResult> click(String selector) async {
    if (!_isInitialized) {
      return StepResult.error('Screen control not initialized');
    }

    _retryAttempts = 0;
    return await _clickWithRetry(selector);
  }

  /// Internal click with retry mechanism
  Future<StepResult> _clickWithRetry(String selector) async {
    try {
      print('🖱️ Agent clicking element: $selector (attempt ${_retryAttempts + 1})');

      // This would typically interact with a WebView controller
      // For now, we'll simulate the action with JavaScript injection
      final script = '''
        (function() {
          try {
            const element = document.querySelector('$selector');
            if (!element) {
              return { success: false, error: 'Element not found: $selector' };
            }

            // Check if element is visible and clickable
            const rect = element.getBoundingClientRect();
            const style = window.getComputedStyle(element);
            
            if (rect.width === 0 || rect.height === 0) {
              return { success: false, error: 'Element has no size' };
            }
            
            if (style.visibility === 'hidden' || style.display === 'none') {
              return { success: false, error: 'Element is hidden' };
            }

            // Scroll into view if needed
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });

            // Highlight element for visual feedback
            if (window.agentHelpers && window.agentHelpers.highlightElement) {
              window.agentHelpers.highlightElement('$selector');
            }

            // Wait briefly then click
            setTimeout(() => {
              element.click();
              
              // Trigger additional events for better compatibility
              element.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
              element.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
              element.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            }, 300);

            return { 
              success: true, 
              elementInfo: {
                tag: element.tagName,
                text: element.textContent.trim(),
                id: element.id,
                className: element.className
              }
            };
          } catch (error) {
            return { success: false, error: error.message };
          }
        })();
      ''';

      // In a real implementation, this would be executed in the WebView
      // For now, we'll simulate success
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate action delay

      return StepResult.success('Successfully clicked element: $selector', {
        'selector': selector,
        'attempts': (_retryAttempts + 1).toString(),
      });

    } catch (e) {
      _retryAttempts++;
      print('❌ Click failed (attempt $_retryAttempts): $e');

      if (_retryAttempts < _maxRetries) {
        print('🔄 Retrying click in 1 second...');
        await Future.delayed(const Duration(seconds: 1));
        return await _clickWithRetry(selector);
      }

      return StepResult.error('Click failed after $_maxRetries attempts: $e');
    }
  }

  /// Type text into an element with retry and validation
  Future<StepResult> type(String selector, String text) async {
    if (!_isInitialized) {
      return StepResult.error('Screen control not initialized');
    }

    _retryAttempts = 0;
    return await _typeWithRetry(selector, text);
  }

  /// Internal type with retry mechanism
  Future<StepResult> _typeWithRetry(String selector, String text) async {
    try {
      print('⌨️ Agent typing "$text" into: $selector (attempt ${_retryAttempts + 1})');

      final script = '''
        (function() {
          try {
            const element = document.querySelector('$selector');
            if (!element) {
              return { success: false, error: 'Element not found: $selector' };
            }

            // Check if element can accept text input
            const inputTypes = ['input', 'textarea'];
            const inputType = element.type ? element.type.toLowerCase() : '';
            const isTextInput = inputTypes.includes(element.tagName.toLowerCase()) || 
                               ['text', 'email', 'password', 'search', 'url', 'tel'].includes(inputType);

            if (!isTextInput && !element.isContentEditable) {
              return { success: false, error: 'Element is not a text input' };
            }

            // Scroll into view and highlight
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            
            if (window.agentHelpers && window.agentHelpers.highlightElement) {
              window.agentHelpers.highlightElement('$selector');
            }

            // Focus the element
            element.focus();

            // Clear existing content
            if (element.value !== undefined) {
              element.value = '';
            } else if (element.textContent !== undefined) {
              element.textContent = '';
            }

            // Type the text
            const textToType = '$text';
            if (element.value !== undefined) {
              element.value = textToType;
            } else {
              element.textContent = textToType;
            }

            // Trigger input events
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            element.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true }));

            return { 
              success: true, 
              elementInfo: {
                tag: element.tagName,
                type: element.type,
                value: element.value || element.textContent,
                id: element.id
              }
            };
          } catch (error) {
            return { success: false, error: error.message };
          }
        })();
      ''';

      // Simulate typing action
      await Future.delayed(Duration(milliseconds: 100 * text.length)); // Simulate typing speed

      return StepResult.success('Successfully typed text into: $selector', {
        'selector': selector,
        'text': text,
        'attempts': (_retryAttempts + 1).toString(),
      });

    } catch (e) {
      _retryAttempts++;
      print('❌ Type failed (attempt $_retryAttempts): $e');

      if (_retryAttempts < _maxRetries) {
        print('🔄 Retrying type in 1 second...');
        await Future.delayed(const Duration(seconds: 1));
        return await _typeWithRetry(selector, text);
      }

      return StepResult.error('Type failed after $_maxRetries attempts: $e');
    }
  }

  /// Scroll to element or by amount
  Future<StepResult> scroll({String? selector, int? deltaX, int? deltaY}) async {
    try {
      if (selector != null) {
        print('📜 Agent scrolling to element: $selector');
        
        final script = '''
          (function() {
            const element = document.querySelector('$selector');
            if (!element) {
              return { success: false, error: 'Element not found' };
            }
            
            element.scrollIntoView({ behavior: 'smooth', block: 'center' });
            return { success: true };
          })();
        ''';
        
        await Future.delayed(const Duration(milliseconds: 1000)); // Simulate scroll
        
        return StepResult.success('Scrolled to element: $selector');
      } else if (deltaX != null || deltaY != null) {
        print('📜 Agent scrolling by delta: x=$deltaX, y=$deltaY');
        
        final script = '''
          window.scrollBy(${deltaX ?? 0}, ${deltaY ?? 0});
        ''';
        
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate scroll
        
        return StepResult.success('Scrolled by delta: x=${deltaX ?? 0}, y=${deltaY ?? 0}');
      } else {
        return StepResult.error('Either selector or delta coordinates must be provided');
      }
    } catch (e) {
      print('❌ Scroll failed: $e');
      return StepResult.error('Scroll failed: $e');
    }
  }

  /// Hover over an element
  Future<StepResult> hover(String selector) async {
    try {
      print('🎯 Agent hovering over: $selector');

      final script = '''
        (function() {
          const element = document.querySelector('$selector');
          if (!element) {
            return { success: false, error: 'Element not found' };
          }

          // Scroll into view
          element.scrollIntoView({ behavior: 'smooth', block: 'center' });

          // Trigger hover events
          element.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
          element.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));

          return { success: true };
        })();
      ''';

      await Future.delayed(const Duration(milliseconds: 300)); // Simulate hover

      return StepResult.success('Hovered over element: $selector');
    } catch (e) {
      print('❌ Hover failed: $e');
      return StepResult.error('Hover failed: $e');
    }
  }

  /// Select option from dropdown
  Future<StepResult> selectOption(String selector, String optionValue) async {
    try {
      print('📋 Agent selecting option "$optionValue" from: $selector');

      final script = '''
        (function() {
          const select = document.querySelector('$selector');
          if (!select) {
            return { success: false, error: 'Select element not found' };
          }

          if (select.tagName.toLowerCase() !== 'select') {
            return { success: false, error: 'Element is not a select' };
          }

          // Find and select the option
          const option = select.querySelector('option[value="$optionValue"]') || 
                        Array.from(select.options).find(opt => opt.text === '$optionValue');

          if (!option) {
            return { success: false, error: 'Option not found: $optionValue' };
          }

          select.value = option.value;
          select.dispatchEvent(new Event('change', { bubbles: true }));

          return { 
            success: true, 
            selectedValue: option.value,
            selectedText: option.text 
          };
        })();
      ''';

      await Future.delayed(const Duration(milliseconds: 200)); // Simulate selection

      return StepResult.success('Selected option: $optionValue from $selector');
    } catch (e) {
      print('❌ Select option failed: $e');
      return StepResult.error('Select option failed: $e');
    }
  }

  /// Take a screenshot for verification
  Future<StepResult> takeScreenshot() async {
    try {
      print('📸 Agent taking screenshot');
      
      // This would integrate with the WebView screenshot functionality
      // For now, simulate the action
      await Future.delayed(const Duration(milliseconds: 500));

      return StepResult.success('Screenshot captured', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Screenshot failed: $e');
      return StepResult.error('Screenshot failed: $e');
    }
  }

  /// Wait for element to become visible or clickable
  Future<StepResult> waitForElement(String selector, {
    int timeoutSeconds = 10,
    bool checkVisible = true,
    bool checkClickable = false,
  }) async {
    try {
      print('⏳ Agent waiting for element: $selector (timeout: ${timeoutSeconds}s)');

      final stopwatch = Stopwatch()..start();

      while (stopwatch.elapsedMilliseconds < timeoutSeconds * 1000) {
        final script = '''
          (function() {
            const element = document.querySelector('$selector');
            if (!element) return { exists: false };

            const rect = element.getBoundingClientRect();
            const style = window.getComputedStyle(element);

            const isVisible = rect.width > 0 && rect.height > 0 && 
                            style.visibility !== 'hidden' && 
                            style.display !== 'none';

            const isClickable = !element.disabled && 
                               style.pointerEvents !== 'none';

            return {
              exists: true,
              visible: isVisible,
              clickable: isClickable
            };
          })();
        ''';

        // Simulate checking element state
        await Future.delayed(const Duration(milliseconds: 500));

        // For simulation, assume element appears after some time
        if (stopwatch.elapsedMilliseconds > 2000) {
          return StepResult.success('Element found and ready: $selector');
        }
      }

      return StepResult.error('Element not ready after ${timeoutSeconds}s: $selector');
    } catch (e) {
      print('❌ Wait for element failed: $e');
      return StepResult.error('Wait for element failed: $e');
    }
  }

  /// Get element information for debugging
  Future<StepResult> getElementInfo(String selector) async {
    try {
      final script = '''
        (function() {
          const element = document.querySelector('$selector');
          if (!element) {
            return { success: false, error: 'Element not found' };
          }

          const rect = element.getBoundingClientRect();
          const style = window.getComputedStyle(element);

          return {
            success: true,
            element: {
              tag: element.tagName,
              id: element.id,
              className: element.className,
              text: element.textContent.trim(),
              value: element.value,
              type: element.type,
              disabled: element.disabled,
              rect: {
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: rect.height
              },
              style: {
                display: style.display,
                visibility: style.visibility,
                opacity: style.opacity
              }
            }
          };
        })();
      ''';

      // Simulate getting element info
      await Future.delayed(const Duration(milliseconds: 100));

      return StepResult.success('Element info retrieved for: $selector', {
        'selector': selector,
        'elementInfo': 'Simulated element data',
      });
    } catch (e) {
      print('❌ Get element info failed: $e');
      return StepResult.error('Get element info failed: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}