import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'web_search.dart';
import 'file_processing.dart';
import 'api_service.dart';

/// Chat State Management - Manages all state variables and controllers for chat
/// This handles the state that was previously managed in _ChatScreenState
class ChatState extends ChangeNotifier {
  
  // Core chat data
  List<ChatMessage> _messages = [];
  String _chatTitle = 'New Chat';
  String _selectedModel = ''; // Will be loaded from SharedPreferences
  
  // UI controllers
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Streaming state
  bool _isStreaming = false;
  String _currentModelResponse = '';
  String _pendingStreamingContent = '';
  Timer? _streamingUpdateTimer;
  StreamSubscription<String>? _streamSubscription;
  Timer? _scrollDebounceTimer;
  
  // Message queue
  final List<String> _messageQueue = [];
  bool _isProcessingQueue = false;
  
  // UI state
  bool _showScrollToBottom = false;
  bool _isPinned = false;
  
  // Attachments
  ChatAttachment? _attachment;
  XFile? _attachedImage;
  
  // Search and research
  List<SearchResult>? _lastSearchResults;
  bool _isWebSearchEnabled = false;
  bool _isResearchModeEnabled = false;
  
  // Feature generation modes
  String? _activeFeature; // null, 'image', 'presentation', 'diagram'
  String _featureImageModel = '';
  
  // Settings
  String _chatId = '';
  
  // Getters
  List<ChatMessage> get messages => _messages;
  String get chatTitle => _chatTitle;
  String get selectedModel => _selectedModel;
  TextEditingController get controller => _controller;
  ScrollController get scrollController => _scrollController;
  FocusNode get focusNode => _focusNode;
  bool get isStreaming => _isStreaming;
  String get currentModelResponse => _currentModelResponse;
  String get pendingStreamingContent => _pendingStreamingContent;
  List<String> get messageQueue => _messageQueue;
  bool get isProcessingQueue => _isProcessingQueue;
  bool get showScrollToBottom => _showScrollToBottom;
  bool get isPinned => _isPinned;
  ChatAttachment? get attachment => _attachment;
  XFile? get attachedImage => _attachedImage;
  List<SearchResult>? get lastSearchResults => _lastSearchResults;
  bool get isWebSearchEnabled => _isWebSearchEnabled;
  bool get isResearchModeEnabled => _isResearchModeEnabled;
  String? get activeFeature => _activeFeature;
  String get featureImageModel => _featureImageModel;
  String get chatId => _chatId;
  
  // Setters
  void setChatId(String id) {
    _chatId = id;
    notifyListeners();
  }
  
  void setMessages(List<ChatMessage> messages) {
    _messages = messages;
    notifyListeners();
  }
  
  void setChatTitle(String title) {
    _chatTitle = title;
    notifyListeners();
  }
  
  void setSelectedModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_model', model);
    notifyListeners();
  }
  
  void setIsStreaming(bool streaming) {
    _isStreaming = streaming;
    notifyListeners();
  }
  
  void setCurrentModelResponse(String response) {
    _currentModelResponse = response;
    // Don't notify listeners for every chunk to avoid excessive rebuilds
  }
  
  void setPendingStreamingContent(String content) {
    _pendingStreamingContent = content;
    // Don't notify listeners for every chunk to avoid excessive rebuilds
  }
  
  void setStreamingUpdateTimer(Timer? timer) {
    _streamingUpdateTimer?.cancel();
    _streamingUpdateTimer = timer;
  }
  
  void setStreamSubscription(StreamSubscription<String>? subscription) {
    _streamSubscription?.cancel();
    _streamSubscription = subscription;
  }
  
  void setIsProcessingQueue(bool processing) {
    _isProcessingQueue = processing;
    notifyListeners();
  }
  
  void setShowScrollToBottom(bool show) {
    _showScrollToBottom = show;
    notifyListeners();
  }
  
  void setIsPinned(bool pinned) {
    _isPinned = pinned;
    notifyListeners();
  }
  
  void setAttachment(ChatAttachment? attachment) {
    _attachment = attachment;
    notifyListeners();
  }
  
  void setAttachedImage(XFile? image) {
    _attachedImage = image;
    notifyListeners();
  }
  
  void setLastSearchResults(List<SearchResult>? results) {
    _lastSearchResults = results;
    notifyListeners();
  }
  
  void setIsWebSearchEnabled(bool enabled) {
    _isWebSearchEnabled = enabled;
    notifyListeners();
  }
  
  void setIsResearchModeEnabled(bool enabled) {
    _isResearchModeEnabled = enabled;
    notifyListeners();
  }
  
  void setActiveFeature(String? feature) {
    _activeFeature = feature;
    notifyListeners();
  }
  
  void setFeatureImageModel(String model) {
    _featureImageModel = model;
    notifyListeners();
  }
  
  // Message operations
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
    
    // Auto-scroll when new messages are added
    if (_isStreaming || message.role == 'model') {
      // Delay scroll slightly to allow the widget to build
      Future.delayed(const Duration(milliseconds: 50), () {
        _autoScrollToBottom();
      });
    }
  }
  
  void updateMessage(int index, ChatMessage message) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = message;
      notifyListeners();
      
      // Auto-scroll during streaming to keep up with the growing message
      if (_isStreaming) {
        _debouncedAutoScroll();
      }
    }
  }
  
  void removeMessagesFrom(int index) {
    if (index >= 0 && index < _messages.length) {
      _messages.removeRange(index, _messages.length);
      notifyListeners();
    }
  }
  
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
  
  // Message queue operations
  void addToMessageQueue(String message) {
    _messageQueue.add(message);
    notifyListeners();
  }
  
  void removeFromMessageQueue(int index) {
    if (index >= 0 && index < _messageQueue.length) {
      _messageQueue.removeAt(index);
      notifyListeners();
    }
  }
  
  void clearMessageQueue() {
    _messageQueue.clear();
    notifyListeners();
  }
  
  // Scroll management
  void scrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
  
  // Auto-scroll optimized for streaming - smoother and faster
  void _autoScrollToBottom() {
    if (!_scrollController.hasClients) return;
    
    // During streaming, always scroll to keep up with new content
    // Use a shorter duration for smoother real-time scrolling
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }
  
  // Debounced auto-scroll for rapid streaming updates
  void _debouncedAutoScroll() {
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      _autoScrollToBottom();
    });
  }
  
  void updateScrollToBottomVisibility() {
    if (!_scrollController.hasClients) return;
    
    final isAtBottom = _scrollController.offset >= 
                      (_scrollController.position.maxScrollExtent - 100);
    
    if (_showScrollToBottom != !isAtBottom) {
      setShowScrollToBottom(!isAtBottom);
    }
  }
  
  // Streaming operations
  void startStreaming() {
    setIsStreaming(true);
    _currentModelResponse = '';
    _pendingStreamingContent = '';
  }
  
  void stopStreaming() {
    setIsStreaming(false);
    _streamingUpdateTimer?.cancel();
    _streamSubscription?.cancel();
    notifyListeners();
  }
  
  void resetStreamingContent() {
    _currentModelResponse = '';
    _pendingStreamingContent = '';
    _streamingUpdateTimer?.cancel();
  }
  
  // Input management
  void clearInput() {
    _controller.clear();
    notifyListeners();
  }
  
  void setInputText(String text) {
    _controller.text = text;
    notifyListeners();
  }
  
  // Attachment management
  void clearAttachment() {
    setAttachment(null);
  }
  
  void clearAttachedImage() {
    setAttachedImage(null);
  }
  
  void clearAllAttachments() {
    setAttachment(null);
    setAttachedImage(null);
  }
  
  // Chat management
  void updateChatInfo(bool isGenerating, bool isStopped) {
    // Update any chat-level information
    // This can be expanded based on specific needs
    notifyListeners();
  }
  
  void resetChatState() {
    clearMessages();
    clearMessageQueue();
    clearInput();
    clearAllAttachments();
    setLastSearchResults(null);
    stopStreaming();
    setChatTitle('New Chat');
    // Model will be loaded from SharedPreferences in _loadSelectedModel()
    _loadSelectedModel();
    setIsWebSearchEnabled(false);
    setIsResearchModeEnabled(false);
    setShowScrollToBottom(false);
    setIsProcessingQueue(false);
  }
  
  // Initialize chat with data
  void initializeChat({
    required String chatId,
    required List<ChatMessage> initialMessages,
    String? title,
    bool? isPinned,
  }) {
    setChatId(chatId);
    setMessages(initialMessages);
    if (title != null) setChatTitle(title);
    if (isPinned != null) setIsPinned(isPinned);
    
    // Setup scroll listener
    _scrollController.addListener(updateScrollToBottomVisibility);
    
    // Load model from SharedPreferences
    _loadSelectedModel();
  }

  /// Load selected model from SharedPreferences (like original)
  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedModel = prefs.getString('chat_model') ?? '';
    
    if (_selectedModel.isEmpty) {
      try {
        final models = await ApiService.getAvailableModels();
        if (models.isNotEmpty) {
          _selectedModel = models.first;
          await prefs.setString('chat_model', _selectedModel);
        }
      } catch (e) {
        print('Error loading default model: $e');
        _selectedModel = 'gpt-4'; // Fallback
      }
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _streamingUpdateTimer?.cancel();
    _streamSubscription?.cancel();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }
  
  // Helper methods
  bool get hasMessages => _messages.isNotEmpty;
  bool get hasAttachments => _attachment != null || _attachedImage != null;
  bool get canSendMessage => !_isStreaming && (!_isProcessingQueue || _messageQueue.isEmpty);
  
  // Get current input text
  String get currentInput => _controller.text.trim();
  
  // Check if input is valid
  bool get isInputValid => currentInput.isNotEmpty || hasAttachments;
  
  // Get hint text for input field
  String get inputHintText {
    if (_isStreaming) {
      return _messageQueue.isEmpty 
        ? 'AI is responding...' 
        : 'Queued: ${_messageQueue.length} messages';
    }
    return 'Type your message...';
  }
  
  // Get last user message
  ChatMessage? get lastUserMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        return _messages[i];
      }
    }
    return null;
  }
  
  // Get last AI message
  ChatMessage? get lastAIMessage {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'model') {
        return _messages[i];
      }
    }
    return null;
  }
  
  // Check if we should show action buttons for a message
  bool shouldShowActionButtons(int index) {
    return index > 0 && 
           index < _messages.length && 
           _messages[index].role == 'model' &&
           _messages[index].text.isNotEmpty &&
           !_messages[index].text.startsWith('❌ Error:');
  }
  
  // Get display title (truncated if needed)
  String get displayTitle {
    return _chatTitle.length > 30 
      ? '${_chatTitle.substring(0, 27)}...' 
      : _chatTitle;
  }
}