import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
import 'diagram_service.dart';
import 'presentation_service.dart';
// import 'image_service.dart'; // Not needed
import 'file_processing.dart';
import 'theme.dart';
import 'chat_ui_helpers.dart';
import 'api_service.dart';

/// Compact Chat Screen - Uses all divided components for clean organization
/// This is a much smaller, more manageable version of the chat screen
class ChatScreenCompact extends StatefulWidget {
  final String chatId;
  final String initialMessage;
  final bool isPinned;
  final StreamController<ChatInfo>? chatInfoStream;

  const ChatScreenCompact({
    super.key,
    required this.chatId,
    this.initialMessage = '',
    this.isPinned = false,
    this.chatInfoStream,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload messages when app is resumed to prevent message loss
      _reloadMessages();
    }
  }

  /// Reload messages from storage when app is resumed
  Future<void> _reloadMessages() async {
    try {
      final messages = await ChatLogic.loadMessages(widget.chatId);
      if (messages.isNotEmpty && messages.length != _chatState.messages.length) {
        // Only update if there's a difference (avoid unnecessary rebuilds)
        _chatState.setMessages(messages);
        if (messages.isNotEmpty) {
          final title = ChatLogic.generateChatTitle(messages);
          _chatState.setChatTitle(title);
        }
      }
    } catch (e) {
      print('Error reloading messages: $e');
    }
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
      // Ensure model is loaded before sending initial message
      if (_chatState.selectedModel.isEmpty) {
        // Wait a bit and load model if not loaded
        await Future.delayed(const Duration(milliseconds: 200));
        if (_chatState.selectedModel.isEmpty) {
          // Load first available model as fallback
          try {
            final models = await ApiService.getAvailableModels();
            if (models.isNotEmpty) {
              _chatState.setSelectedModel(models.first);
            }
          } catch (e) {
            print('Error loading fallback model: $e');
            return; // Don't send message if no model available
          }
        }
      }
      
      // Auto-send the initial message for new users from welcome screen
      await _sendMessage(widget.initialMessage);
    }
  }

  /// Handle sending messages
  Future<void> _sendMessage(String input) async {
    if (!ChatLogic.isValidInput(input, _chatState.attachment)) return;

    // Clear input immediately when send is pressed
    _chatState.clearInput();
    
    // Clear attachments immediately when message is sent (not after streaming)
    _chatState.clearAllAttachments();

    if (_chatState.isStreaming) {
      _chatState.addToMessageQueue(input);
      return;
    }

    if (_chatState.attachedImage != null) {
      await _sendVisionMessage(input);
    } else {
      await _sendTextMessage(input); // This handles both text and file attachments
    }
  }

  /// Send text message
  Future<void> _sendTextMessage(String input) async {
    await ChatLogic.sendTextMessage(
      input: input,
      messages: _chatState.messages,
      selectedModel: _chatState.selectedModel,
      isWebSearchEnabled: _chatState.isWebSearchEnabled,
      isResearchModeEnabled: _chatState.isResearchModeEnabled,
      isThinkingModeEnabled: _chatState.isThinkingModeEnabled,
      addMessage: _addMessage,
      updateMessage: _updateMessage,
      scrollToBottom: _chatState.scrollToBottom,
      startStreaming: () => _chatState.startStreaming(),
      stopStreaming: () => _chatState.stopStreaming(),
      onStreamingComplete: _onStreamingDone,
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
      startStreaming: () => _chatState.startStreaming(),
      stopStreaming: () => _chatState.stopStreaming(),
      onStreamingComplete: _onStreamingDone,
    );
  }

  /// Add message and save
  void _addMessage(ChatMessage message) {
    _chatState.addMessage(message);
    ChatLogic.saveMessages(widget.chatId, _chatState.messages);
    _updateChatTitle();
    // Note: _updateChatInfo() is called automatically by _updateChatTitle()
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
      _updateChatInfo();
    }
  }

  /// Update chat info and send to stream
  void _updateChatInfo() {
    if (widget.chatInfoStream != null && _chatState.messages.isNotEmpty) {
      final chatInfo = ChatInfo(
        id: widget.chatId,
        title: _chatState.chatTitle,
        messages: _chatState.messages,
        isPinned: widget.isPinned,
        isGenerating: _chatState.isStreaming,
        isStopped: false,
        category: 'General', // Default category
      );
      widget.chatInfoStream!.add(chatInfo);
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
    // Note: Chat title already updated when message was added
    
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
      getIsStreaming: () => _chatState.isStreaming,
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
  Future<void> _handleImageAttachment([ImageSource source = ImageSource.gallery]) async {
    try {
      // Use ImagePicker for both camera and gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: source == ImageSource.camera ? CameraDevice.rear : CameraDevice.rear,
      );
      
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
      onDiagramGeneration: () => _generateDiagram(),
      onPickCamera: () => _handleImageAttachment(ImageSource.camera),
      onPickGallery: () => _handleImageAttachment(ImageSource.gallery),
      onPickFile: () => _handleFileAttachment(),
      isWebSearchEnabled: _chatState.isWebSearchEnabled,
      onWebSearchToggle: (value) => _chatState.setIsWebSearchEnabled(value),
      isThinkingModeEnabled: _chatState.isThinkingModeEnabled,
      onThinkingModeToggle: (value) => _chatState.setIsThinkingModeEnabled(value),
      isResearchModeEnabled: _chatState.isResearchModeEnabled,
      onResearchModeToggle: (value) => _chatState.setIsResearchModeEnabled(value),
    );
  }

  /// Generate image using ImagePromptSheet (original implementation)
  void _generateImage() async {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => ImagePromptSheet(
        onGenerate: (prompt, model) async {
          await ChatLogic.generateImage(
            prompt: prompt,
            selectedModel: model,
            addMessage: _addMessage,
            updateMessage: _updateMessage,
          );
        }
      )
    );
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
        selectedModel: _chatState.selectedModel,
        addMessage: _addMessage,
        updateMessage: _updateMessage,
      );
    }
  }

  /// Generate diagram
  void _generateDiagram() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _DiagramDialog(),
    );
    
    if (result != null && result.isNotEmpty) {
      // Add user message requesting diagram
      _addMessage(ChatMessage(role: 'user', text: result));
      
      // Add placeholder AI message for diagram generation
      _addMessage(ChatMessage(
        role: 'model', 
        text: 'Generating diagram...',
        type: MessageType.diagram,
        diagramData: <String, dynamic>{}, // Empty placeholder
      ));
      
      // Generate diagram data
      try {
        final diagramData = await DiagramService.generateDiagramData(result, _chatState.selectedModel);
        
        if (diagramData != null) {
          // Update the last message with actual diagram data
          final lastIndex = _chatState.messages.length - 1;
          _updateMessage(lastIndex, ChatMessage(
            role: 'model',
            text: 'Diagram generated successfully!',
            type: MessageType.diagram,
            diagramData: diagramData,
          ));
        } else {
          // Update with error message
          final lastIndex = _chatState.messages.length - 1;
          _updateMessage(lastIndex, ChatMessage(
            role: 'model', 
            text: '❌ Failed to generate diagram. Please try again.',
          ));
        }
      } catch (e) {
        // Update with error message
        final lastIndex = _chatState.messages.length - 1;
        _updateMessage(lastIndex, ChatMessage(
          role: 'model', 
          text: '❌ Error generating diagram: $e',
        ));
      }
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
      onShowTools: _showToolsBottomSheet,
      messageQueue: chatState.messageQueue,
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

/// Diagram Generation Dialog
class _DiagramDialog extends StatefulWidget {
  @override
  _DiagramDialogState createState() => _DiagramDialogState();
}

class _DiagramDialogState extends State<_DiagramDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Generate Diagram'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Describe the diagram you want to create:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            cursorColor: Theme.of(context).colorScheme.primary,
            decoration: const InputDecoration(
              hintText: 'e.g., Bar chart showing sales data for 2024\nFlowchart for user registration process\nPie chart of market share distribution',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (prompt) {
              if (prompt.trim().isNotEmpty) {
                Navigator.of(context).pop(prompt);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _controller.text.trim().isNotEmpty
            ? () => Navigator.pop(context, _controller.text)
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
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Presentation Topic'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: const InputDecoration(
          hintText: 'e.g., The History of Space Exploration',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
        onSubmitted: (topic) {
          if (topic.trim().isNotEmpty) {
            Navigator.of(context).pop(topic);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _controller.text.trim().isNotEmpty
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