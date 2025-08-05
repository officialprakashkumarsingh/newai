import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ahamai/web_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ai_message_actions.dart';
import 'api.dart';
import 'chat_ui_helpers.dart';
import 'file_processing.dart';
import 'main.dart';
import 'presentation_generator.dart';
// import 'social_sharing_service.dart'; // REMOVED: This service was slowing down the app.
import 'theme.dart';

class ChatScreen extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  final String? initialMessage;
  final String? chatId;
  final String? chatTitle;
  final bool isPinned;
  final bool isGenerating;
  final bool isStopped;
  final StreamController<ChatInfo> chatInfoStream;

  const ChatScreen({super.key, this.initialMessages, this.initialMessage, this.chatId, this.chatTitle, this.isPinned = false, this.isGenerating = false, this.isStopped = false, required this.chatInfoStream});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  String _currentModelResponse = '';
  bool _isStreaming = false;
  bool _isStoppedByUser = false;
  
  GenerativeModel? _geminiModel;
  GenerativeModel? _geminiVisionModel;
  ChatSession? _geminiChat;
  String _selectedChatModel = ChatModels.gemini;
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

  @override
  void initState() {
    super.initState();
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
      _sendMessage(widget.initialMessage!);
    }
  }

  Future<void> _setupChatModel() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedChatModel = prefs.getString('chat_model') ?? ChatModels.gemini;
    
    _geminiModel = GenerativeModel(model: ApiConfig.geminiChatModel, apiKey: ApiConfig.geminiApiKey);
    _geminiVisionModel = GenerativeModel(model: ApiConfig.geminiVisionModel, apiKey: ApiConfig.geminiApiKey);
    final history = _messages.where((m) => m.type == MessageType.text && m.imageBytes == null).map((m) => Content(m.role == 'user' ? 'user' : 'model', [TextPart(m.text)])).toList();
    _geminiChat = _geminiModel!.startChat(history: history);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
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
    });
    _controller.clear();
    _scrollToBottom();
    _updateChatInfo(true, false);

    try {
      final content = [Content.multi([TextPart(input), DataPart('image/jpeg', imageBytes)])];
      final responseStream = _geminiVisionModel!.generateContentStream(content);
      _streamSubscription = responseStream.listen(
        (chunk) {
          if (_isStoppedByUser) { _streamSubscription?.cancel(); return; }
          _currentModelResponse += chunk.text ?? '';
          setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: _currentModelResponse));
          _scrollToBottom();
        },
        onDone: _onStreamingDone,
        onError: _onStreamingError,
        cancelOnError: true,
      );
    } catch(e) {
      _onStreamingError(e);
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

    final isNewStreamingModel = [
      ChatModels.grok_3,
      ChatModels.grok_3_mini,
      ChatModels.grok_3_fast,
      ChatModels.grok_3_mini_fast,
      ChatModels.claude_4_sonnet,
    ].contains(_selectedChatModel);

    if (_isThinkingModeEnabled || isNewStreamingModel) {
      _sendOpenAICompatibleStream(finalInputForAI, webSearchResults: webContext);
    } else if (_selectedChatModel == ChatModels.gemini) {
      _sendMessageGemini(finalInputForAI, webSearchResults: webContext);
    } else {
      _sendMessagePollinations(finalInputForAI, webSearchResults: webContext);
    }
  }
  
  String _buildHistoryContext() {
    if (_messages.length <= 1) return "";
    final history = _messages.sublist(0, _messages.length - 1);
    return history.map((m) => "${m.role == 'user' ? 'User' : 'AI'}: ${m.text}").join('\n');
  }

  Future<void> _sendOpenAICompatibleStream(String input, {String? webSearchResults}) async {
    setState(() {
      _messages[_messages.length - 1] = ChatMessage(role: 'model', text: '');
      _currentModelResponse = '';
    });
    _scrollToBottom();

    _httpClient = http.Client();
    try {
      String apiUrl;
      String apiKey;
      String modelName;

      if (_isThinkingModeEnabled) {
        apiUrl = ApiConfig.openRouterChatUrl;
        apiKey = ApiConfig.openRouterApiKey;
        modelName = ApiConfig.openRouterModel;
      } else {
        switch (_selectedChatModel) {
          case ChatModels.grok_3:
          case ChatModels.grok_3_mini:
          case ChatModels.grok_3_fast:
          case ChatModels.grok_3_mini_fast:
            apiUrl = '${ApiConfig.grokApiBaseUrl}/chat/completions';
            apiKey = ApiConfig.grokApiKey;
            modelName = _selectedChatModel;
            break;
          case ChatModels.claude_4_sonnet:
            apiUrl = '${ApiConfig.claudeApiBaseUrl}/chat/completions';
            apiKey = ApiConfig.claudeApiKey;
            modelName = _selectedChatModel;
            break;
          default:
            _onStreamingError('Model not configured for OpenAI-compatible streaming.');
            return;
        }
      }

      final now = DateTime.now().toIso8601String();
      String finalPrompt = """System Knowledge: 
1. Current date: $now
2. Screenshot Capability: You can generate website screenshots using the format: https://s0.wp.com/mshots/v1/https%3A%2F%2F[URL]?w=[WIDTH]&h=[HEIGHT]
   - Replace [URL] with the URL-encoded website address
   - Replace [WIDTH] and [HEIGHT] with desired dimensions (default: w=1280&h=720)
   - Example: https://s0.wp.com/mshots/v1/https%3A%2F%2Fgoogle.com?w=1280&h=720
   - The markdown renderer will automatically display these as images
   - Use this when users ask for website previews, screenshots, or visual representations of websites

User Prompt: $input""";
      if (webSearchResults != null && webSearchResults.isNotEmpty) {
        finalPrompt = """Use the following context to answer the user's prompt.\n---\nCONTEXT:\n1. Current Date: $now\n2. Web Search Results:\n$webSearchResults\n---\nUSER PROMPT:\n$input""";
      }

      final history = _messages.map((m) { return {"role": m.role == 'user' ? "user" : "assistant", "content": m.text}; }).toList();
      history.removeLast();
      history.add({"role": "user", "content": finalPrompt});

      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers.addAll({'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'})
        ..body = jsonEncode({'model': modelName, 'messages': history, 'stream': true});

      final response = await _httpClient!.send(request);
      
      String buffer = '';
      _streamSubscription = response.stream.transform(utf8.decoder).listen(
        (chunk) {
          if (_isStoppedByUser) { _streamSubscription?.cancel(); return; }
          buffer += chunk;
          while (true) {
            final lineEnd = buffer.indexOf('\n');
            if (lineEnd == -1) break;
            final line = buffer.substring(0, lineEnd).trim();
            buffer = buffer.substring(lineEnd + 1);
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') return;
              try {
                final parsed = jsonDecode(data);
                final content = parsed['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  _currentModelResponse += content;
                  setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: _currentModelResponse));
                   _scrollToBottom();
                }
              } catch (e) { /* Ignore incomplete chunks */ }
            }
          }
        },
        onDone: () { _httpClient?.close(); _onStreamingDone(); },
        onError: (error) { _httpClient?.close(); _onStreamingError(error); },
        cancelOnError: true,
      );
    } catch (e) {
      _httpClient?.close();
      _onStreamingError(e);
    }
  }

  void _sendMessageGemini(String input, {String? webSearchResults}) {
    try {
      setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: ''));
      _currentModelResponse = '';
      _scrollToBottom();

      String finalContent;
      final now = DateTime.now().toIso8601String();
      if (webSearchResults != null && webSearchResults.isNotEmpty) {
        finalContent = """Use the following context to answer the user's prompt.\n---\nCONTEXT:\n1. Current Date: $now\n2. Web Search Results:\n$webSearchResults\n3. Screenshot Capability: You can generate website screenshots using: https://s0.wp.com/mshots/v1/https%3A%2F%2F[URL]?w=[WIDTH]&h=[HEIGHT]\n---\nUSER PROMPT:\n$input""";
      } else {
        finalContent = """System Knowledge: 
1. Current date: $now
2. Screenshot Capability: You can generate website screenshots using the format: https://s0.wp.com/mshots/v1/https%3A%2F%2F[URL]?w=[WIDTH]&h=[HEIGHT]
   - Replace [URL] with the URL-encoded website address
   - Replace [WIDTH] and [HEIGHT] with desired dimensions (default: w=1280&h=720)
   - Example: https://s0.wp.com/mshots/v1/https%3A%2F%2Fgoogle.com?w=1280&h=720
   - The markdown renderer will automatically display these as images
   - Use this when users ask for website previews, screenshots, or visual representations of websites

User Prompt: $input""";
      }

      final responseStream = _geminiChat!.sendMessageStream(Content.text(finalContent));
      bool isCodeSheetShown = false;
      _streamSubscription = responseStream.listen(
        (chunk) {
          if (_isStoppedByUser) { _streamSubscription?.cancel(); return; }
          _currentModelResponse += chunk.text ?? '';
          setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: _currentModelResponse));
          if (_currentModelResponse.contains('```') && !isCodeSheetShown) {
            isCodeSheetShown = true;
            _codeStreamNotifier.value = '';
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).scaffoldBackgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => CodeStreamingSheet(notifier: _codeStreamNotifier));
            });
          }
          if (isCodeSheetShown) {
            final codeMatch = RegExp(r'```(?:\w+)?\n([\s\S]*?)(?:```|$)').firstMatch(_currentModelResponse);
            _codeStreamNotifier.value = codeMatch?.group(1) ?? '';
          }
          _scrollToBottom();
        },
        onDone: _onStreamingDone,
        onError: _onStreamingError,
        cancelOnError: true,
      );
    } catch (e) {
      _onStreamingError(e);
    }
  }

  Future<void> _sendMessagePollinations(String input, {String? webSearchResults}) async {
    try {
      setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: ''));
      _scrollToBottom();
      
      final historyContext = _buildHistoryContext();
      final now = DateTime.now().toIso8601String();
      String finalPrompt;
      if (webSearchResults != null && webSearchResults.isNotEmpty) {
        finalPrompt = """Conversation History:\n$historyContext\n---\nBased on this context:\nDate: $now\nWeb Results: $webSearchResults\n---\nAnswer this prompt: $input""";
      } else {
        finalPrompt = """Conversation History:\n$historyContext\n---\nCurrent date is $now. Answer: $input""";
      }

      final url = ApiConfig.getPollinationsChatUrl(finalPrompt, _selectedChatModel);
      final response = await http.get(Uri.parse(url));
      if (_isStoppedByUser) { _onStreamingDone(); return; }
      if (response.statusCode == 200) {
        final output = utf8.decode(response.bodyBytes);
        setState(() => _messages[_messages.length - 1] = ChatMessage(role: 'model', text: output.trim()));
      } else {
        _onStreamingError('Pollinations API Error: ${response.statusCode}');
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
    _streamSubscription?.cancel();
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
    final imageUrl = ImageApi.getImageUrl(prompt, model: model);
    final imageMessage = ChatMessage(role: 'model', text: 'Image for: $prompt', type: MessageType.image, imageUrl: imageUrl);
    final placeholderMessage = ChatMessage(role: 'model', text: 'Generating image...', type: MessageType.image, imageUrl: null);
    
    setState(() { _messages.add(userMessage); _messages.add(placeholderMessage); });
    _scrollToBottom();
    final int placeholderIndex = _messages.length - 1;

    try {
      await precacheImage(NetworkImage(imageUrl), context);
      if (mounted) setState(() => _messages[placeholderIndex] = imageMessage);
    } catch(e) {
      if (mounted) setState(() => _messages[placeholderIndex] = ChatMessage(role: 'model', text: '❌ Failed to load image.', type: MessageType.text));
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

    final slides = await PresentationGenerator.generateSlides(topic, ApiConfig.geminiApiKey);
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
          return Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(message.imageUrl!, fit: BoxFit.cover, loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stack) => const Icon(Icons.error)))));
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
          return Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: MarkdownBody(data: message.text, selectable: true, styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)))), if (isModelMessage && message.searchResults != null && message.searchResults!.isNotEmpty) _buildSearchResultsWidget(message.searchResults!), if (showActionButtons && message.text.isNotEmpty && !message.text.startsWith('❌ Error:')) AiMessageActions(key: ValueKey('actions_${_chatId}_$index'), messageText: message.text, onCopy: () => _copyToClipboard(message.text), onRegenerate: () => _regenerateResponse(index - 1))]));
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
                      ? const Color(0xFF333446) // New bubble color for light mode
                      : const Color(0xFF31363F), // Dark mode: match suggestion prompt background
                  borderRadius: BorderRadius.circular(16)
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageBytes != null)
                    Padding(padding: const EdgeInsets.only(bottom: 8.0), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(message.imageBytes!, height: 150))),
                  
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
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: isLightTheme(context) 
                  ? Colors.white // Light mode: pure white
                  : const Color(0xFF000000), // Dark mode: AMOLED black
            ), // Removed top border line
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
                      color: isLightTheme(context) ? Colors.black : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: _isStreaming ? 'AhamAI is responding...' : 'Ask AhamAI anything...', 
                      hintStyle: TextStyle(
                        color: isLightTheme(context) ? Colors.grey.shade600 : Colors.white.withOpacity(0.7),
                      ),
                      filled: true, 
                      fillColor: isLightTheme(context) 
                          ? Colors.white 
                          : const Color(0xFF31363F), // Dark mode: match suggestion prompt background
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32), 
                        borderSide: BorderSide.none
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32), 
                        borderSide: BorderSide(
                          color: isLightTheme(context) 
                              ? Colors.grey.shade300 
                              : Colors.grey.shade700,
                          width: 1
                        )
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32), 
                        borderSide: BorderSide(
                          color: isLightTheme(context) 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                          width: 1.5
                        )
                      )
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