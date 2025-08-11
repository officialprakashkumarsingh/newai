import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'ai_message_actions.dart';
import 'thinking_panel.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'web_search.dart';
import 'file_processing.dart';
import 'theme.dart';
import 'enhanced_content_widget.dart';

/// UI Components for Chat Screen - Helper methods for building UI
/// This class provides clean UI building methods without replacing core functionality
class ChatUIComponents {
  
  /// Build enhanced message bubble with better styling
  static Widget buildMessageBubble({
    required BuildContext context,
    required ChatMessage message,
    required bool isUserMessage,
    required VoidCallback? onLongPress,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isUserMessage 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isUserMessage 
          ? null 
          : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }

  /// Build enhanced input field with better styling
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
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
                icon: Icon(Icons.attach_file, color: Theme.of(context).primaryColor),
                onPressed: isStreaming ? null : onAttach,
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isStreaming,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => isStreaming ? null : onSend(),
                ),
              ),
              
              // Voice input button
              IconButton(
                icon: Icon(Icons.mic, color: Theme.of(context).primaryColor),
                onPressed: isStreaming ? null : onVoiceInput,
              ),
              
              // Send button
              IconButton(
                icon: Icon(
                  isStreaming ? Icons.stop : Icons.send,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: onSend,
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