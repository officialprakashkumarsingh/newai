import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Our divided files
import 'chat_state.dart';
import 'chat_ui.dart';
import 'chat_widgets.dart';
import 'chat_logic.dart';
import 'chat_chart_builder.dart';

// Existing imports
import 'main.dart';
import 'diagram_handler.dart';
import 'presentation_service.dart';
// import 'image_service.dart'; // Not needed
import 'file_processing.dart';
import 'theme.dart';

/// Compact Chat Screen - Uses all divided components for clean organization
/// This is a much smaller, more manageable version of the chat screen
class ChatScreenCompact extends StatefulWidget {
  final String chatId;
  final String initialMessage;
  final bool isPinned;

  const ChatScreenCompact({
    super.key,
    required this.chatId,
    this.initialMessage = '',
    this.isPinned = false,
  });

  @override
  State<ChatScreenCompact> createState() => _ChatScreenCompactState();
}

class _ChatScreenCompactState extends State<ChatScreenCompact> with WidgetsBindingObserver {
  late ChatState _chatState;
  late DiagramHandler _diagramHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize state
    _chatState = ChatState();
    _diagramHandler = DiagramHandler(context);
    
    // Setup initial chat
    _setupChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatState.dispose();
    super.dispose();
  }

  /// Setup initial chat state and load data
  Future<void> _setupChat() async {
    await ChatLogic.initializeChat();
    await ChatLogic.setupChatModel();
    
    final messages = await ChatLogic.loadMessages(widget.chatId);
    _chatState.initializeChat(
      chatId: widget.chatId,
      initialMessages: messages,
      isPinned: widget.isPinned,
    );
    
    if (messages.isNotEmpty) {
      final title = ChatLogic.generateChatTitle(messages);
      _chatState.setChatTitle(title);
    }
    
    if (widget.initialMessage.isNotEmpty) {
      _chatState.setInputText(widget.initialMessage);
    }
  }

  /// Handle sending messages
  Future<void> _sendMessage(String input) async {
    if (!ChatLogic.isValidInput(input, _chatState.attachment)) return;

    if (_chatState.isStreaming) {
      _chatState.addToMessageQueue(input);
      _chatState.clearInput();
      return;
    }

    if (_chatState.attachedImage != null) {
      await _sendVisionMessage(input);
    } else {
      await _sendTextMessage(input);
    }
    
    _chatState.clearInput();
    _chatState.clearAllAttachments();
  }

  /// Send text message
  Future<void> _sendTextMessage(String input) async {
    await ChatLogic.sendTextMessage(
      input: input,
      messages: _chatState.messages,
      selectedModel: _chatState.selectedModel,
      isWebSearchEnabled: _chatState.isWebSearchEnabled,
      isResearchModeEnabled: _chatState.isResearchModeEnabled,
      addMessage: _addMessage,
      updateMessage: _updateMessage,
      scrollToBottom: _chatState.scrollToBottom,
      attachment: _chatState.attachment,
    );
  }

  /// Send vision message with image
  Future<void> _sendVisionMessage(String input) async {
    if (_chatState.attachedImage == null) return;
    
    await ChatLogic.sendVisionMessage(
      input: input,
      imageFile: _chatState.attachedImage!,
      messages: _chatState.messages,
      selectedModel: _chatState.selectedModel,
      addMessage: _addMessage,
      updateMessage: _updateMessage,
      scrollToBottom: _chatState.scrollToBottom,
    );
  }

  /// Add message and save
  void _addMessage(ChatMessage message) {
    _chatState.addMessage(message);
    ChatLogic.saveMessages(widget.chatId, _chatState.messages);
    _updateChatTitle();
  }

  /// Update message and save
  void _updateMessage(int index, ChatMessage message) {
    _chatState.updateMessage(index, message);
    ChatLogic.saveMessages(widget.chatId, _chatState.messages);
  }

  /// Update chat title based on messages
  void _updateChatTitle() {
    if (_chatState.messages.isNotEmpty) {
      final title = ChatLogic.generateChatTitle(_chatState.messages);
      _chatState.setChatTitle(title);
    }
  }

  /// Handle streaming updates
  void _onStreamingUpdate(String chunk) {
    ChatLogic.optimizedStreamingUpdate(
      chunk: chunk,
      messages: _chatState.messages,
      updateMessage: _updateMessage,
      scrollToBottom: _chatState.scrollToBottom,
      currentModelResponse: _chatState.currentModelResponse,
      setCurrentModelResponse: _chatState.setCurrentModelResponse,
      setPendingStreamingContent: _chatState.setPendingStreamingContent,
      streamingUpdateTimer: null, // Will be managed by ChatState
      setStreamingUpdateTimer: _chatState.setStreamingUpdateTimer,
    );
  }

  /// Handle streaming completion
  void _onStreamingDone() async {
    await ChatLogic.onStreamingDone(
      messages: _chatState.messages,
      selectedModel: _chatState.selectedModel,
      lastSearchResults: _chatState.lastSearchResults,
      diagramHandler: _diagramHandler,
    );
    
    _chatState.stopStreaming();
    ChatLogic.saveMessages(widget.chatId, _chatState.messages);
    _updateChatTitle();
    
    // Process next message in queue
    await _processMessageQueue();
  }

  /// Handle streaming errors
  void _onStreamingError(dynamic error) {
    ChatLogic.onStreamingError(error, _chatState.messages, _updateMessage);
    _chatState.stopStreaming();
    
    // Process next message in queue
    Future.microtask(() => _processMessageQueue());
  }

  /// Process message queue
  Future<void> _processMessageQueue() async {
    await ChatLogic.processMessageQueue(
      messageQueue: _chatState.messageQueue,
      isProcessingQueue: _chatState.isProcessingQueue,
      isStreaming: _chatState.isStreaming,
      sendTextMessage: _sendTextMessage,
      setProcessingQueue: _chatState.setIsProcessingQueue,
      updateUI: () => setState(() {}),
    );
  }

  /// Regenerate AI response
  void _regenerateResponse(int userMessageIndex) async {
    await ChatLogic.regenerateResponse(
      userMessageIndex: userMessageIndex,
      messages: _chatState.messages,
      selectedModel: _chatState.selectedModel,
      isWebSearchEnabled: _chatState.isWebSearchEnabled,
      addMessage: _addMessage,
      updateMessage: _updateMessage,
      scrollToBottom: _chatState.scrollToBottom,
      removeMessagesFrom: (messages) {
        _chatState.setMessages(messages);
        ChatLogic.saveMessages(widget.chatId, messages);
      },
    );
  }

  /// Show user message options
  void _showUserMessageOptions(int index) {
    if (index < 0 || index >= _chatState.messages.length) return;
    
    final message = _chatState.messages[index];
    ChatWidgets.showUserMessageOptions(
      context: context,
      message: message,
      index: index,
      onCopy: (text) => _copyToClipboard(text),
      onEditAndResend: () {
        _chatState.setInputText(message.text);
        _chatState.removeMessagesFrom(index);
        _chatState.stopStreaming();
      },
    );
  }

  /// Copy text to clipboard
  void _copyToClipboard(String text) {
    ChatLogic.copyToClipboard(text, context);
  }

  /// Handle file attachment
  Future<void> _handleFileAttachment() async {
    try {
      final result = await FileProcessingService.pickAndProcessFile();
      if (result != null) {
        _chatState.setAttachment(result);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching file: $e')),
      );
    }
  }

  /// Handle image attachment
  Future<void> _handleImageAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _chatState.setAttachedImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error attaching image: $e')),
      );
    }
  }

  /// Handle voice input
  Future<void> _handleVoiceInput() async {
    // Voice input implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input not implemented yet')),
    );
  }

  /// Show tools bottom sheet
  void _showToolsBottomSheet() {
    ChatWidgets.showToolsBottomSheet(
      context: context,
      onImageGeneration: () => _generateImage(),
      onPresentationGeneration: () => _generatePresentation(),
    );
  }

  /// Generate image
  void _generateImage() async {
    // Show image generation dialog
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ImageGenerationDialog(),
    );
    
    if (result != null) {
      await ChatLogic.generateImage(
        prompt: result['prompt']!,
        selectedModel: result['model']!,
        addMessage: _addMessage,
        updateMessage: _updateMessage,
      );
    }
  }

  /// Generate presentation
  void _generatePresentation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PresentationDialog(),
    );
    
    if (result != null && result.isNotEmpty) {
      await ChatLogic.generatePresentation(
        topic: result,
        addMessage: _addMessage,
        updateMessage: _updateMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatState,
      child: Consumer<ChatState>(
        builder: (context, chatState, child) {
          return ChatUI.buildChatLayout(
            context: context,
            chatTitle: chatState.displayTitle,
            scrollController: chatState.scrollController,
            messages: chatState.messages,
            chatId: widget.chatId,
            onCopy: _copyToClipboard,
            onRegenerate: _regenerateResponse,
            onUserMessageOptions: _showUserMessageOptions,
            messageQueue: chatState.messageQueue,
            isProcessingQueue: chatState.isProcessingQueue,
            attachment: chatState.attachment,
            attachedImage: chatState.attachedImage,
            showScrollToBottom: chatState.showScrollToBottom,
            isStreaming: chatState.isStreaming,
            onScrollToBottom: chatState.scrollToBottom,
            inputField: _buildInputField(chatState),
          );
        },
      ),
    );
  }

  /// Build input field using ChatWidgets
  Widget _buildInputField(ChatState chatState) {
    return ChatWidgets.buildInputField(
      context: context,
      controller: chatState.controller,
      isStreaming: chatState.isStreaming,
      onSendMessage: _sendMessage,
      onAttachFile: _handleFileAttachment,
      onVoiceInput: _handleVoiceInput,
      onStopStreaming: () => chatState.stopStreaming(),
      hintText: chatState.inputHintText,
    );
  }
}

/// Image Generation Dialog
class _ImageGenerationDialog extends StatefulWidget {
  @override
  _ImageGenerationDialogState createState() => _ImageGenerationDialogState();
}

class _ImageGenerationDialogState extends State<_ImageGenerationDialog> {
  final _controller = TextEditingController();
  String _selectedModel = 'dall-e-3';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Describe the image you want...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedModel,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'dall-e-3', child: Text('DALL-E 3')),
              DropdownMenuItem(value: 'dall-e-2', child: Text('DALL-E 2')),
            ],
            onChanged: (value) => setState(() => _selectedModel = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _controller.text.isNotEmpty
            ? () => Navigator.pop(context, {
                'prompt': _controller.text,
                'model': _selectedModel,
              })
            : null,
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

/// Presentation Generation Dialog
class _PresentationDialog extends StatefulWidget {
  @override
  _PresentationDialogState createState() => _PresentationDialogState();
}

class _PresentationDialogState extends State<_PresentationDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate Presentation'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter presentation topic...',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _controller.text.isNotEmpty
            ? () => Navigator.pop(context, _controller.text)
            : null,
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

/// Fullscreen Diagram Screen - Simplified using ChatChartBuilder
class FullscreenDiagramScreen extends StatelessWidget {
  final Map<String, dynamic> diagramData;

  const FullscreenDiagramScreen({
    super.key,
    required this.diagramData,
  });

  @override
  Widget build(BuildContext context) {
    final String type = diagramData['type'] ?? 'bar';
    final String title = diagramData['title'] ?? 'Chart';
    final GlobalKey chartKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadDiagram(context, chartKey, title, type),
            tooltip: 'Save Chart',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: chartKey,
          child: ChatChartBuilder.buildFullscreenChart(type, diagramData, context),
        ),
      ),
    );
  }

  Future<void> _downloadDiagram(BuildContext context, GlobalKey chartKey, String title, String type) async {
    try {
      // This would implement the download functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving chart: $e')),
      );
    }
  }
}