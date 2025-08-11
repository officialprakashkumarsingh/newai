import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_ui_components.dart';

import 'enhanced_content_widget.dart';
import 'main.dart';
import 'ai_message_actions.dart';
import 'improved_ai_actions.dart';
import 'app_animations.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'web_search.dart';
import 'theme.dart';
import 'chat_widgets.dart';
import 'queue_panel.dart';
import 'fullscreen_diagram_screen.dart';
import 'feature_shimmer.dart';
import 'dotted_background.dart';
import 'dotted_appbar.dart';

// Import for SearchResultCard
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.result});
  final SearchResult result;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              result.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat UI Builder - Contains all UI building methods from chat_screen.dart
/// This handles the visual presentation of messages, charts, and other UI elements
class ChatUI {
  
  /// Build the main message widget
  static Widget buildMessage(ChatMessage message, int index, String chatId, BuildContext context, {
    required Function(String) onCopy,
    required Function() onRegenerate,
    required Function() onUserMessageOptions,
    bool isStreaming = false,
  }) {
    final isUserMessage = message.role == 'user';
    final isModelMessage = message.role == 'model';
    final showActionButtons = index > 0 && isModelMessage && !isStreaming && 
                              message.type == MessageType.text &&
                              message.presentationData == null && message.diagramData == null && message.imageUrl == null;
    
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isUserMessage) 
            GestureDetector(
              onLongPress: () => onUserMessageOptions(),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLightTheme(context)
                      ? const Color(0xFF5F6B73) // Greyish blue bubble for light mode
                      : const Color(0xFF2C2C2E), // Dark mode: Card Background
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: _buildMessageContent(message, isUserMessage, onUserMessageOptions, context, isStreaming: isStreaming),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: _buildMessageContent(message, isUserMessage, onUserMessageOptions, context, isStreaming: isStreaming),
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
          
          // Action buttons for AI messages - hidden during streaming
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
  static Widget _buildMessageContent(ChatMessage message, bool isUserMessage, Function() onUserMessageOptions, BuildContext context, {bool isStreaming = false}) {
    // Check if message has attached image bytes (user uploaded image)
    if (message.imageBytes != null) {
      return _buildUserImageMessage(message, isUserMessage, onUserMessageOptions, context, isStreaming: isStreaming);
    }
    
    switch (message.type) {
      case MessageType.image:
        return _buildImageMessage(message, context);
      case MessageType.presentation:
        return _buildPresentationMessage(message, context);
      case MessageType.diagram:
        return _buildDiagramMessage(message, context);
      case MessageType.text:
      default:
        return _buildTextMessage(message, isUserMessage, onUserMessageOptions, null, context, isStreaming: isStreaming);
    }
  }

  /// Build user image message (user uploaded images with imageBytes)
  static Widget _buildUserImageMessage(ChatMessage message, bool isUserMessage, Function() onUserMessageOptions, BuildContext context, {bool isStreaming = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          _buildTextMessage(message, isUserMessage, onUserMessageOptions, null, context, isStreaming: isStreaming),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            message.imageBytes!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 40, color: Colors.red),
                    Text('Failed to load image', style: TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build image message (AI generated images with imageUrl)
  static Widget _buildImageMessage(ChatMessage message, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          buildMessageContent(message.text, context),
        const SizedBox(height: 8),
        
        // Show shimmer if imageUrl is null (loading), otherwise show image
        message.imageUrl == null
          ? Column(
              children: [
                FeatureShimmer.buildImageGenerationShimmer(context),
                const FeatureStatusShimmer(feature: 'image'),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageWidget(message.imageUrl!, context),
        ),
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
          : DiagramService.buildDiagramWidget(message.diagramData!, context, (data) {
              // Navigate to fullscreen diagram on tap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullscreenDiagramScreen(diagramData: data),
                ),
              );
            }),
      ],
    );
  }

  /// Build text message
  static Widget _buildTextMessage(ChatMessage message, bool isUserMessage, Function() onUserMessageOptions, Function()? onAIMessageOptions, BuildContext context, {bool isStreaming = false}) {
    return GestureDetector(
      onLongPress: isUserMessage ? onUserMessageOptions : null,
      onTap: !isUserMessage ? onAIMessageOptions : null,
      child: EnhancedContentWidget(
        content: message.text,
        isUserMessage: isUserMessage,
      ),
    );
  }

  /// Build message content with markdown support
  static Widget buildMessageContent(String text, BuildContext context, {bool isUserMessage = false}) {
    // Use ChemJAX-enabled rendering for all messages
    return ChatUIComponents.buildMessageWithChemJAX(
      context: context,
      content: text,
      isUserMessage: isUserMessage,
    );
    
    /* Original markdown-only code replaced with ChemJAX-enabled rendering above */
  }

  /// Build search results widget
  static Widget buildSearchResultsWidget(List<SearchResult> results, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 22, top: 8, bottom: 8),
          child: Text("Sources", style: Theme.of(context).textTheme.titleSmall),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            itemCount: results.length,
            itemBuilder: (context, index) => SearchResultCard(result: results[index]),
          ),
        ),
      ],
    );
  }

  /// Build the main chat screen layout
  static Widget buildChatLayout({
    required BuildContext context,
    required String chatTitle,
    required ScrollController scrollController,
    required List<ChatMessage> messages,
    required String chatId,
    required Function(String) onCopy,
    required Function(int) onRegenerate,
    required Function(int) onUserMessageOptions,
    required List<String> messageQueue,
    required bool isProcessingQueue,
    required dynamic attachment,
    required dynamic attachedImage,
    required bool showScrollToBottom,
    required bool isStreaming,
    required Function() onScrollToBottom,
    required Widget inputField,
  }) {
    return Scaffold(
      appBar: DottedAppBar(
        title: Text(chatTitle),
        centerTitle: true,
      ),
      body: DottedBackground(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty 
                ? _buildWelcomeMessage(context)
                : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => buildMessage(
                    messages[index],
                    index,
                    chatId,
                    context,
                    onCopy: onCopy,
                    onRegenerate: () => onRegenerate(index - 1),
                    onUserMessageOptions: () => onUserMessageOptions(index),
                    isStreaming: isStreaming,
                  ),
                  cacheExtent: 1000.0,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                ),
          ),
          
          // Message queue panel
          if (messageQueue.isNotEmpty || isProcessingQueue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: QueuePanel(
                queuedMessages: messageQueue,
                isProcessing: isProcessingQueue,
              ),
            ),
          
          // Attachment preview
          if (attachment != null)
            ChatWidgets.buildAttachmentPreview(
              attachment: attachment,
              onClear: () {}, // Will be handled by parent
            ),
          
          // Attached image preview
          if (attachedImage != null)
            Container(
              margin: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(attachedImage.path), // Convert XFile to File
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {}, // Will be handled by parent
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Scroll to bottom button - positioned above input area
          if (showScrollToBottom && !isStreaming)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onScrollToBottom,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isLightTheme(context) ? Colors.white : Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          
          inputField,
          ],
        ),
      ),
    );
  }

  /// Build file attachment display in message
  static Widget buildFileAttachmentInMessage({
    required ChatMessage message,
    required bool isDark,
  }) {
    if (message.attachedFileName == null) return const SizedBox.shrink();
    
    final hasContainedFiles = message.attachedContainedFiles != null && 
                              message.attachedContainedFiles!.isNotEmpty;
    final icon = hasContainedFiles ? Icons.folder_zip_outlined : Icons.description_outlined;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.attachedFileName!,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasContainedFiles)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
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
      ),
    );
  }

  /// Build welcome message for empty chat
  static Widget _buildWelcomeMessage(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Ask me anything! I can help with:\n• Answering questions\n• Creating diagrams & charts\n• Generating presentations\n• Image generation\n• Web research',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}