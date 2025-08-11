import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'ai_message_actions.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'web_search.dart';
import 'file_processing.dart';
import 'theme.dart';
import 'enhanced_content_widget.dart';

/// UI Components for Chat Screen - Helper methods for building UI
/// This class provides clean UI building methods without replacing core functionality
class ChatUIComponents {
  
  /// Build enhanced message bubble with better styling - Material 3 design
  static Widget buildMessageBubble({
    required BuildContext context,
    required ChatMessage message,
    required bool isUserMessage,
    required VoidCallback? onLongPress,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUserMessage 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUserMessage 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }

  /// Build enhanced input field with better styling - Material 3 design
  static Widget buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required bool isStreaming,
    required ChatAttachment? attachment,
    required VoidCallback onSend,
    required VoidCallback onAttach,
    required VoidCallback onClearAttachment,
    required VoidCallback onVoiceInput,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Attachment preview if present
          if (attachment != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded, 
                    size: 18, 
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded, 
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: onClearAttachment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          
          // Input row
          Row(
            children: [
              // Attachment button
              IconButton(
                icon: Icon(
                  Icons.attach_file_rounded, 
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: isStreaming ? null : onAttach,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isStreaming,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isStreaming ? null : onSend(),
                ),
              ),
              
              // Voice input button
              IconButton(
                icon: Icon(
                  Icons.mic_rounded, 
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: isStreaming ? null : onVoiceInput,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                ),
              ),
              
              // Send button - Use FilledButton.icon for Material 3
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: onSend,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    minimumSize: const Size(48, 48),
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    isStreaming ? Icons.stop_rounded : Icons.send_rounded,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build enhanced search results widget
  static Widget buildSearchResultsWidget(BuildContext context, List<SearchResult> results) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Web Search Results',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...results.take(3).map((result) => _buildSearchResultItem(context, result)),
        ],
      ),
    );
  }

  static Widget _buildSearchResultItem(BuildContext context, SearchResult result) {
    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(result.url))) {
          await launchUrl(Uri.parse(result.url), mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              result.snippet,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              result.url,
              style: TextStyle(
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced scroll to bottom button
  static Widget buildScrollToBottomButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required bool showScrollToBottom,
  }) {
    return AnimatedOpacity(
      opacity: showScrollToBottom ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 80, right: 16),
        child: FloatingActionButton.small(
          onPressed: showScrollToBottom ? onPressed : null,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  /// Build message content with enhanced support for ChemJAX, LaTeX, and HTML
  static Widget buildMessageWithChemJAX({
    required BuildContext context,
    required String content,
    required bool isUserMessage,
  }) {
    return EnhancedContentWidget(
      content: content,
      isUserMessage: isUserMessage,
    );
  }
}