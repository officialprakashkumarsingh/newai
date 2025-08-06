import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:ahamai/web_search.dart';
import 'package:ahamai/diagram_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
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

class _ChatScreenState extends State<ChatScreen> {
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
  // Category system removed
  bool _isWebSearchEnabled = false;
  bool _isThinkingModeEnabled = false;

  List<SearchResult>? _lastSearchResults;

  ChatAttachment? _attachment;
  XFile? _attachedImage;

  // Removed background processing variables

  @override
  void initState() {
    super.initState();
    
    _messages = widget.initialMessages != null ? List.from(widget.initialMessages!) : [];
    _isPinned = widget.isPinned;
    _chatId = widget.chatId ?? DateTime.now().millisecondsSinceEpoch.toString();
    _chatTitle = widget.chatTitle ?? "New Chat";
    // Category calculation removed
    
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
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
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
          // Category system removed
      _attachment = null;
    });
    _controller.clear();
    _scrollToBottom();
    _updateChatInfo(true, false);

    // Store message for processing
    print('💾 Processing message: $input');

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

    // Stream completed
    print('✅ Stream completed successfully');
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
    final chatInfo = ChatInfo(id: _chatId, title: _chatTitle, messages: List.from(_messages), isPinned: _isPinned, isGenerating: isGenerating, isStopped: isStopped, category: 'General');
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
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.bar_chart_outlined), title: const Text('Generate diagram'), onTap: () { Navigator.pop(context); _showDiagramPromptDialog(); }),

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

  void _showDiagramPromptDialog() {
    final TextEditingController promptController = TextEditingController();
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
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
              controller: promptController, 
              autofocus: true, 
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Bar chart showing sales data for 2024\nFlowchart for user registration process\nPie chart of market share distribution',
                border: OutlineInputBorder(),
              ), 
              onSubmitted: (prompt) { 
                if (prompt.trim().isNotEmpty) { 
                  Navigator.of(context).pop(); 
                  _generateDiagram(prompt); 
                } 
              }
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { 
              final prompt = promptController.text; 
              if (prompt.trim().isNotEmpty) { 
                Navigator.of(context).pop(); 
                _generateDiagram(prompt); 
              } 
            }, 
            child: const Text('Generate')
          ),
        ],
      )
    );
  }

  Future<void> _generateDiagram(String prompt) async {
    _messages.add(ChatMessage(role: 'user', text: prompt));
    _messages.add(ChatMessage(role: 'model', text: 'Generating diagram...', type: MessageType.diagram, diagramData: null));
    final int placeholderIndex = _messages.length - 1;
    setState(() {});
    _scrollToBottom();

    try {
      // Generate diagram data using DiagramService
      final diagramData = await DiagramService.generateDiagramData(prompt, _selectedChatModel);
      if (!mounted) return;
      
      if (diagramData != null) {
        setState(() => _messages[placeholderIndex] = ChatMessage(
          role: 'model', 
          text: 'Diagram ready: $prompt', 
          type: MessageType.diagram, 
          diagramData: diagramData
        ));
      } else {
        setState(() => _messages[placeholderIndex] = ChatMessage(
          role: 'model', 
          text: 'Could not generate diagram for "$prompt". Please try again.', 
          type: MessageType.text
        ));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _messages[placeholderIndex] = ChatMessage(
        role: 'model', 
        text: 'Error generating diagram: $error', 
        type: MessageType.text
      ));
    }
    
    _updateChatInfo(false, false);
  }

  Future<Map<String, dynamic>?> _generateDiagramData(String prompt) async {
    try {
      print('Starting diagram generation for: $prompt');
      
      // Collect the complete AI response from the stream
      String fullResponse = '';
      await for (final chunk in ApiService.sendChatMessage(
        message: '''Create structured data for this diagram request: "$prompt"

IMPORTANT: Respond with ONLY a valid JSON object (no markdown, no explanation, no extra text).

For bar/line/pie/doughnut charts, use this exact format:
{
  "type": "bar",
  "title": "Your Chart Title",
  "data": [
    {"label": "Category 1", "value": 25},
    {"label": "Category 2", "value": 35},
    {"label": "Category 3", "value": 40}
  ]
}

For scatter charts, use this format:
{
  "type": "scatter",
  "title": "Scatter Plot Title",
  "data": [
    {"x": 10, "y": 20, "label": "Point 1"},
    {"x": 15, "y": 30, "label": "Point 2"},
    {"x": 25, "y": 15, "label": "Point 3"}
  ]
}

For radar charts, use this format:
{
  "type": "radar",
  "title": "Performance Analysis",
  "data": [
    {"category": "Speed", "value": 80},
    {"category": "Accuracy", "value": 95},
    {"category": "Efficiency", "value": 70}
  ]
}

For flowcharts, use this exact format:
{
  "type": "flowchart",
  "title": "Process Title",
  "steps": [
    {"id": "start", "text": "Start", "type": "start"},
    {"id": "step1", "text": "Step 1", "type": "process"},
    {"id": "end", "text": "End", "type": "end"}
  ],
  "connections": [
    {"from": "start", "to": "step1"},
    {"from": "step1", "to": "end"}
  ]
}

Valid types: "bar", "line", "pie", "doughnut", "scatter", "radar", "area", "flowchart"
Generate realistic data relevant to: $prompt''',
        model: _selectedChatModel,
      )) {
        fullResponse += chunk;
      }

      print('AI Response: $fullResponse');
      
      // Clean the response - remove markdown formatting if present
      String cleanResponse = fullResponse.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      
      cleanResponse = cleanResponse.trim();
      print('Cleaned Response: $cleanResponse');

      // Parse the JSON response
      final jsonData = json.decode(cleanResponse);
      print('Parsed JSON: $jsonData');
      
      // Validate the response structure
      if (jsonData is Map<String, dynamic> && 
          jsonData.containsKey('type') && 
          jsonData.containsKey('title')) {
        return jsonData;
      } else {
        throw Exception('Invalid response structure from AI');
      }
      
    } catch (error) {
      print('Error generating diagram data: $error');
      // Don't use fallback - return null to show error
      return null;
    }
  }

  Widget _buildDiagramWidget(Map<String, dynamic> diagramData) {
    final String type = diagramData['type'] ?? 'bar';
    final String title = diagramData['title'] ?? 'Chart';
    final GlobalKey chartKey = GlobalKey();

    // Calculate flexible height based on chart type and data
    double getFlexibleHeight() {
      final List<dynamic> data = diagramData['data'] ?? diagramData['steps'] ?? [];
      switch (type.toLowerCase()) {
        case 'flowchart':
          return math.max(150, math.min(400, data.length * 60.0));
        case 'radar':
          return 300; // Fixed for radar
        case 'pie':
        case 'doughnut':
          return 280; // Fixed for circular charts
        default:
          return math.max(200, math.min(450, data.length * 40.0 + 100));
      }
    }

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getChartIcon(type),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'download':
                        await DiagramService.downloadDiagram(chartKey, title, type, diagramData, context);
                        break;
                      case 'fullscreen':
                        _showFullscreenDiagram(diagramData);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 8),
                          Text('Download as Image'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'fullscreen',
                      child: Row(
                        children: [
                          Icon(Icons.fullscreen),
                          SizedBox(width: 8),
                          Text('View Fullscreen'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Flexible sizing without fixed background container
            RepaintBoundary(
              key: chartKey,
              child: Container(
                height: getFlexibleHeight(),
                width: double.infinity,
                // Remove background color and decoration for clean diagram export
                child: _buildOptimizedChart(type, diagramData),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap menu for download & fullscreen options',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String type, Map<String, dynamic> diagramData) {
    switch (type.toLowerCase()) {
      case 'bar':
        return _buildBarChart(diagramData);
      case 'line':
        return _buildLineChart(diagramData);
      case 'pie':
        return _buildPieChart(diagramData);
      case 'doughnut':
        return _buildDoughnutChart(diagramData);
      case 'scatter':
        return _buildScatterChart(diagramData);
      case 'radar':
        return _buildRadarChart(diagramData);
      case 'area':
        return _buildAreaChart(diagramData);
      case 'flowchart':
        return _buildFlowChart(diagramData);
      default:
        return _buildBarChart(diagramData);
    }
  }

  Widget _buildBarChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['value'] as num).toDouble(),
                color: Colors.lightBlueAccent,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num).toDouble();
          final double total = data.fold(0.0, (sum, item) => sum + (item['value'] as num));
          final double percentage = (value / total) * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlowChart(Map<String, dynamic> diagramData) {
    final List<dynamic> steps = diagramData['steps'] ?? [];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final step = entry.value;
          final isLast = entry.key == steps.length - 1;
          
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getFlowChartStepColor(step['type']),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  step['text'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getFlowChartStepColor(String? type) {
    switch (type) {
      case 'start': return Colors.green;
      case 'end': return Colors.red;
      case 'decision': return Colors.orange;
      case 'process':
      default: return Colors.blue;
    }
  }

  Widget _getChartIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bar': return const Icon(Icons.bar_chart, size: 20);
      case 'line': return const Icon(Icons.show_chart, size: 20);
      case 'pie': case 'doughnut': return const Icon(Icons.pie_chart, size: 20);
      case 'scatter': return const Icon(Icons.scatter_plot, size: 20);
      case 'radar': return const Icon(Icons.radar, size: 20);
      case 'area': return const Icon(Icons.area_chart, size: 20);
      case 'flowchart': return const Icon(Icons.account_tree, size: 20);
      default: return const Icon(Icons.bar_chart, size: 20);
    }
  }

  Widget _buildOptimizedChart(String type, Map<String, dynamic> diagramData) {
    // Use FutureBuilder to prevent UI freezing
    return FutureBuilder<Widget>(
      future: _buildChartAsync(type, diagramData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error rendering chart: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return snapshot.data ?? const Center(child: Text('Failed to render chart'));
      },
    );
  }

  Future<Widget> _buildChartAsync(String type, Map<String, dynamic> diagramData) async {
    // Run chart building in a separate isolate to prevent freezing
    return Future.microtask(() => _buildChart(type, diagramData));
  }



  Widget _buildDoughnutChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 80, // Larger center for doughnut effect
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num).toDouble();
          final double total = data.fold(0.0, (sum, item) => sum + (item['value'] as num));
          final double percentage = (value / total) * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScatterChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.map((item) {
              final x = (item['x'] as num?)?.toDouble() ?? 0;
              final y = (item['y'] as num?)?.toDouble() ?? 0;
              return FlSpot(x, y);
            }).toList(),
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    // Simple radar chart implementation using CustomPaint
    return CustomPaint(
      size: const Size(250, 250),
      painter: RadarChartPainter(data),
    );
  }

  Widget _buildAreaChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.6),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDiagram(GlobalKey chartKey, String title, String type) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing diagram for download...')),
      );

      // Get the render object
      final RenderRepaintBoundary boundary = 
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image with high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Get file name
      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${type}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      // Save to downloads
      await _saveImageToDownloads(pngBytes, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagram saved as $fileName')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving diagram: $error')),
      );
    }
  }

  Future<void> _saveImageToDownloads(Uint8List bytes, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory!.parent.parent.parent.parent.path}/Download';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsBytes(bytes);
    } catch (error) {
      // Fallback to app directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
    }
  }

  void _showFullscreenDiagram(Map<String, dynamic> diagramData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenDiagramScreen(diagramData: diagramData),
      ),
    );
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
      case MessageType.diagram:
        return Align(
          alignment: Alignment.centerLeft, 
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), 
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), 
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, 
              borderRadius: BorderRadius.circular(16)
            ), 
            child: message.diagramData == null 
              ? Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    const Text('Generating diagram...'), 
                    const SizedBox(width: 12), 
                    GeneratingIndicator(size: 16)
                  ]
                ) 
              : DiagramService.buildDiagramWidget(message.diagramData!, context, (data) {})
          )
        );
      case MessageType.text:
      default:
        final isModelMessage = message.role == 'model';
        if (isModelMessage) {
          if (message.text.isEmpty && _isStreaming && index == _messages.length - 1) return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: const GeneratingIndicator()));
          if (message.text == 'Searching the web...' || message.text == 'Thinking deeply...') return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(message.text), const SizedBox(width: 12), GeneratingIndicator(size: 16)])));
          final bool showActionButtons = (!_isStreaming || index != _messages.length - 1) && !_isStoppedByUser;
          return Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: message.thinkingContent != null && message.thinkingContent!.isNotEmpty ? ThinkingPanel(thinkingContent: message.thinkingContent!, finalContent: message.text) : _buildMessageContent(message.text)), if (isModelMessage && message.searchResults != null && message.searchResults!.isNotEmpty) _buildSearchResultsWidget(message.searchResults!), if (showActionButtons && message.text.isNotEmpty && !message.text.startsWith('❌ Error:')) AiMessageActions(key: ValueKey('actions_${_chatId}_$index'), messageText: message.text, onCopy: () => _copyToClipboard(message.text), onRegenerate: () => _regenerateResponse(index - 1))]));
        }
        
        final isDark = !isLightTheme(context);

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
                    SelectableText(
                      message.text,
                      style: TextStyle(color: Colors.white),
                    ),
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

  // Removed background processing lifecycle methods

  // Background processing methods removed

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

    // Categories removed - no longer needed

     // Agent feature removed as requested

  Widget _buildMessageContent(String text) {
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<dynamic> data;
  
  RadarChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw radar grid
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
    }

    // Draw axes
    final angleStep = 2 * 3.14159 / data.length;
    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - 3.14159 / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }

    // Draw data points
    final dataPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dataPath = Path();
    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - 3.14159 / 2;
      final value = (data[i]['value'] as num?)?.toDouble() ?? 0;
      final normalizedValue = (value / 100) * radius;
      
      final point = Offset(
        center.dx + normalizedValue * math.cos(angle),
        center.dy + normalizedValue * math.sin(angle),
      );
      
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);

    // Draw data point circles
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - 3.14159 / 2;
      final value = (data[i]['value'] as num?)?.toDouble() ?? 0;
      final normalizedValue = (value / 100) * radius;
      
      final point = Offset(
        center.dx + normalizedValue * math.cos(angle),
        center.dy + normalizedValue * math.sin(angle),
      );
      
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FullscreenDiagramScreen extends StatelessWidget {
  final Map<String, dynamic> diagramData;

  const FullscreenDiagramScreen({super.key, required this.diagramData});

  @override
  Widget build(BuildContext context) {
    final String type = diagramData['type'] ?? 'bar';
    final String title = diagramData['title'] ?? 'Chart';
    final GlobalKey chartKey = GlobalKey();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFullscreenDiagram(context, chartKey, title, type),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RepaintBoundary(
            key: chartKey,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildFullscreenChart(type, diagramData),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenChart(String type, Map<String, dynamic> diagramData) {
    switch (type.toLowerCase()) {
      case 'bar':
        return _buildFullscreenBarChart(diagramData);
      case 'line':
        return _buildFullscreenLineChart(diagramData);
      case 'pie':
        return _buildFullscreenPieChart(diagramData);
      case 'doughnut':
        return _buildFullscreenDoughnutChart(diagramData);
      case 'scatter':
        return _buildFullscreenScatterChart(diagramData);
      case 'radar':
        return _buildFullscreenRadarChart(diagramData);
      case 'area':
        return _buildFullscreenAreaChart(diagramData);
      case 'flowchart':
        return _buildFullscreenFlowChart(diagramData);
      default:
        return _buildFullscreenBarChart(diagramData);
    }
  }

  Widget _buildFullscreenBarChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x]['label']}\n${rod.toY.round()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['value'] as num).toDouble(),
                color: Colors.lightBlueAccent,
                width: 30,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Add other fullscreen chart methods (simplified for brevity)
  Widget _buildFullscreenLineChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenPieChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenDoughnutChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenScatterChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenRadarChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenAreaChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);
  Widget _buildFullscreenFlowChart(Map<String, dynamic> data) => _buildFullscreenBarChart(data);

  Future<void> _downloadFullscreenDiagram(BuildContext context, GlobalKey chartKey, String title, String type) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading fullscreen diagram...')),
      );

      final RenderRepaintBoundary boundary = 
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${type}_fullscreen_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory!.parent.parent.parent.parent.path}/Download';
      final file = File('$downloadsPath/$fileName');
      await file.writeAsBytes(pngBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fullscreen diagram saved as $fileName')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving diagram: $error')),
      );
    }
  }
}