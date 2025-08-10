import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'main.dart';
import 'file_processing.dart';
import 'theme.dart';
import 'app_animations.dart';
import 'micro_interactions.dart';

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
    List<String> messageQueue = const [],
    String? hintText,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme(context) 
          ? const Color(0xFFF1F3F4) // Light grey background for light mode
          : const Color(0xFF303134), // Dark background for dark mode
        borderRadius: BorderRadius.circular(24),
        border: isLightTheme(context) 
          ? Border.all(color: const Color(0xFFE0E0E0), width: 1.0) // Subtle border in light mode
          : null, // No border in dark mode
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ), // Clean fully rounded input area
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.apps_outlined), 
            onPressed: onShowTools, 
            tooltip: 'Tools', 
            color: Theme.of(context).iconTheme.color
          ),
          Expanded(
            child: TextField(
              controller: controller, 
              enabled: true, // Always enabled - queue messages during streaming
              onSubmitted: (val) => onSendMessage(val), // Always allow input
              textInputAction: TextInputAction.send, 
              maxLines: 5, 
              minLines: 1, 
              style: TextStyle(
                color: isLightTheme(context) ? const Color(0xFF202124) : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: isStreaming 
                  ? (messageQueue.isEmpty 
                      ? 'AhamAI is responding... (type to queue)' 
                      : 'Queued: ${messageQueue.length} messages')
                  : 'Ask AhamAI anything...', 
                hintStyle: TextStyle(
                  color: isLightTheme(context) ? const Color(0xFF5F6368) : const Color(0xFFB0B0B0), // Google secondary text
                  fontSize: 16,
                ),
                filled: true, 
                fillColor: Colors.transparent, // Transparent to use container's background
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                border: InputBorder.none, // No border - container provides it
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              )
            ),
          ),
          const SizedBox(width: 8),
          // Always show send button, with stop functionality on a separate small button during streaming
          AnimatedScaleButton(
            onTap: () {
              MicroInteractions.lightImpact();
              onSendMessage(controller.text);
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
              radius: 24, 
              child: Icon(
                Icons.arrow_upward, 
                color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({})
              ),
            ),
          ),
          // Add stop button next to send button during streaming - matching alignment
          if (isStreaming) ...[
            const SizedBox(width: 4),
            AnimatedSlideIn(
              offset: Offset(0.5, 0),
              child: PulseAnimation(
                child: AnimatedScaleButton(
                  onTap: () {
                    MicroInteractions.mediumImpact();
                    onStopStreaming();
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 24,
                    child: const Icon(Icons.stop, size: 20, color: Colors.white),
                  ),
                ),
              ),
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

  /// Tools bottom sheet - Complete original implementation
  static void showToolsBottomSheet({
    required BuildContext context,
    required Function() onImageGeneration,
    required Function() onPresentationGeneration,
    required Function() onDiagramGeneration,
    required Function() onPickCamera,
    required Function() onPickGallery,
    required Function() onPickFile,
    required bool isWebSearchEnabled,
    required Function(bool) onWebSearchToggle,
    required bool isThinkingModeEnabled,
    required Function(bool) onThinkingModeToggle,
    required bool isResearchModeEnabled,
    required Function(bool) onResearchModeToggle,
    required Function() onShowToolsHelp,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ToolsBottomSheetContent(
        isWebSearchEnabled: isWebSearchEnabled,
        isThinkingModeEnabled: isThinkingModeEnabled,
        isResearchModeEnabled: isResearchModeEnabled,
        onImageGeneration: onImageGeneration,
        onPresentationGeneration: onPresentationGeneration,
        onDiagramGeneration: onDiagramGeneration,
        onPickCamera: onPickCamera,
        onPickGallery: onPickGallery,
        onPickFile: onPickFile,
        onWebSearchToggle: onWebSearchToggle,
        onThinkingModeToggle: onThinkingModeToggle,
        onResearchModeToggle: onResearchModeToggle,
        onShowToolsHelp: onShowToolsHelp,
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
class FileSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FileSourceButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).iconTheme.color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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

/// Stateful Tools Bottom Sheet Content for instant toggle updates
class _ToolsBottomSheetContent extends StatefulWidget {
  final bool isWebSearchEnabled;
  final bool isThinkingModeEnabled;
  final bool isResearchModeEnabled;
  final Function() onImageGeneration;
  final Function() onPresentationGeneration;
  final Function() onDiagramGeneration;
  final Function() onPickCamera;
  final Function() onPickGallery;
  final Function() onPickFile;
  final Function(bool) onWebSearchToggle;
  final Function(bool) onThinkingModeToggle;
  final Function(bool) onResearchModeToggle;
  final Function() onShowToolsHelp;

  const _ToolsBottomSheetContent({
    required this.isWebSearchEnabled,
    required this.isThinkingModeEnabled,
    required this.isResearchModeEnabled,
    required this.onImageGeneration,
    required this.onPresentationGeneration,
    required this.onDiagramGeneration,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onPickFile,
    required this.onWebSearchToggle,
    required this.onThinkingModeToggle,
    required this.onResearchModeToggle,
    required this.onShowToolsHelp,
  });

  @override
  State<_ToolsBottomSheetContent> createState() => _ToolsBottomSheetContentState();
}

class _ToolsBottomSheetContentState extends State<_ToolsBottomSheetContent> {
  late bool localWebSearch;
  late bool localThinking;
  late bool localResearch;

  @override
  void initState() {
    super.initState();
    localWebSearch = widget.isWebSearchEnabled;
    localThinking = widget.isThinkingModeEnabled;
    localResearch = widget.isResearchModeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File attachment options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FileSourceButton(
                icon: Icons.camera_alt_outlined, 
                label: 'Camera', 
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickCamera();
                }
              ),
              FileSourceButton(
                icon: Icons.photo_library_outlined, 
                label: 'Photos', 
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickGallery();
                }
              ),
              FileSourceButton(
                icon: Icons.folder_open_outlined, 
                label: 'Files', 
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickFile();
                }
              ),
              FileSourceButton(
                icon: Icons.help_outline, 
                label: 'AI Tools', 
                onTap: () {
                  Navigator.pop(context);
                  widget.onShowToolsHelp();
                }
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // AI Mode Toggles
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: const Icon(Icons.public), 
            title: const Text('Search the web'), 
            trailing: Switch(
              value: localWebSearch, 
              onChanged: (bool value) { 
                setState(() {
                  localWebSearch = value;
                }); 
                widget.onWebSearchToggle(value);
              }
            )
          ),
          // Thinking mode toggle
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Thinking Mode'),
            subtitle: Text(
              localThinking 
                ? 'Showing AI reasoning process' 
                : 'Show AI thought process',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Switch(
              value: localThinking,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) {
                setState(() {
                  localThinking = value;
                }); 
                widget.onThinkingModeToggle(value);
              }
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: const Icon(Icons.search), 
            title: const Text('Research mode'), 
            subtitle: const Text('Deep research with multiple sources'), 
            trailing: Switch(
              value: localResearch, 
              onChanged: (bool value) { 
                setState(() {
                  localResearch = value;
                }); 
                widget.onResearchModeToggle(value);
              }
            )
          ),
          
          // Generation Tools
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: const Icon(Icons.image_outlined), 
            title: const Text('Create an image'), 
            onTap: () { 
              Navigator.pop(context); 
              widget.onImageGeneration(); 
            }
          ),
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: const Icon(Icons.slideshow_outlined), 
            title: const Text('Make a presentation'), 
            onTap: () { 
              Navigator.pop(context); 
              widget.onPresentationGeneration(); 
            }
          ),
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: const Icon(Icons.bar_chart_outlined), 
            title: const Text('Generate diagram'), 
            onTap: () { 
              Navigator.pop(context); 
              widget.onDiagramGeneration(); 
            }
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}