import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'api_service.dart';
import 'api.dart';
import 'diagram_handler.dart';
import 'research_mode.dart';
import 'web_search.dart';
import 'presentation_service.dart';
import 'thinking_panel.dart';

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

  /// Save messages to storage
  static Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((message) => jsonEncode(message.toJson())).toList();
      await prefs.setStringList('chat_$chatId', messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  /// Send text message to AI
  static Future<void> sendTextMessage({
    required String input,
    required List<ChatMessage> messages,
    required String selectedModel,
    required bool isWebSearchEnabled,
    required bool isResearchModeEnabled,
    required bool isThinkingModeEnabled,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required Function() scrollToBottom,
    required Function() startStreaming,
    required Function() stopStreaming,
    Function()? onStreamingComplete,
    dynamic attachment,
  }) async {
    if (input.trim().isEmpty && attachment == null) return;

    // Add user message
    final userMessage = ChatMessage(
      role: 'user',
      text: input,
      attachedFileName: attachment?.fileName,
      attachedContainedFiles: attachment?.containedFileNames,
    );
    addMessage(userMessage);

    // Add placeholder AI response
    addMessage(ChatMessage(role: 'model', text: ''));
    scrollToBottom();

    try {
      String finalInputForAI = input;

      // Handle research mode
      if (isResearchModeEnabled && input.trim().isNotEmpty) {
        finalInputForAI = formatResearchModeInput(input);
      }

      // Handle web search if enabled
      String? webSearchResults;
      if (isWebSearchEnabled) {
        webSearchResults = await handleWebSearch(input);
      }

      // Start streaming state
      startStreaming();

      // Send to AI with streaming
      await sendOpenAICompatibleStream(
        input: finalInputForAI,
        messages: messages,
        selectedModel: selectedModel,
        webSearchResults: webSearchResults,
        updateMessage: updateMessage,
        isThinkingMode: isThinkingModeEnabled,
      );
      
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

  /// Format input for research mode
  static String formatResearchModeInput(String input) {
    return """Please analyze this query in detail and provide a comprehensive research-based response: $input

Please structure your response with:
1. **Overview**: Brief summary of the topic
2. **Key Points**: Main information and findings  
3. **Analysis**: Deep dive into important aspects
4. **Applications**: Real-world uses or implications
5. **Conclusion**: Summary and key takeaways

Based on the context above, answer the following prompt: $input""";
  }

  /// Send OpenAI compatible stream
  static Future<void> sendOpenAICompatibleStream({
    required String input,
    required List<ChatMessage> messages,
    required String selectedModel,
    required Function(int, ChatMessage) updateMessage,
    String? webSearchResults,
    bool isThinkingMode = false,
  }) async {
    String finalInputForAI = input;
    
    if (webSearchResults != null) {
      finalInputForAI = webSearchResults + input;
    }

    final conversationHistory = buildConversationHistory(messages);

    await for (final chunk in ApiService.sendChatMessage(
      message: finalInputForAI,
      model: selectedModel,
      conversationHistory: conversationHistory,
      isThinkingMode: isThinkingMode,
    )) {
      final lastIndex = messages.length - 1;
      final currentText = messages[lastIndex].text + chunk;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: currentText));
    }
  }

  /// Build conversation history for API
  static List<Map<String, dynamic>>? buildConversationHistory(List<ChatMessage> messages) {
    final conversationHistory = messages
        .where((m) => m.text.isNotEmpty)
        .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
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

      final parsedContent = ThinkingContentParser.parseContent(newResponse);
      final finalContent = parsedContent['final'] as String?;
      final thinkingContent = parsedContent['thinking'] as String?;
      
      // Debug logging for thinking content
      if (thinkingContent != null && thinkingContent.isNotEmpty) {
        print('🧠 Thinking content detected: ${thinkingContent.substring(0, thinkingContent.length > 100 ? 100 : thinkingContent.length)}...');
      }
      
      // Check if response contains thinking tags
      if (ThinkingContentParser.hasThinkingContent(newResponse)) {
        print('🏷️ Thinking tags detected in response');
      }

      updateMessage(
        messages.length - 1,
        ChatMessage(
          role: 'model',
          text: finalContent ?? newResponse,
          thinkingContent: thinkingContent,
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

      await sendOpenAICompatibleStream(
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
  }) async {
    // Add user message for image generation
    addMessage(ChatMessage(role: 'user', text: 'Generate image: $prompt'));
    
    // Add placeholder for AI response
    final placeholderIndex = 1; // Will be the second message (index 1)
    addMessage(ChatMessage(role: 'model', text: 'Generating image...'));

    try {
      // Use ImageApi to generate the actual image
      final imageUrl = await ImageApi.generateImage(prompt, model: selectedModel);
      
      updateMessage(placeholderIndex, ChatMessage(
        role: 'model',
        text: 'Image generated successfully!',
        type: MessageType.image,
        imageUrl: imageUrl,
      ));
    } catch (e) {
      updateMessage(placeholderIndex, ChatMessage(
        role: 'model', 
        text: '❌ Error generating image: $e'
      ));
    }
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
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
  }) async {
    // Add user message for presentation generation
    addMessage(ChatMessage(role: 'user', text: 'Generate presentation: $topic'));
    
    // Add placeholder for AI response
    addMessage(ChatMessage(role: 'model', text: 'Generating presentation...'));

    try {
      // Use PresentationService to generate actual presentation
      final presentationData = await PresentationService.generatePresentationData(topic, selectedModel);
      
      final lastIndex = 1; // Assuming we just added 2 messages
      updateMessage(lastIndex, ChatMessage(
        role: 'model',
        text: 'Presentation generated successfully!',
        type: MessageType.presentation,
        presentationData: presentationData ?? <String, dynamic>{},
      ));
    } catch (e) {
      final lastIndex = 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error generating presentation: $e'));
    }
  }
}