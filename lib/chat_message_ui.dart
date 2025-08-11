import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'enhanced_content_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';
import 'ai_message_actions.dart';
import 'improved_ai_actions.dart';
import 'app_animations.dart';
import 'thinking_panel.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'chat_chart_builder.dart';
import 'web_search.dart';
import 'theme.dart';
import 'feature_shimmer.dart';

/// Message UI Builder for Chat Screen - Contains all message building logic
/// This class contains ALL the message building methods moved from chat_screen.dart
class ChatMessageUI {

  /// Build complete message widget
  static Widget buildMessage(ChatMessage message, int index, String chatId, BuildContext context, {
    required Function(String) onCopy,
    required Function() onRegenerate,
    required Function() onUserMessageOptions,
  }) {
    final isUserMessage = message.role == 'user';
    final isModelMessage = message.role == 'model';
    final showActionButtons = index > 0 && isModelMessage && 
                              message.type == MessageType.text &&
                              message.presentationData == null && message.diagramData == null && message.imageUrl == null;
    
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
            child: _buildMessageContent(message, isUserMessage, onUserMessageOptions, context),
          ),
          
          // Research widget if present
          if (message.researchWidget != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: message.researchWidget!,
            ),
          
          // Search results if present
          if (isModelMessage && message.searchResults != null && message.searchResults!.isNotEmpty)
            buildSearchResultsWidget(message.searchResults!, context),
          
          // Action buttons for AI messages
          if (showActionButtons && message.text.isNotEmpty && !message.text.startsWith('❌ Error:'))
            AnimatedSlideIn(
              delay: Duration(milliseconds: 200),
              child: ImprovedAiMessageActions(
                key: ValueKey('actions_${chatId}_$index'),
                messageText: message.text,
                onCopy: () => onCopy(message.text),
                onRegenerate: onRegenerate,
              ),
            ),
        ],
      ),
    );
  }

  /// Build message content based on type
  static Widget _buildMessageContent(ChatMessage message, bool isUserMessage, Function() onUserMessageOptions, BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(message, context);
      case MessageType.presentation:
        return _buildPresentationMessage(message, context);
      case MessageType.diagram:
        return _buildDiagramMessage(message, context);
      case MessageType.text:
      default:
        return _buildTextMessage(message, isUserMessage, onUserMessageOptions, context);
    }
  }

  /// Build image message
  static Widget _buildImageMessage(ChatMessage message, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          buildMessageContent(message.text, context),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(message.imageUrl!, context),
        ),
      ],
    );
  }

  /// Build presentation message
  static Widget _buildPresentationMessage(ChatMessage message, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty && !message.text.contains('Generating presentation'))
          buildMessageContent(message.text, context),
        const SizedBox(height: 8),
        (message.presentationData == null || message.presentationData!.isEmpty)
          ? PresentationService.buildPresentationWidget({}, context, isGenerating: true)
          : PresentationService.buildPresentationWidget(message.presentationData!, context),
      ],
    );
  }

  /// Build image widget that handles both data URLs and regular URLs
  static Widget _buildImageWidget(String imageUrl, BuildContext context) {
    // Check if it's a data URL (base64 image)
    if (imageUrl.startsWith('data:')) {
      try {
        // Extract base64 data from data URL
        final base64Data = imageUrl.split(',')[1];
        final bytes = base64.decode(base64Data);
        
        return Image.memory(
          bytes,
          width: 300,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading base64 image: $error');
            return _buildImageError(context);
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildImageError(context);
      }
    } else {
      // Regular URL - use Image.network
      return Image.network(
        imageUrl,
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
          print('Error loading network image: $error');
          return _buildImageError(context);
        },
      );
    }
  }

  /// Build error widget for failed images
  static Widget _buildImageError(BuildContext context) {
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
  }

  /// Build diagram message
  static Widget _buildDiagramMessage(ChatMessage message, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty && !message.text.contains('Generating diagram'))
          buildMessageContent(message.text, context),
        const SizedBox(height: 8),
        (message.diagramData == null || message.diagramData!.isEmpty)
          ? Column(
              children: [
                FeatureShimmer.buildDiagramGenerationShimmer(context),
                const FeatureStatusShimmer(feature: 'diagram'),
              ],
            )
          : ChatChartBuilder.buildDiagramWidget(message.diagramData!, context),
      ],
    );
  }

  /// Build text message
  static Widget _buildTextMessage(ChatMessage message, bool isUserMessage, Function() onUserMessageOptions, BuildContext context) {
    return GestureDetector(
      onLongPress: isUserMessage ? onUserMessageOptions : null,
      child: EnhancedContentWidget(
        content: message.text,
        isUserMessage: isUserMessage,
      ),
    );
  }

  /// Build message content with enhanced support for HTML, LaTeX, and ChemJAX
  static Widget buildMessageContent(String text, BuildContext context) {
    return EnhancedContentWidget(
      content: text,
      isUserMessage: false,
    );
  }

  /// Build search results widget
  static Widget buildSearchResultsWidget(List<SearchResult> results, BuildContext context) {
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
          ...results.take(3).map((result) => _buildSearchResultItem(result, context)),
        ],
      ),
    );
  }

  /// Build individual search result item
  static Widget _buildSearchResultItem(SearchResult result, BuildContext context) {
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

  /// Build file attachment display
  static Widget buildFileAttachmentInMessage(ChatMessage message, BuildContext context) {
    if (message.attachedFileName == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.attachedFileName!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (message.attachedContainedFiles != null && message.attachedContainedFiles!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${message.attachedContainedFiles!.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}