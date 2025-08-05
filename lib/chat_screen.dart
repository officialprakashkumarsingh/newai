import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ahamai/web_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'background_service.dart'; // Temporarily disabled

import 'ai_message_actions.dart';
import 'api.dart';
import 'api_service.dart';
import 'chat_ui_helpers.dart';
import 'file_processing.dart';
import 'main.dart';
import 'presentation_generator.dart';
import 'thinking_panel.dart';
// import 'social_sharing_service.dart'; // REMOVED: This service was slowing down the app.
import 'theme.dart';
// Removed duplicate imports - already exists above

class ChatScreen extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  final String? initialMessage;
  final String? chatId;
  final String? chatTitle;
  final bool isPinned;
  final bool isGenerating;
  final bool isStopped;
  final bool autoSend;
  final bool enableKeyboard;
  final StreamController<ChatInfo> chatInfoStream;

  const ChatScreen({super.key, this.initialMessages, this.initialMessage, this.chatId, this.chatTitle, this.isPinned = false, this.isGenerating = false, this.isStopped = false, this.autoSend = true, this.enableKeyboard = false, required this.chatInfoStream});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  String _currentModelResponse = '';
  bool _isStreaming = false;
  bool _isStoppedByUser = false;
  
  // GenerativeModel removed - now using ApiService

  String _selectedChatModel = ''; // Will be set from API
  bool _isModelSetupComplete = false;

  StreamSubscription? _streamSubscription;
  http.Client? _httpClient;

  final ValueNotifier<String> _codeStreamNotifier = ValueNotifier('');
  late String _chatId;
  late bool _isPinned;
  late String _chatTitle;
  late String _category; // OPTIMIZED: Store category locally to avoid re-calculation.
  bool _isWebSearchEnabled = false;
  bool _isThinkingModeEnabled = false;
  List<SearchResult>? _lastSearchResults;

  ChatAttachment? _attachment;
  XFile? _attachedImage;

  // Enhanced background processing variables
  String? _currentStreamingMessage;
  String? _currentStreamingChatId;
  Timer? _backgroundCheckTimer;
  Timer? _connectionHealthTimer;
  DateTime? _streamStartTime;
  Duration _backgroundCheckInterval = const Duration(seconds: 2);
  int _retryAttempts = 0;
  int _maxRetryAttempts = 3;
  bool _isInBackground = false;
  bool _streamPersistenceEnabled = true;
  
  // Background processing channel
  static const _backgroundChannel = MethodChannel('com.ahamai.background');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize background health monitoring
    _startConnectionHealthMonitoring();
    
    _messages = widget.initialMessages != null ? List.from(widget.initialMessages!) : [];
    _isPinned = widget.isPinned;
    _chatId = widget.chatId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _chatTitle = widget.chatTitle ?? "New Chat";
    _category = _determineCategory(_messages); // OPTIMIZED: Calculate category only once on init.
    
    if (_chatTitle == "New Chat" && _messages.isNotEmpty) {
      final firstUserMessage = _messages.firstWhere((m) => m.role == 'user', orElse: () => ChatMessage(role: 'user', text: ''));
      _chatTitle = firstUserMessage.text.length > 30 ? '${firstUserMessage.text.substring(0, 30)}...' : firstUserMessage.text.trim().isEmpty ? "New Chat" : firstUserMessage.text;
    }
    
    _isStreaming = widget.isGenerating;
    _isStoppedByUser = widget.isStopped;

    _initialize();
  }

  Future<void> _initialize() async {
    await _setupChatModel();
    _isModelSetupComplete = true;

    if (widget.initialMessage != null && mounted) {
      _controller.text = widget.initialMessage!;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Always focus keyboard for immediate typing
        _focusNode.requestFocus();
        
        // Auto-send if enabled (default behavior)
        if (widget.autoSend) {
          _sendMessage(widget.initialMessage!);
        }
      });
    } else if (widget.enableKeyboard && mounted) {
      // Enable keyboard even without initial message (from widget tap)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  Future<void> _setupChatModel() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedChatModel = prefs.getString('chat_model') ?? '';
    
    // Note: All model setup now handled by ApiService - no more direct Gemini setup
    // Note: Vision now uses ApiService with user's selected model

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    // _streamSubscription cleanup handled in lifecycle
    _httpClient?.close();
    _codeStreamNotifier.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String input) async {
    if (!_isModelSetupComplete || _isStreaming) return;
    if (input.trim().isEmpty && _attachment == null && _attachedImage == null) return;
    
    // REMOVED: The call to _handleSocialShare was here, removing it significantly improves performance.

    if (_attachedImage != null) {
      _sendVisionMessage(input, _attachedImage!);
    } else {
      _sendTextMessage(input);
    }
  }

  Future<void> _sendVisionMessage(String input, XFile imageFile) async {
    _isStoppedByUser = false;
    _lastSearchResults = null;
    final imageBytes = await imageFile.readAsBytes();
    final userMessage = ChatMessage(role: 'user', text: input, imageBytes: imageBytes);

    setState(() {
      _messages.add(userMessage);
      _messages.add(ChatMessage(role: 'model', text: ''));
      _isStreaming = true;
      _attachedImage = null;
      _currentModelResponse = '';
    });
    _controller.clear();
    _scrollToBottom();
    _updateChatInfo(true, false);

    try {
      // Use ApiService with user's selected model for vision
      await for (final chunk in ApiService.sendVisionMessage(
        message: input,
        imageBase64: base64Encode(imageBytes),
        model: _selectedChatModel, // Use user's selected model from popup
      )) {
        if (_isStoppedByUser) break;
        
        _currentModelResponse += chunk;
        setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: _currentModelResponse));
        _scrollToBottom();
      }
    } catch(e) {
      _onStreamingError(e);
    } finally {
      _onStreamingDone();
    }
  }

  Future<void> _sendTextMessage(String input) async {
    if (input.trim().isEmpty && _attachment != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please ask a question about the document.')));
      return;
    }

    _isStoppedByUser = false;
    _lastSearchResults = null;
    
    String finalInputForAI = input;
    if (_attachment != null) {
      finalInputForAI = """CONTEXT FROM THE FILE '${_attachment!.fileName}':
---
${_attachment!.content}
---
Based on the context above, answer the following prompt: $input""";
    }

    final userMessage = ChatMessage(
      role: 'user', 
      text: input,
      attachedFileName: _attachment?.fileName,
      attachedContainedFiles: _attachment?.containedFileNames,
    );
    
    setState(() {
      _messages.add(userMessage);
      _messages.add(ChatMessage(role: 'model', text: ''));
      _isStreaming = true;
      if (_chatTitle == "New Chat" || _chatTitle.trim().isEmpty) {
        _chatTitle = userMessage.text.length > 30 ? '${userMessage.text.substring(0, 30)}...' : userMessage.text;
      }
      // OPTIMIZED: Only recalculate the category if it's currently 'General'.
      if (_category == 'General') {
        _category = _determineCategory(_messages);
      }
      _attachment = null;
    });
    _controller.clear();
    _scrollToBottom();
    _updateChatInfo(true, false);

    // Enhanced state tracking
    _currentStreamingMessage = input;
    _currentStreamingChatId = widget.chatInfoStream.hashCode.toString();
    _streamStartTime = DateTime.now();
    _retryAttempts = 0;
    
    print('💾 Starting stream tracking: message=$input, chatId=$_currentStreamingChatId');

    String? webContext;
    if (_isWebSearchEnabled) {
      setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: 'Searching the web...'));
      _scrollToBottom();
      final searchResponse = await WebSearchService.search(input);
      if (searchResponse != null) {
        webContext = searchResponse.promptContent;
        _lastSearchResults = searchResponse.results;
      }
    }

    // Use the new ApiService for all models
    _sendOpenAICompatibleStream(finalInputForAI, webSearchResults: webContext);
  }
  


  Future<void> _sendOpenAICompatibleStream(String input, {String? webSearchResults}) async {
    setState(() {
      _messages[_messages.length - 1] = ChatMessage(role: 'model', text: '');
      _currentModelResponse = '';
    });
    _scrollToBottom();

    try {

      // Build conversation history for context
      final conversationHistory = _messages
          .where((m) => m.text.isNotEmpty)
          .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
          .toList();

      // System prompt with current capabilities
      final now = DateTime.now().toIso8601String();
      String systemPrompt = '''System Knowledge: 
1. Current date: $now
2. Screenshot Capability: You can generate website screenshots using the format: https://s0.wp.com/mshots/v1/https%3A%2F%2F[URL]?w=[WIDTH]&h=[HEIGHT]
   - Replace [URL] with the URL-encoded website address
   - Replace [WIDTH] and [HEIGHT] with desired dimensions (default: w=1280&h=720)
   - Example: https://s0.wp.com/mshots/v1/https%3A%2F%2Fgoogle.com?w=1280&h=720
   - The markdown renderer will automatically display these as images
   - Use this when users ask for website previews, screenshots, or visual representations of websites''';

      if (webSearchResults != null && webSearchResults.isNotEmpty) {
        systemPrompt += '\n3. Web Search Results: $webSearchResults';
      }

      // Use ApiService for streaming
      await for (final chunk in ApiService.sendChatMessage(
        message: input,
        model: _selectedChatModel,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
        isThinkingMode: _isThinkingModeEnabled,
      )) {
        if (_isStoppedByUser) break;
        
        _currentModelResponse += chunk;
        
        // Parse content to separate thinking and final content
        final parsedContent = ThinkingContentParser.parseContent(_currentModelResponse);
        final thinkingContent = parsedContent['thinking'];
        final finalContent = parsedContent['final'];
        
        setState(() => _messages[_messages.length - 1] = ChatMessage(
          role: 'model', 
          text: finalContent ?? _currentModelResponse,
          thinkingContent: thinkingContent?.isNotEmpty == true ? thinkingContent : null,
        ));
        _scrollToBottom();
       }
    } catch (e) {
      _onStreamingError(e);
    } finally {
      _onStreamingDone();
    }
  }




  
  void _onStreamingDone() {
    if (_lastSearchResults != null && _messages.isNotEmpty) {
      final lastMessage = _messages.last;
      _messages[_messages.length - 1] = ChatMessage(
        role: lastMessage.role,
        text: lastMessage.text,
        type: lastMessage.type,
        imageUrl: lastMessage.imageUrl,
        slides: lastMessage.slides,
        searchResults: _lastSearchResults,
      );
      _lastSearchResults = null;
    }
    
    _setupChatModel(); 
    setState(() => _isStreaming = false);
    _updateChatInfo(false, false);
    _scrollToBottom();

    // Clear enhanced tracking
    print('✅ Stream completed, clearing tracking state');
    _currentStreamingMessage = null;
    _currentStreamingChatId = null;
    _streamStartTime = null;
    _retryAttempts = 0;
    // Stream cleanup handled automatically
  }

  void _onStreamingError(dynamic error) {
    setState(() {
      _messages[_messages.length - 1] = ChatMessage(role: 'model', text: '❌ Error: $error');
      _isStreaming = false;
    });
    _updateChatInfo(false, false);
    _scrollToBottom();
  }
  
  void _updateChatInfo(bool isGenerating, bool isStopped) {
    final chatInfo = ChatInfo(id: _chatId, title: _chatTitle, messages: List.from(_messages), isPinned: _isPinned, isGenerating: isGenerating, isStopped: isStopped, category: _category);
    widget.chatInfoStream.add(chatInfo);
  }

  void _stopStreaming() {
    // Stream cancellation handled naturally by Flutter
    _httpClient?.close();
    setState(() {
      _isStreaming = false;
      _isStoppedByUser = true;
    });
    _updateChatInfo(false, true);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1)));
  }

  void _regenerateResponse(int userMessageIndex) {
    if (userMessageIndex < 0 || userMessageIndex >= _messages.length) return;
    final userMessage = _messages[userMessageIndex];
    if (userMessage.role != 'user') return;
    setState(() => _messages.removeRange(userMessageIndex + 1, _messages.length));
    if (userMessage.imageBytes != null) {
      _sendVisionMessage(userMessage.text, XFile.fromData(userMessage.imageBytes!, name: 'image.jpg'));
    } else {
      _sendTextMessage(userMessage.text);
    }
  }

  void _showUserMessageOptions(BuildContext context, ChatMessage message, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.copy_outlined), title: const Text('Copy Message'), onTap: () { Navigator.pop(context); _copyToClipboard(message.text); }),
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Edit and Resend'), onTap: () { Navigator.pop(context); setState(() { _controller.text = message.text; _messages.removeRange(index, _messages.length); _stopStreaming(); }); }),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image != null) setState(() { _attachedImage = image; _attachment = null; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickAndProcessFile() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processing file...'), duration: Duration(seconds: 20)));
    try {
      final attachment = await FileProcessingService.pickAndProcessFile();
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (attachment != null) {
        setState(() { _attachment = attachment; _attachedImage = null; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text('"${attachment.fileName}" uploaded and ready.'))]), backgroundColor: isLightTheme(context) ? Colors.black87 : draculaCurrentLine, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: EdgeInsets.only(left: 12, right: 12, bottom: 90 + MediaQuery.of(context).viewInsets.bottom)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
      }
    }
  }

  void _showToolsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FileSourceButton(icon: Icons.camera_alt_outlined, label: 'Camera', onTap: () => _pickImage(ImageSource.camera)),
                  FileSourceButton(icon: Icons.photo_library_outlined, label: 'Photos', onTap: () => _pickImage(ImageSource.gallery)),
                  FileSourceButton(icon: Icons.folder_open_outlined, label: 'Files', onTap: _pickAndProcessFile),
                ],
              ),
              const Divider(height: 32),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.public), title: const Text('Search the web'), trailing: Switch(value: _isWebSearchEnabled, onChanged: (bool value) { setSheetState(() => _isWebSearchEnabled = value); setState(() => _isWebSearchEnabled = value); })),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.auto_awesome_outlined), title: const Text('Think for longer'), trailing: Switch(value: _isThinkingModeEnabled, onChanged: (bool value) { setSheetState(() => _isThinkingModeEnabled = value); setState(() => _isThinkingModeEnabled = value); })),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.image_outlined), title: const Text('Create an image'), onTap: () { Navigator.pop(context); _showImagePromptBottomSheet(); }),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.slideshow_outlined), title: const Text('Make a presentation'), onTap: () { Navigator.pop(context); _showPresentationPromptDialog(); }),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePromptBottomSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => ImagePromptSheet(onGenerate: _generateImage));
  }

  Future<void> _generateImage(String prompt, String? model) async {
    final userMessage = ChatMessage(role: 'user', text: prompt);
    final placeholderMessage = ChatMessage(role: 'model', text: 'Generating image...', type: MessageType.image, imageUrl: null);
    
    setState(() { 
      _messages.add(userMessage); 
      _messages.add(placeholderMessage); 
    });
    _scrollToBottom();
    final int placeholderIndex = _messages.length - 1;

    try {
      // Use the new OpenAI-compatible image generation API
      final imageUrl = await ImageApi.generateImage(prompt, model: model);
      
      // Download image bytes for save functionality
      print('🖼️ Downloading image bytes from: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      final imageBytes = response.statusCode == 200 ? response.bodyBytes : null;
      print('💾 ImageBytes length: ${imageBytes?.length ?? 'null'}');
      
      final imageMessage = ChatMessage(
        role: 'model', 
        text: 'Image for: $prompt', 
        type: MessageType.image, 
        imageUrl: imageUrl,
        imageBytes: imageBytes
      );
      print('📱 Message created with imageBytes: ${imageMessage.imageBytes != null}');
      
      // Precache the image
      await precacheImage(NetworkImage(imageUrl), context);
      if (mounted) setState(() => _messages[placeholderIndex] = imageMessage);
    } catch(e) {
      if (mounted) {
        setState(() => _messages[placeholderIndex] = ChatMessage(
          role: 'model', 
          text: '❌ Failed to generate image: ${e.toString()}', 
          type: MessageType.text
        ));
      }
    } finally {
      _updateChatInfo(false, false);
    }
  }
  
  void _showPresentationPromptDialog() {
    final TextEditingController promptController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Presentation Topic'),
      content: TextField(controller: promptController, autofocus: true, decoration: const InputDecoration(hintText: 'e.g., The History of Space Exploration'), onSubmitted: (topic) { if (topic.trim().isNotEmpty) { Navigator.of(context).pop(); _generatePresentation(topic); } }),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { final topic = promptController.text; if (topic.trim().isNotEmpty) { Navigator.of(context).pop(); _generatePresentation(topic); } }, child: const Text('Generate')),
      ],
    ));
  }

  Future<void> _generatePresentation(String topic) async {
    _messages.add(ChatMessage(role: 'user', text: topic));
    _messages.add(ChatMessage(role: 'model', text: 'Generating presentation...', type: MessageType.presentation, slides: null));
    final int placeholderIndex = _messages.length - 1;
    setState(() {});
    _scrollToBottom();

          final slides = await PresentationGenerator.generateSlides(topic, selectedModel: _selectedChatModel);
    if (!mounted) return;
    if (slides.isNotEmpty) {
      setState(() => _messages[placeholderIndex] = ChatMessage(role: 'model', text: 'Presentation ready: $topic', type: MessageType.presentation, slides: slides));
      Navigator.push(context, MaterialPageRoute(builder: (context) => PresentationViewScreen(slides: slides, topic: topic)));
    } else {
      setState(() => _messages[placeholderIndex] = ChatMessage(role: 'model', text: 'Could not generate presentation for "$topic". Please try again.', type: MessageType.text));
    }
    _updateChatInfo(false, false);
  }

  Widget _buildMessage(ChatMessage message, int index) {
    switch (message.type) {
      case MessageType.image:
        if (message.imageUrl == null) {
          return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Text('Generating image...'), const SizedBox(width: 12), GeneratingIndicator(size: 16)])));
        } else {
          return Align(
            alignment: Alignment.centerLeft, 
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), 
              constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250), 
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12), 
                    child: Image.network(
                      message.imageUrl!, 
                      fit: BoxFit.cover, 
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), 
                      errorBuilder: (context, error, stack) => const Icon(Icons.error)
                    )
                  ),
                  // Add save button for generated images
                  if (message.role == 'model' && message.imageBytes != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _saveImage(message.imageBytes!),
                            child: Icon(
                              Icons.download,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      case MessageType.presentation:
        return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: message.slides == null ? Row(mainAxisSize: MainAxisSize.min, children: [const Text('Generating presentation...'), const SizedBox(width: 12), GeneratingIndicator(size: 16)]) : InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PresentationViewScreen(slides: message.slides!, topic: message.text.replaceFirst('Presentation ready: ', '')))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.slideshow, size: 20), const SizedBox(width: 12), Flexible(child: Text(message.text, style: const TextStyle(fontWeight: FontWeight.bold)))]))));
      case MessageType.text:
      default:
        final isModelMessage = message.role == 'model';
        if (isModelMessage) {
          if (message.text.isEmpty && _isStreaming && index == _messages.length - 1) return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: const GeneratingIndicator()));
          if (message.text == 'Searching the web...' || message.text == 'Thinking deeply...') return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(message.text), const SizedBox(width: 12), GeneratingIndicator(size: 16)])));
          final bool showActionButtons = (!_isStreaming || index != _messages.length - 1) && !_isStoppedByUser;
          return Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: message.thinkingContent != null && message.thinkingContent!.isNotEmpty ? ThinkingPanel(thinkingContent: message.thinkingContent!, finalContent: message.text) : MarkdownBody(data: message.text, selectable: true, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)))), if (isModelMessage && message.searchResults != null && message.searchResults!.isNotEmpty) _buildSearchResultsWidget(message.searchResults!), if (showActionButtons && message.text.isNotEmpty && !message.text.startsWith('❌ Error:')) AiMessageActions(key: ValueKey('actions_${_chatId}_$index'), messageText: message.text, onCopy: () => _copyToClipboard(message.text), onRegenerate: () => _regenerateResponse(index - 1))]));
        }
        
        final isDark = !isLightTheme(context);
                  final userMessageStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isLightTheme(context) 
                  ? Colors.white  // Light mode: white text on dark bubble
                  : Colors.white // Dark mode: white text on dark bubble
            ),
                      code: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: isLightTheme(context) 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              color: Colors.white // White text for code in both modes
            ),
        );

        return GestureDetector(
          onLongPress: () => _showUserMessageOptions(context, message, index),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                  color: isLightTheme(context)
                    ? const Color(0xFF0F0F10) // Near black bubble for light mode - high contrast
                    : const Color(0xFF2C2C2E), // Dark mode: Card Background
                  borderRadius: BorderRadius.circular(16)
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageBytes != null)
                    Builder(
                      builder: (context) {
                        final showSaveButton = message.type == MessageType.image && message.role == 'model';
                        print('💾 Image detected: type=${message.type}, role=${message.role}, showSave=$showSaveButton');
                        return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0), 
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          maxWidth: double.infinity,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12), 
                              child: Image.memory(
                                message.imageBytes!, 
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            ),
                            if (showSaveButton)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => _saveImage(message.imageBytes!),
                                      child: Icon(
                                        Icons.download,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                        ); // Close Builder
                      },
                    ),
                  
                  if (message.attachedFileName != null)
                    _FileAttachmentInMessage(message: message, isDark: isDark),
                  
                  if (message.text.isNotEmpty)
                    MarkdownBody(data: message.text, selectable: false, styleSheet: userMessageStyle),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildSearchResultsWidget(List<SearchResult> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 22, top: 8, bottom: 8), child: Text("Sources", style: Theme.of(context).textTheme.titleSmall)),
        SizedBox(height: 90, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8), itemCount: results.length, itemBuilder: (context, index) => SearchResultCard(result: results[index]))),
      ],
    );
  }

  Widget _FileAttachmentInMessage({ required ChatMessage message, required bool isDark, }) {
    final hasContainedFiles = message.attachedContainedFiles != null && message.attachedContainedFiles!.isNotEmpty;
    final icon = hasContainedFiles ? Icons.folder_zip_outlined : Icons.description_outlined;
    final textColor = isDark ? draculaBackground : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: textColor.withOpacity(0.8)),
              const SizedBox(width: 8),
              Flexible(child: Text(message.attachedFileName!, style: TextStyle(fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (hasContainedFiles)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: textColor.withOpacity(0.8),
                collapsedIconColor: textColor.withOpacity(0.8),
                tilePadding: const EdgeInsets.only(left: 28, right: 8),
                title: Text('${message.attachedContainedFiles!.length} files', style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.9))),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: message.attachedContainedFiles!.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(left: 28, right: 8, top: 2, bottom: 2),
                        child: Text(message.attachedContainedFiles![index], style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8), fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if(message.text.isNotEmpty)
            Container(height: 1, color: textColor.withOpacity(0.2), margin: const EdgeInsets.only(top: 8)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chatTitle), centerTitle: true),
      extendBody: true, // Extend body behind system navigation bar
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), itemCount: _messages.length, itemBuilder: (context, index) => _buildMessage(_messages[index], index)),
          ),
          if (_attachment != null)
            AttachmentPreview(attachment: _attachment!, onClear: () => setState(() => _attachment = null)),
          if (_attachedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Stack(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_attachedImage!.path), height: 100, width: 100, fit: BoxFit.cover)),
                  Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => _attachedImage = null), child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 20)))),
                ],
              ),
            ),
          Container(
            margin: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isLightTheme(context) 
                  ? const Color(0xFFE8EAED) // Light mode: Google search bar background
                  : const Color(0xFF2C2C2E), // Dark mode: Card Background
              borderRadius: BorderRadius.circular(28), // Fully rounded corners
              border: Border.all(
                                  color: isLightTheme(context) 
                      ? const Color(0xFFE8EAED) // Google search bar background for light mode
                      : const Color(0xFF333438), // Secondary Background for dark mode
                width: 1,
              ),
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
                IconButton(icon: const Icon(Icons.apps_outlined), onPressed: _isStreaming ? null : _showToolsBottomSheet, tooltip: 'Tools', color: _isStreaming ? Theme.of(context).disabledColor : Theme.of(context).iconTheme.color),
                Expanded(
                  child: TextField(
                    controller: _controller, 
                    enabled: !_isStreaming, 
                    onSubmitted: _isStreaming ? null : (val) => _sendMessage(val), 
                    textInputAction: TextInputAction.send, 
                    maxLines: 5, 
                    minLines: 1, 
                    style: TextStyle(
                      color: isLightTheme(context) ? const Color(0xFF0F0F10) : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: _isStreaming ? 'AhamAI is responding...' : 'Ask AhamAI anything...', 
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
                CircleAvatar(backgroundColor: _isStreaming ? Colors.red : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}), radius: 24, child: IconButton(icon: Icon(_isStreaming ? Icons.stop : Icons.arrow_upward, color: Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({})), onPressed: _isStreaming ? _stopStreaming : () => _sendMessage(_controller.text))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced app lifecycle detection with multiple triggers
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    print('🔄 App lifecycle: $state | streaming: $_isStreaming | message: $_currentStreamingMessage');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _handleAppGoingBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppReturningForeground();
        break;
      case AppLifecycleState.inactive:
        // Mark as potentially going to background
        Future.delayed(Duration(milliseconds: 500), () {
          if (_isStreaming && _currentStreamingMessage != null) {
            print('⚠️ App inactive during streaming - preparing for background transfer');
            _prepareBackgroundTransfer();
          }
        });
        break;
      default:
        print('🔄 Other lifecycle state: $state');
        break;
    }
  }

  /// Handle app going to background with multiple strategies
  void _handleAppGoingBackground() {
    print('📱 App going to background...');
    _isInBackground = true;
    
    if (_isStreaming && _currentStreamingMessage != null) {
      print('🚀 Initiating robust background transfer...');
      
      // Strategy 1: Immediate transfer
      _transferToBackgroundProcessing();
      
      // Strategy 2: Start monitoring timer as backup
      _startBackgroundMonitoring();
      
      // Strategy 3: Persist stream state
      if (_streamPersistenceEnabled) {
        _persistStreamState();
      }
    }
  }

  /// Handle app returning to foreground
  void _handleAppReturningForeground() {
    print('📱 App returning to foreground...');
    _isInBackground = false;
    
    // Stop background monitoring
    _backgroundCheckTimer?.cancel();
    
    // Check for completed background results
    _checkBackgroundResult();
    
    // Restore any persisted streams if needed
    _restoreStreamStateIfNeeded();
  }

  /// Start background monitoring as a fallback strategy
  void _startBackgroundMonitoring() {
    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer = Timer.periodic(_backgroundCheckInterval, (timer) {
      if (!_isInBackground) {
        timer.cancel();
        return;
      }
      
      print('🔍 Background monitoring check...');
      _checkBackgroundResult();
    });
  }

  /// Persist stream state for recovery
  void _persistStreamState() {
    if (_currentStreamingMessage == null) return;
    
    try {
      final streamState = {
        'message': _currentStreamingMessage!,
        'chatId': _currentStreamingChatId ?? widget.chatInfoStream.hashCode.toString(),
        'model': _selectedChatModel,
        'startTime': _streamStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'retryAttempts': _retryAttempts,
      };
      
      // Save to local storage (implement as needed)
      print('💾 Persisting stream state: $streamState');
      
    } catch (e) {
      print('❌ Failed to persist stream state: $e');
    }
  }

  /// Restore stream state if needed
  void _restoreStreamStateIfNeeded() {
    // Implementation for restoring persisted stream state
    print('🔄 Checking for persisted stream state...');
  }

  /// Prepare for background transfer (called on inactive state)
  void _prepareBackgroundTransfer() {
    if (_currentStreamingMessage != null) {
      // Pre-warm the background service
      _backgroundChannel.invokeMethod('prepareBackgroundService', {
        'chatId': _currentStreamingChatId ?? widget.chatInfoStream.hashCode.toString(),
        'message': _currentStreamingMessage!,
        'model': _selectedChatModel,
      }).catchError((e) {
        print('⚠️ Failed to prepare background service: $e');
      });
    }
  }

  /// Enhanced background transfer with retry logic
  Future<void> _transferToBackgroundProcessing() async {
    if (_currentStreamingMessage == null) {
      print('⚠️ No streaming message to transfer');
      return;
    }
    
    try {
      print('🔄 Transferring to background (attempt ${_retryAttempts + 1}/$_maxRetryAttempts)');
      
      // Stop any existing stream
      // (existing Flutter streaming will be stopped naturally)
      
      // Update UI immediately
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: 'model', 
            text: '🔄 Continuing in background...\n⏳ Processing your request while you use other apps!\n📱 We\'ll notify you when ready!'
          );
        });
      }
      
      // Start native background service with enhanced parameters
      await _backgroundChannel.invokeMethod('startBackgroundProcessing', {
        'chatId': _currentStreamingChatId ?? widget.chatInfoStream.hashCode.toString(),
        'message': _currentStreamingMessage!,
        'model': _selectedChatModel,
        'processType': 'chat',
        'retryAttempts': _retryAttempts,
        'priority': 'high',
        'timeout': 300000, // 5 minutes
      });
      
      print('✅ Successfully transferred to background processing');
      _retryAttempts = 0; // Reset on success
      
    } catch (e) {
      print('❌ Failed to transfer to background (attempt ${_retryAttempts + 1}): $e');
      
      _retryAttempts++;
      if (_retryAttempts < _maxRetryAttempts) {
        // Exponential backoff retry
        final delay = Duration(seconds: (2 * _retryAttempts).clamp(1, 10));
        print('🔄 Retrying in ${delay.inSeconds}s...');
        
        Timer(delay, () {
          if (_isInBackground && _currentStreamingMessage != null) {
            _transferToBackgroundProcessing();
          }
        });
      } else {
        print('❌ Max retry attempts reached');
        _handleBackgroundTransferFailure();
      }
    }
  }

  /// Handle background transfer failure
  void _handleBackgroundTransferFailure() {
    if (mounted && _messages.isNotEmpty) {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          role: 'model', 
          text: '⚠️ Background processing failed.\nPlease stay in the app for best experience.'
        );
        _isStreaming = false;
      });
    }
    _currentStreamingMessage = null;
    _retryAttempts = 0;
  }

  /// Enhanced background result checking with better error handling
  Future<void> _checkBackgroundResult() async {
    try {
      final result = await _backgroundChannel.invokeMethod('getBackgroundResult');
      
      if (result != null && result is Map) {
        final content = result['content'] as String?;
        final success = result['success'] as bool? ?? false;
        final chatId = result['chatId'] as String?;
        
        print('📥 Background result received: success=$success, content length=${content?.length ?? 0}');
        
        if (content != null && content.isNotEmpty) {
          // Verify this result is for current chat
          final currentChatId = _currentStreamingChatId ?? widget.chatInfoStream.hashCode.toString();
          if (chatId == currentChatId || chatId == null) {
            
            // Update the UI with result
            if (mounted && _messages.isNotEmpty) {
              setState(() {
                _messages[_messages.length - 1] = ChatMessage(
                  role: 'model', 
                  text: success ? content : '❌ Background Error: $content'
                );
                _isStreaming = false;
              });
              _scrollToBottom();
            }
            
            // Clear streaming state
            _currentStreamingMessage = null;
            _currentStreamingChatId = null;
            _streamStartTime = null;
            _retryAttempts = 0;
            
            print('✅ Background result processed successfully');
          } else {
            print('⚠️ Background result chatId mismatch: expected $currentChatId, got $chatId');
          }
        }
      } else {
        print('📭 No background result available');
      }
    } catch (e) {
      print('❌ Failed to check background result: $e');
    }
  }

  /// Start connection health monitoring
  void _startConnectionHealthMonitoring() {
    _connectionHealthTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_isStreaming && _streamStartTime != null) {
        final elapsed = DateTime.now().difference(_streamStartTime!);
        if (elapsed.inMinutes > 5) { // 5 minutes timeout
          print('⏰ Stream timeout detected after ${elapsed.inMinutes} minutes');
          _handleStreamTimeout();
        }
      }
    });
  }

  /// Handle stream timeout
  void _handleStreamTimeout() {
    print('⏰ Handling stream timeout');
    
    if (_isInBackground && _currentStreamingMessage != null) {
      // Try to transfer to background if not already done
      _transferToBackgroundProcessing();
    } else {
      // Stop streaming and show timeout message
      if (mounted && _messages.isNotEmpty) {
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: 'model', 
            text: '⏰ Request timed out. Please try again.'
          );
          _isStreaming = false;
        });
      }
      _currentStreamingMessage = null;
    }
  }

  Future<void> _saveImage(Uint8List imageBytes) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required to save images')),
        );
        return;
      }

      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create AhamAI folder
      final ahamAIDir = Directory('${downloadsDir.path}/AhamAI');
      if (!await ahamAIDir.exists()) {
        await ahamAIDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'AhamAI_image_$timestamp.png';
      final filePath = '${ahamAIDir.path}/$fileName';

      // Save the image
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved to Downloads/AhamAI/$fileName'),
          action: SnackBarAction(
            label: 'Open Folder',
            onPressed: () {
              // Note: Opening folder programmatically requires additional permissions
              // For now, just show the path
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: $e')),
      );
    }
  }
}

String _determineCategory(List<ChatMessage> messages) {
  if (messages.isEmpty) return 'General';
  final userMessages = messages.where((m) => m.role == 'user').map((m) => m.text.toLowerCase()).join(' ');
  if (userMessages.contains('code') || userMessages.contains('programming') || userMessages.contains('debug') || userMessages.contains('flutter') || userMessages.contains('python')) return 'Coding';
  if (userMessages.contains('write') || userMessages.contains('poem') || userMessages.contains('story') || userMessages.contains('script') || userMessages.contains('lyrics')) return 'Creative';
  if (userMessages.contains('science') || userMessages.contains('physics') || userMessages.contains('biology') || userMessages.contains('chemistry') || userMessages.contains('astronomy')) return 'Science';
  if (userMessages.contains('health') || userMessages.contains('medical') || userMessages.contains('fitness') || userMessages.contains('diet') || userMessages.contains('wellness')) return 'Health';
  if (userMessages.contains('history') || userMessages.contains('ancient') || userMessages.contains('war') || userMessages.contains('historical')) return 'History';
  if (userMessages.contains('tech') || userMessages.contains('gadget') || userMessages.contains('software') || userMessages.contains('computer') || userMessages.contains('ai')) return 'Technology';
  if (userMessages.contains('plan') || userMessages.contains('trip') || userMessages.contains('schedule') || userMessages.contains('travel') || userMessages.contains('itinerary') || userMessages.contains('vacation')) return 'Travel & Plans';
  if (userMessages.contains('weather') || userMessages.contains('forecast') || userMessages.contains('temperature')) return 'Weather';
  if (userMessages.contains('fact') || userMessages.contains('trivia') || userMessages.contains('knowledge')) return 'Facts';
  return 'General';
}