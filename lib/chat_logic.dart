import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'api_service.dart';
import 'api.dart';

import 'diagram_handler.dart';

import 'web_search.dart';
import 'presentation_service.dart';
import 'global_system_prompt.dart';

/// Chat Logic - Contains all business logic methods from chat_screen.dart
/// This handles message processing, API calls, and data management
class ChatLogic {
  
  /// Initialize chat settings and model
  static Future<void> initializeChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('first_time') ?? true;
      
      if (isFirstTime) {
        await prefs.setBool('first_time', false);
        // Any first-time setup logic
      }
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  /// Setup chat model configuration
  static Future<void> setupChatModel() async {
    try {
      // Model setup logic if needed
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('Error setting up chat model: $e');
    }
  }

  /// Load messages from storage
  static Future<List<ChatMessage>> loadMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('chat_$chatId');
      if (messagesJson != null) {
        return messagesJson
            .map((jsonString) => ChatMessage.fromJson(jsonDecode(jsonString)))
            .toList();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
    return [];
  }

  /// Save messages to storage and sync with HomeScreen chat data
  static Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save individual chat messages (existing system)
      final messagesJson = messages.map((message) => jsonEncode(message.toJson())).toList();
      await prefs.setStringList('chat_$chatId', messagesJson);
      
      // SYNC WITH HOMESCREEN: Update the main chats data
      await _syncWithHomeScreenChats(chatId, messages, prefs);
      
      print('💾 CHAT LOGIC: Saved ${messages.length} messages for chat $chatId');
    } catch (e) {
      print('Error saving messages: $e');
    }
  }
  
  /// Sync individual chat messages with HomeScreen's main chat data
  static Future<void> _syncWithHomeScreenChats(String chatId, List<ChatMessage> messages, SharedPreferences prefs) async {
    try {
      // Load existing chats from HomeScreen storage
      final chatData = prefs.getString('chats');
      List<Map<String, dynamic>> chats = [];
      
      if (chatData != null) {
        final List<dynamic> decoded = jsonDecode(chatData);
        chats = decoded.cast<Map<String, dynamic>>();
      }
      
      // Find and update the specific chat
      bool chatFound = false;
      for (int i = 0; i < chats.length; i++) {
        if (chats[i]['id'] == chatId) {
          chats[i]['messages'] = messages.map((m) => m.toJson()).toList();
          chatFound = true;
          print('🔄 SYNC: Updated existing chat $chatId with ${messages.length} messages');
          break;
        }
      }
      
      // If chat not found and has messages, create new chat entry
      if (!chatFound && messages.isNotEmpty) {
        final newChat = {
          'id': chatId,
          'title': generateChatTitle(messages),
          'messages': messages.map((m) => m.toJson()).toList(),
          'isPinned': false,
          'isGenerating': false,
          'isStopped': false,
          'category': 'General'
        };
        chats.add(newChat);
        print('➕ SYNC: Created new chat entry $chatId with ${messages.length} messages');
      }
      
      // Save back to HomeScreen storage
      final updatedChatData = jsonEncode(chats);
      await prefs.setString('chats', updatedChatData);
      
    } catch (e) {
      print('Error syncing with HomeScreen chats: $e');
    }
  }

  /// Process a chat message and handle streaming response
  static Future<void> sendChatMessage({
    required String input,
    required List<ChatMessage> messages,
    required String selectedModel,
    required bool isWebSearchEnabled,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required Function() scrollToBottom,
    required Function() startStreaming,
    required Function() stopStreaming,
  }) async {
    print('🚀 CHAT LOGIC: Starting sendChatMessage');
    print('🚀 CHAT LOGIC: Input: ${input.substring(0, math.min(100, input.length))}...');
    print('🚀 CHAT LOGIC: Selected Model: $selectedModel');
    print('🚀 CHAT LOGIC: Messages count: ${messages.length}');
    
    if (selectedModel.isEmpty) {
      print('❌ CHAT LOGIC: No model selected!');
      stopStreaming();
      addMessage(ChatMessage(role: 'model', text: '❌ Error: No AI model selected. Please select a model from settings.'));
      return;
    }
    
    if (input.trim().isEmpty) {
      print('❌ CHAT LOGIC: Empty input!');
      return;
    }

    // Add user message
    final userMessage = ChatMessage(
      role: 'user',
      text: input,
    );
    addMessage(userMessage);

    // Add placeholder AI response
    addMessage(ChatMessage(role: 'model', text: ''));
    scrollToBottom();

    try {
      String finalInputForAI = input;

      // Handle web search if enabled
      String? webSearchResults;
      if (isWebSearchEnabled) {
        webSearchResults = await handleWebSearch(input);
      }

      // Start streaming state
      startStreaming();

      // Stream AI response
      print('📤 CHAT LOGIC: About to call _streamAIResponse');
      await _streamAIResponse(
        input: input,
        messages: messages,
        selectedModel: selectedModel,
        webSearchResults: null, // We'll handle web search later
        updateMessage: updateMessage,
      );
      
      // Stop streaming state
      print('🛑 CHAT LOGIC: Stopping streaming');
      stopStreaming();
      
    } catch (e) {
      // Stop streaming on error
      print('❌ CHAT LOGIC: Error in sendChatMessage: $e');
      stopStreaming();
      addMessage(ChatMessage(role: 'model', text: '❌ Error: $e'));
    }
  }

  /// Send vision message with image
  static Future<void> sendVisionMessage({
    required String input,
    required XFile imageFile,
    required List<ChatMessage> messages,
    required String selectedModel,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required Function() scrollToBottom,
    required Function() startStreaming,
    required Function() stopStreaming,
    Function()? onStreamingComplete,
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final userMessage = ChatMessage(
      role: 'user',
      text: input,
      imageBytes: imageBytes,
    );
    addMessage(userMessage);
    addMessage(ChatMessage(role: 'model', text: ''));
    scrollToBottom();

    try {
      // Start streaming state
      startStreaming();
      
      await for (final chunk in ApiService.sendVisionMessage(
        message: input,
        imageBase64: base64.encode(imageBytes),
        model: selectedModel,
      )) {
        final lastIndex = messages.length - 1;
        final currentText = messages[lastIndex].text + chunk;
        updateMessage(lastIndex, ChatMessage(role: 'model', text: currentText));
      }
      
      // Stop streaming state
      stopStreaming();
      
      // Notify completion
      if (onStreamingComplete != null) {
        onStreamingComplete();
      }
    } catch (e) {
      // Stop streaming on error
      stopStreaming();
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $e'));
      
      // Notify completion even on error
      if (onStreamingComplete != null) {
        onStreamingComplete();
      }
    }
  }

  /// Handle web search
  static Future<String?> handleWebSearch(String input) async {
    try {
      final searchResponse = await WebSearchService.search(input);
      if (searchResponse != null && searchResponse.results.isNotEmpty) {
        final context = searchResponse.results.take(3).map((r) => 
          'Title: ${r.title}\nContent: ${r.snippet}\nURL: ${r.url}'
        ).join('\n\n');
        return 'Web search results for "$input":\n\n$context\n\n';
      }
    } catch (e) {
      print('Web search error: $e');
    }
    return null;
  }

  /// Format search results for AI context
  static String formatSearchResultsForAI(List<SearchResult> results) {
    if (results.isEmpty) return "";
    
    final buffer = StringBuffer();
    buffer.writeln("🔍 **SEARCH RESULTS CONTEXT**:");
    buffer.writeln("Based on recent web search, here's current information:");
    buffer.writeln();
    
    for (int i = 0; i < results.length && i < 5; i++) {
      final result = results[i];
      buffer.writeln("**${i + 1}. ${result.title}**");
      buffer.writeln("Source: ${result.url}");
      buffer.writeln("${result.snippet}");
      buffer.writeln();
    }
    
    buffer.writeln("---");
    return buffer.toString();
  }

  /// Handle web search functionality

  /// Stream AI response with enhanced thinking content parsing
  static Future<void> _streamAIResponse({
    required String input,
    required List<ChatMessage> messages,
    required String selectedModel,
    required Function(int, ChatMessage) updateMessage,
    String? webSearchResults,
  }) async {
    String finalInputForAI = input;
    
    if (webSearchResults != null) {
      finalInputForAI = webSearchResults + input;
    }

    final conversationHistory = buildConversationHistory(messages);

    // Use the new global system prompt with comprehensive capabilities
    String systemPrompt = GlobalSystemPrompt.getGlobalSystemPrompt(
      includeTools: false, // No more function calling
    );
    
    String fullResponse = '';
    
    print('📡 CHAT LOGIC: About to call ApiService.sendChatMessage');
    print('📡 CHAT LOGIC: Model: $selectedModel');
    print('📡 CHAT LOGIC: Has conversation history: ${conversationHistory != null && conversationHistory.isNotEmpty}');
    print('📡 CHAT LOGIC: System prompt length: ${systemPrompt.length}');
    
    try {
      await for (final chunk in ApiService.sendChatMessage(
        message: finalInputForAI,
        model: selectedModel,
        conversationHistory: conversationHistory,
        systemPrompt: systemPrompt,
      )) {
        print('📨 CHAT LOGIC: Received chunk: ${chunk.substring(0, math.min(50, chunk.length))}...');
        final lastIndex = messages.length - 1;
        fullResponse += chunk;
        
        // Update the streaming message directly with accumulated response
        final updatedMessage = ChatMessage(
          role: 'model',
          text: fullResponse,
        );
        
        updateMessage(lastIndex, updatedMessage);
      }
      print('✅ CHAT LOGIC: Streaming completed successfully');
    } catch (e) {
      print('❌ CHAT LOGIC: Error in streaming: $e');
      final lastIndex = messages.length - 1;
      final errorMessage = ChatMessage(
        role: 'model',
        text: '❌ Error: Failed to get AI response. $e',
      );
      updateMessage(lastIndex, errorMessage);
    }
  }



  /// Build conversation history for API (last 10 messages for AI memory)
  static List<Map<String, dynamic>>? buildConversationHistory(List<ChatMessage> messages) {
    // Filter out empty messages and take only the last 10 for memory efficiency
    final filteredMessages = messages
        .where((m) => m.text.isNotEmpty && m.text.trim().isNotEmpty)
        .toList();
    
    // Take the last 10 messages to give AI memory of recent conversation
    final recentMessages = filteredMessages.length > 10 
        ? filteredMessages.sublist(filteredMessages.length - 10)
        : filteredMessages;
    
    final conversationHistory = recentMessages
        .map((m) => {
          'role': m.role == 'user' ? 'user' : 'assistant', 
          'content': m.text.trim()
        })
        .toList();
    
    return conversationHistory.isNotEmpty ? conversationHistory : null;
  }

  /// Handle streaming completion
  static Future<void> onStreamingDone({
    required List<ChatMessage> messages,
    required String selectedModel,
    required List<SearchResult>? lastSearchResults,
    required DiagramHandler diagramHandler,
  }) async {
    if (messages.isEmpty) return;

    final lastMessage = messages.last;
    if (lastMessage.role != 'model') return;

    try {
      // Automatic diagram detection removed - use bottom sheet instead

      // Update search results if available
      if (lastSearchResults != null && lastSearchResults.isNotEmpty) {
        // This would be handled by the parent widget
      }
    } catch (e) {
      print('Error in streaming completion: $e');
    }
  }

  /// Handle streaming errors
  static void onStreamingError(dynamic error, List<ChatMessage> messages, Function(int, ChatMessage) updateMessage) {
    if (messages.isNotEmpty) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $error'));
    }
  }

  /// Process message queue
  static Future<void> processMessageQueue({
    required List<String> messageQueue,
    required bool isProcessingQueue,
    required Function() getIsStreaming,
    required Function(String) sendTextMessage,
    required Function(bool) setProcessingQueue,
    required Function() updateUI,
  }) async {
    if (messageQueue.isEmpty || isProcessingQueue || getIsStreaming()) return;

    setProcessingQueue(true);

    while (messageQueue.isNotEmpty && !getIsStreaming()) {
      final nextMessage = messageQueue.removeAt(0);
      updateUI(); // Update UI to show queue count change

      // Send the next message
      await sendTextMessage(nextMessage);

      // Wait for streaming to complete
      while (getIsStreaming()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    setProcessingQueue(false);
  }

  /// Generate chat title from messages
  static String generateChatTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'New Chat';
    
    final userMessages = messages.where((m) => m.role == 'user').toList();
    final aiMessages = messages.where((m) => m.role == 'model').toList();
    
    if (userMessages.isNotEmpty && aiMessages.isNotEmpty) {
      final lastUserMessage = userMessages.last.text;
      final lastAiMessage = aiMessages.last.text;
      
      // Combine user message with AI response for title
      final combinedTitle = '$lastUserMessage → ${stripMarkdown(lastAiMessage)}';
      final truncatedTitle = combinedTitle.length > 60 
        ? '${combinedTitle.substring(0, 57)}...' 
        : combinedTitle;
      
      return truncatedTitle;
    } else if (userMessages.isNotEmpty) {
      // Fallback to just user message if no AI response
      final lastUserMessage = stripMarkdown(userMessages.last.text);
      final truncatedTitle = lastUserMessage.length > 60 
        ? '${lastUserMessage.substring(0, 57)}...' 
        : lastUserMessage;
      
      return truncatedTitle;
    }
    
    return 'New Chat';
  }

  /// Strip markdown formatting for chat preview
  static String stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), '[Code]') // Code blocks
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Links
        .replaceAll(RegExp(r'\n+'), ' ') // Multiple newlines to space
        .trim();
  }

  /// Handle optimized streaming updates
  static void optimizedStreamingUpdate({
    required String chunk,
    required List<ChatMessage> messages,
    required Function(int, ChatMessage) updateMessage,
    required Function() scrollToBottom,
    required String currentModelResponse,
    required Function(String) setCurrentModelResponse,
    required Function(String) setPendingStreamingContent,
    required Timer? streamingUpdateTimer,
    required Function(Timer?) setStreamingUpdateTimer,
  }) {
    final newResponse = currentModelResponse + chunk;
    setCurrentModelResponse(newResponse);
    setPendingStreamingContent(newResponse);

    // Cancel existing timer
    streamingUpdateTimer?.cancel();

    // Set new timer for optimized updates
    setStreamingUpdateTimer(Timer(const Duration(milliseconds: 16), () { // 60fps update rate
      if (messages.isEmpty) return;

      // Update message content
      updateMessage(
        messages.length - 1,
        ChatMessage(
          role: 'model',
          text: newResponse,
        ),
      );

      // Auto-scroll if user is near the bottom
      scrollToBottom();
    }));
  }

  /// Regenerate response for a specific message
  static Future<void> regenerateResponse({
    required int userMessageIndex,
    required List<ChatMessage> messages,
    required String selectedModel,
    required bool isWebSearchEnabled,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required Function() scrollToBottom,
    required Function(List<ChatMessage>) removeMessagesFrom,
  }) async {
    if (userMessageIndex < 0 || userMessageIndex >= messages.length) return;

    final userMessage = messages[userMessageIndex];
    
    // Remove all messages after the user message
    removeMessagesFrom(messages.take(userMessageIndex + 1).toList());
    
    // Add new placeholder response
    addMessage(ChatMessage(role: 'model', text: ''));
    scrollToBottom();

    try {
      String? webSearchResults;
      if (isWebSearchEnabled) {
        webSearchResults = await handleWebSearch(userMessage.text);
      }

      await _streamAIResponse(
        input: userMessage.text,
        messages: messages.take(userMessageIndex + 1).toList(),
        selectedModel: selectedModel,
        updateMessage: updateMessage,
        webSearchResults: webSearchResults,
      );
    } catch (e) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $e'));
    }
  }

  /// Check if input should trigger web search
  static bool shouldTriggerWebSearch(String input) {
    final lowerInput = input.toLowerCase();
    final webSearchTriggers = [
      'search', 'find', 'look up', 'what is', 'tell me about',
      'latest', 'current', 'recent', 'news', 'today',
      'weather', 'stock price', 'exchange rate'
    ];
    
    return webSearchTriggers.any((trigger) => lowerInput.contains(trigger));
  }

  /// Validate message input
  static bool isValidInput(String input, dynamic attachment) {
    return input.trim().isNotEmpty || attachment != null;
  }

  /// Generate image using AI
  static Future<void> generateImage({
    required String prompt,
    required String selectedModel,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required List<ChatMessage> messages,
  }) async {
    print('🎨 Starting image generation...');
    print('   Prompt: $prompt');
    print('   Model: $selectedModel');
    print('   Messages count before: ${messages.length}');
    
    // Add user message for image generation
    addMessage(ChatMessage(role: 'user', text: 'Generate image: $prompt'));
    print('   Messages count after user message: ${messages.length}');
    
    // Add placeholder for AI response with image type
    addMessage(ChatMessage(role: 'model', text: '', type: MessageType.image));
    print('   Messages count after placeholder: ${messages.length}');
    
    // Get the index of the placeholder message (last message in the list)
    final placeholderIndex = messages.length - 1;
    print('   Placeholder index: $placeholderIndex');

    try {
      print('📡 Calling ImageApi.generateImage...');
      // Use ImageApi to generate the actual image
      final imageUrl = await ImageApi.generateImage(prompt, model: selectedModel);
      
      print('📸 Image generation completed:');
      print('   URL: $imageUrl');
      print('   Type: ${imageUrl?.runtimeType}');
      print('   Is null: ${imageUrl == null}');
      print('   Is empty: ${imageUrl?.isEmpty}');
      print('   Length: ${imageUrl?.length}');
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        print('✅ Updating message with successful image...');
        updateMessage(placeholderIndex, ChatMessage(
          role: 'model',
          text: '',
          type: MessageType.image,
          imageUrl: imageUrl,
        ));
        print('✅ Image generated successfully: ${imageUrl.substring(0, math.min(50, imageUrl.length))}...');
      } else {
        print('❌ Image generation returned null/empty, showing error...');
        updateMessage(placeholderIndex, ChatMessage(
          role: 'model', 
          text: '❌ Error: Image generation returned empty result'
        ));
      }
    } catch (e, stackTrace) {
      print('❌ Image generation error: $e');
      print('❌ Stack trace: $stackTrace');
      updateMessage(placeholderIndex, ChatMessage(
        role: 'model', 
        text: '❌ Error generating image: $e'
      ));
    }
    
    print('🏁 Image generation function completed.');
  }

  /// Copy text to clipboard
  static void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1))
    );
  }

  /// Generate presentation using AI
  static Future<void> generatePresentation({
    required String topic,
    required String selectedModel,
    required List<ChatMessage> messages,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
  }) async {
    // Add user message for presentation generation
    addMessage(ChatMessage(role: 'user', text: 'Generate presentation: $topic'));
    
    // Add placeholder for AI response with null presentation data (will show shimmer)
    addMessage(ChatMessage(role: 'model', text: '', type: MessageType.presentation));

    try {
      // Use PresentationService to generate actual presentation
      final presentationData = await PresentationService.generatePresentationData(topic, selectedModel);
      
      final lastIndex = messages.length - 1; // Get the actual last message index
      updateMessage(lastIndex, ChatMessage(
        role: 'model',
        text: '',
        type: MessageType.presentation,
        presentationData: presentationData ?? <String, dynamic>{},
      ));
    } catch (e) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error generating presentation: $e'));
    }
  }
}