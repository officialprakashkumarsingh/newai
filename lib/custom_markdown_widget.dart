import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'theme.dart';

/// Custom markdown widget that uses Kotlin-based renderer
class CustomMarkdownWidget extends StatefulWidget {
  final String data;
  final bool selectable;
  final double? fontSize;

  const CustomMarkdownWidget({
    super.key,
    required this.data,
    this.selectable = true,
    this.fontSize,
  });

  @override
  State<CustomMarkdownWidget> createState() => _CustomMarkdownWidgetState();
}

class _CustomMarkdownWidgetState extends State<CustomMarkdownWidget> {
  static const platform = MethodChannel('com.ahamai.markdown');
  
  Future<Widget>? _markdownFuture;
  
  @override
  void initState() {
    super.initState();
    _markdownFuture = _renderMarkdown();
  }
  
  @override
  void didUpdateWidget(CustomMarkdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || 
        oldWidget.fontSize != widget.fontSize) {
      _markdownFuture = _renderMarkdown();
    }
  }

  Future<Widget> _renderMarkdown() async {
    final isDark = !isLightTheme(context);
    
    try {
      final result = await platform.invokeMethod('renderMarkdown', {
        'markdown': widget.data,
        'isDarkTheme': isDark,
        'fontSize': widget.fontSize ?? 16.0,
      });
      
      if (result['success'] == true && result['image'] != null) {
        final imageBytes = base64Decode(result['image']);
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: widget.selectable 
            ? SelectableImage(imageBytes: imageBytes, originalText: widget.data)
            : Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
        );
      } else {
        throw Exception(result['error'] ?? 'Unknown rendering error');
      }
    } catch (e) {
      // Fallback to simple text display
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Markdown Rendering Failed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.data,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _markdownFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Rendering markdown...', style: TextStyle(fontSize: 14)),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Failed to render markdown: ${snapshot.error}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          );
        } else {
          return snapshot.data ?? const SizedBox.shrink();
        }
      },
    );
  }
}

/// Widget that allows text selection on rendered markdown image
class SelectableImage extends StatefulWidget {
  final Uint8List imageBytes;
  final String originalText;

  const SelectableImage({
    super.key,
    required this.imageBytes,
    required this.originalText,
  });

  @override
  State<SelectableImage> createState() => _SelectableImageState();
}

class _SelectableImageState extends State<SelectableImage> {
  bool _showOriginalText = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () {
            setState(() {
              _showOriginalText = !_showOriginalText;
            });
            
            // Show snackbar with instruction
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _showOriginalText 
                    ? 'Showing raw text - long press to show rendered view'
                    : 'Showing rendered view - long press to show selectable text',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: _showOriginalText
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: SelectableText(
                  widget.originalText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                ),
              )
            : Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
        ),
        if (!_showOriginalText)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.originalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Markdown copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showOriginalText = true;
                    });
                  },
                  icon: const Icon(Icons.text_fields, size: 16),
                  label: const Text('Select', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Service class for markdown operations
class MarkdownService {
  static const platform = MethodChannel('com.ahamai.markdown');

  /// Process markdown content and get metadata
  static Future<MarkdownMetadata> processMarkdown(String markdown) async {
    try {
      final result = await platform.invokeMethod('processMarkdown', {
        'markdown': markdown,
      });

      return MarkdownMetadata(
        content: result['content'] ?? '',
        hasCodeBlocks: result['hasCodeBlocks'] ?? false,
        hasLatex: result['hasLatex'] ?? false,
        hasTables: result['hasTables'] ?? false,
        hasImages: result['hasImages'] ?? false,
        hasLinks: result['hasLinks'] ?? false,
        lineCount: result['lineCount'] ?? 0,
        wordCount: result['wordCount'] ?? 0,
      );
    } catch (e) {
      // Fallback analysis
      return MarkdownMetadata(
        content: markdown,
        hasCodeBlocks: markdown.contains('```'),
        hasLatex: markdown.contains('\$'),
        hasTables: markdown.contains('|'),
        hasImages: markdown.contains('!['),
        hasLinks: markdown.contains('['),
        lineCount: markdown.split('\n').length,
        wordCount: markdown.split(RegExp(r'\s+')).length,
      );
    }
  }

  /// Check if content should use custom renderer
  static bool shouldUseCustomRenderer(String content) {
    // Use custom renderer for complex content
    return content.contains('```') ||    // Code blocks
           content.contains('\$') ||     // LaTeX
           content.contains('|') ||      // Tables
           content.contains('![') ||     // Images
           content.contains('#') ||      // Headers
           content.length > 500;         // Long content
  }
}

/// Metadata about markdown content
class MarkdownMetadata {
  final String content;
  final bool hasCodeBlocks;
  final bool hasLatex;
  final bool hasTables;
  final bool hasImages;
  final bool hasLinks;
  final int lineCount;
  final int wordCount;

  const MarkdownMetadata({
    required this.content,
    required this.hasCodeBlocks,
    required this.hasLatex,
    required this.hasTables,
    required this.hasImages,
    required this.hasLinks,
    required this.lineCount,
    required this.wordCount,
  });

  bool get isComplex {
    return hasCodeBlocks || hasLatex || hasTables || hasImages || lineCount > 10;
  }
}