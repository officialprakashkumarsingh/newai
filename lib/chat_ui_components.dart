import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'main.dart';
import 'ai_message_actions.dart';
import 'thinking_panel.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'web_search.dart';
import 'file_processing.dart';
import 'theme.dart';

class ChatUIComponents {
  /// Build a chat message widget
  static Widget buildMessage(
    BuildContext context,
    ChatMessage message, 
    int index,
    String chatId,
    Function(String) onCopy,
    Function() onRegenerate,
    Function() onUserMessageOptions,
  ) {
    final isUserMessage = message.role == 'user';
    final isModelMessage = message.role == 'model';
    final showActionButtons = index > 0 && isModelMessage;
    
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content based on type
                if (message.type == MessageType.image && message.imageUrl != null)
                  _buildImageMessage(context, message)
                else if (message.type == MessageType.presentation && message.presentationData != null)
                  _buildPresentationMessage(context, message)
                else if (message.type == MessageType.diagram && message.diagramData != null)
                  _buildDiagramMessage(context, message)
                else
                  _buildTextMessage(context, message, isUserMessage, onUserMessageOptions),
              ],
            ),
          ),
          
          // Research widget if present
          if (message.researchWidget != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: message.researchWidget!,
            ),
          
          // Search results if present
          if (isModelMessage && message.searchResults != null && message.searchResults!.isNotEmpty)
            buildSearchResultsWidget(context, message.searchResults!),
          
          // Action buttons for AI messages
          if (showActionButtons && message.text.isNotEmpty && !message.text.startsWith('❌ Error:'))
            AiMessageActions(
              key: ValueKey('actions_${chatId}_$index'),
              messageText: message.text,
              onCopy: () => onCopy(message.text),
              onRegenerate: onRegenerate,
            ),
        ],
      ),
    );
  }

  static Widget _buildImageMessage(BuildContext context, ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          _buildMessageContent(context, message.text),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.imageUrl!,
            width: 300,
            height: 300,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text('Failed to load image'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildPresentationMessage(BuildContext context, ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty && !message.text.contains('Generating presentation'))
          _buildMessageContent(context, message.text),
        const SizedBox(height: 8),
        message.presentationData!.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PresentationService.buildPresentationWidget(message.presentationData!, context),
      ],
    );
  }

  static Widget _buildDiagramMessage(BuildContext context, ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty && !message.text.contains('Generating diagram'))
          _buildMessageContent(context, message.text),
        const SizedBox(height: 8),
        message.diagramData!.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : DiagramService.buildDiagramWidget(message.diagramData!, context, (data) {}),
      ],
    );
  }

  static Widget _buildTextMessage(
    BuildContext context, 
    ChatMessage message, 
    bool isUserMessage, 
    Function() onUserMessageOptions,
  ) {
    return GestureDetector(
      onLongPress: isUserMessage ? onUserMessageOptions : null,
      child: message.thinkingContent != null && message.thinkingContent!.isNotEmpty
        ? ThinkingPanel(
            thinkingContent: message.thinkingContent!,
            finalContent: message.text,
          )
        : _buildMessageContent(context, message.text),
    );
  }

  static Widget _buildMessageContent(BuildContext context, String text) {
    return SelectableText.rich(
      TextSpan(
        children: _parseMessageText(text, context),
      ),
      style: TextStyle(
        fontSize: 16,
        height: 1.4,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  static List<TextSpan> _parseMessageText(String text, BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp codeBlockRegex = RegExp(r'```(\w+)?\n([\s\S]*?)\n```');
    final RegExp inlineCodeRegex = RegExp(r'`([^`]+)`');
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicRegex = RegExp(r'\*(.*?)\*');
    
    int lastEnd = 0;
    
    // Process code blocks first
    for (final match in codeBlockRegex.allMatches(text)) {
      // Add text before code block
      if (match.start > lastEnd) {
        spans.addAll(_parseInlineFormatting(text.substring(lastEnd, match.start), context));
      }
      
      // Add code block
      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      spans.add(TextSpan(
        children: [
          TextSpan(
            text: '\n$code\n',
            style: TextStyle(
              fontFamily: 'Courier',
              backgroundColor: Theme.of(context).cardColor,
              fontSize: 14,
            ),
          ),
        ],
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.addAll(_parseInlineFormatting(text.substring(lastEnd), context));
    }
    
    return spans;
  }

  static List<TextSpan> _parseInlineFormatting(String text, BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp inlineCodeRegex = RegExp(r'`([^`]+)`');
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicRegex = RegExp(r'\*(.*?)\*');
    
    // For simplicity, just return the text as-is for now
    // This can be enhanced later with proper inline formatting
    spans.add(TextSpan(text: text));
    
    return spans;
  }

  /// Build search results widget
  static Widget buildSearchResultsWidget(BuildContext context, List<SearchResult> results) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
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

  /// Build input field with attachment support
  static Widget buildInputField(
    BuildContext context, {
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
      ),
      child: Column(
        children: [
          // Attachment preview
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
}