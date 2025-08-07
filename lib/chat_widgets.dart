import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'main.dart';
import 'file_processing.dart';
import 'theme.dart';

/// Chat Widgets - Reusable widget components for the chat screen
/// This contains all the small, reusable widgets used throughout the chat interface
class ChatWidgets {
  
  /// Input field widget for typing messages
  static Widget buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required bool isStreaming,
    required Function(String) onSendMessage,
    required Function() onAttachFile,
    required Function() onVoiceInput,
    required Function() onStopStreaming,
    required Function() onShowTools,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Tools button
          IconButton(
            icon: const Icon(Icons.apps_outlined),
            onPressed: onShowTools,
            tooltip: 'Tools',
            color: Theme.of(context).iconTheme.color,
          ),
          
          // Text input field
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isStreaming,
              onSubmitted: (val) => onSendMessage(val),
              maxLines: null,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: hintText ?? (isStreaming 
                  ? 'AI is responding...' 
                  : 'Type your message...'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Action buttons
          if (isStreaming) ...[
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: onStopStreaming,
              tooltip: 'Stop',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: onAttachFile,
              tooltip: 'Attach File',
            ),
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: onVoiceInput,
              tooltip: 'Voice Input',
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => onSendMessage(controller.text),
              tooltip: 'Send',
            ),
          ],
        ],
      ),
    );
  }

  /// Message queue indicator widget
  static Widget buildMessageQueueIndicator({
    required List<String> queuedMessages,
    required bool isProcessing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.queue, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            isProcessing
              ? 'Processing...'
              : 'Queued: ${queuedMessages.length} messages',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Attachment preview widget
  static Widget buildAttachmentPreview({
    required ChatAttachment attachment,
    required Function() onClear,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                if (attachment.containedFileNames != null && 
                    attachment.containedFileNames!.isNotEmpty)
                  Text(
                    '${attachment.containedFileNames!.length} files',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
            iconSize: 20,
            color: Colors.blue[700],
          ),
        ],
      ),
    );
  }

  /// Image attachment preview widget
  static Widget buildImageAttachmentPreview({
    required XFile imageFile,
    required Function() onClear,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(imageFile.path),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onClear,
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
    );
  }

  /// Scroll to bottom button
  static Widget buildScrollToBottomButton({
    required Function() onPressed,
    required bool visible,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.small(
        onPressed: visible ? onPressed : null,
        child: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }

  /// User message options bottom sheet
  static void showUserMessageOptions({
    required BuildContext context,
    required ChatMessage message,
    required int index,
    required Function(String) onCopy,
    required Function() onEditAndResend,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                onCopy(message.text);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit and Resend'),
              onTap: () {
                Navigator.pop(context);
                onEditAndResend();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Tools bottom sheet
  static void showToolsBottomSheet({
    required BuildContext context,
    required Function() onImageGeneration,
    required Function() onPresentationGeneration,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Tools',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Image Generation
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Generate Image'),
              subtitle: const Text('Create images from text descriptions'),
              onTap: () {
                Navigator.pop(context);
                onImageGeneration();
              },
            ),
            
            // Presentation Generation
            ListTile(
              leading: const Icon(Icons.slideshow, color: Colors.green),
              title: const Text('Generate Presentation'),
              subtitle: const Text('Create slide presentations'),
              onTap: () {
                Navigator.pop(context);
                onPresentationGeneration();
              },
            ),
            
            const SizedBox(height: 20),
            
            // Cancel button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Loading indicator for various operations
  static Widget buildLoadingIndicator({
    required String message,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color ?? Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Error message widget
  static Widget buildErrorMessage({
    required String message,
    Function()? onRetry,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  /// Custom app bar for chat screen
  static PreferredSizeWidget buildChatAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Function()? onBack,
  }) {
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      leading: onBack != null
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          )
        : null,
      actions: actions,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
    );
  }
}

/// Message Queue Indicator Widget
class MessageQueueIndicator extends StatelessWidget {
  final List<String> queuedMessages;
  final bool isProcessing;

  const MessageQueueIndicator({
    super.key,
    required this.queuedMessages,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return ChatWidgets.buildMessageQueueIndicator(
      queuedMessages: queuedMessages,
      isProcessing: isProcessing,
    );
  }
}

/// Attachment Preview Widget
class AttachmentPreview extends StatelessWidget {
  final ChatAttachment attachment;
  final Function() onClear;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ChatWidgets.buildAttachmentPreview(
      attachment: attachment,
      onClear: onClear,
    );
  }
}