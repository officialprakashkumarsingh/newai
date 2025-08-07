import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'api_service.dart';
import 'diagram_handler.dart';
import 'research_mode.dart';
import 'web_search.dart';
import 'presentation_service.dart';
import 'file_processing.dart';

class ChatMessageHandler {
  final Function(String, bool) updateChatInfo;
  final Function(ChatMessage) addMessage;
  final Function(int, ChatMessage) updateMessage;
  final Function() scrollToBottom;
  final Function() saveMessages;
  final Function(List<SearchResult>) setSearchResults;
  final DiagramHandler diagramHandler;

  ChatMessageHandler({
    required this.updateChatInfo,
    required this.addMessage,
    required this.updateMessage, 
    required this.scrollToBottom,
    required this.saveMessages,
    required this.setSearchResults,
    required this.diagramHandler,
  });

  /// Send a text message
  Future<void> sendTextMessage(
    String input,
    List<ChatMessage> messages,
    String selectedModel,
    bool isWebSearchEnabled,
    bool isResearchModeEnabled,
    ChatAttachment? attachment,
  ) async {
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

    updateChatInfo(selectedModel, false);
    scrollToBottom();

    try {
      String finalInputForAI = input;

      // Handle research mode
      Widget? researchWidget;
      if (isResearchModeEnabled && input.trim().isNotEmpty) {
        finalInputForAI = """Please analyze this query in detail and provide a comprehensive research-based response: $input

Please structure your response with:
1. **Overview**: Brief summary of the topic
2. **Key Points**: Main information and findings  
3. **Analysis**: Deep dive into important aspects
4. **Applications**: Real-world uses or implications
5. **Conclusion**: Summary and key takeaways

Based on the context above, answer the following prompt: $input""";
        
        // Create inline research terminal
        final researchWidget = InlineResearchTerminal(
          query: input,
          selectedModel: selectedModel,
          onResult: (result) {
            // Handle research results if needed
          },
        );

        // Update the message with research widget
        final lastIndex = messages.length;
        updateMessage(lastIndex, ChatMessage(
          role: 'model',
          text: '',
          researchWidget: researchWidget,
        ));
      }

      // Handle web search if enabled
      String? webSearchResults;
      if (isWebSearchEnabled) {
        await _handleWebSearch(input, messages);
        // Get search results for context
        webSearchResults = await _getWebSearchContext(input);
      }

      // Send to AI with streaming
      await _sendOpenAICompatibleStream(
        finalInputForAI,
        messages,
        selectedModel,
        webSearchResults: webSearchResults,
      );

    } catch (e) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $e'));
      updateChatInfo('', false);
    }

    saveMessages();
  }

  /// Send a vision message with image
  Future<void> sendVisionMessage(
    String input,
    XFile imageFile,
    List<ChatMessage> messages,
    String selectedModel,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final userMessage = ChatMessage(role: 'user', text: input, imageBytes: imageBytes);
    addMessage(userMessage);
    addMessage(ChatMessage(role: 'model', text: ''));

    updateChatInfo(selectedModel, false);
    scrollToBottom();

    try {
      await for (final chunk in ApiService.sendVisionMessage(
        message: input,
        imageBase64: base64.encode(imageBytes),
        model: selectedModel,
      )) {
        final lastIndex = messages.length - 1;
        final currentText = messages[lastIndex].text + chunk;
        updateMessage(lastIndex, ChatMessage(role: 'model', text: currentText));
      }
    } catch (e) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $e'));
    }

    updateChatInfo('', false);
    saveMessages();
  }

  /// Handle web search
  Future<void> _handleWebSearch(String input, List<ChatMessage> messages) async {
    final lastIndex = messages.length - 1;
    updateMessage(lastIndex, ChatMessage(role: 'model', text: 'Searching the web...'));

    try {
      final searchResponse = await WebSearchService.search(input);
      if (searchResponse != null && searchResponse.results.isNotEmpty) {
        setSearchResults(searchResponse.results);
      }
      
      // Clear the searching message
      updateMessage(lastIndex, ChatMessage(role: 'model', text: ''));
    } catch (e) {
      print('Web search error: $e');
      updateMessage(lastIndex, ChatMessage(role: 'model', text: ''));
    }
  }

  /// Get web search context for AI
  Future<String?> _getWebSearchContext(String query) async {
    try {
      final searchResponse = await WebSearchService.search(query);
      if (searchResponse != null && searchResponse.results.isNotEmpty) {
        final context = searchResponse.results.take(3).map((r) => 
          'Title: ${r.title}\nContent: ${r.snippet}\nURL: ${r.url}'
        ).join('\n\n');
        return 'Web search results for "$query":\n\n$context\n\n';
      }
    } catch (e) {
      print('Error getting web search context: $e');
    }
    return null;
  }

  /// Send OpenAI compatible stream
  Future<void> _sendOpenAICompatibleStream(
    String input,
    List<ChatMessage> messages,
    String selectedModel, {
    String? webSearchResults,
  }) async {
    String finalInputForAI = input;
    
    if (webSearchResults != null) {
      finalInputForAI = webSearchResults + input;
    }

    // External tools removed as requested

    final conversationHistory = _buildConversationHistory(messages);

    await for (final chunk in ApiService.sendChatMessage(
      message: finalInputForAI,
      model: selectedModel,
      conversationHistory: conversationHistory,
    )) {
      final lastIndex = messages.length - 1;
      final currentText = messages[lastIndex].text + chunk;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: currentText));
    }

    // Check for diagram requests after streaming is done
    final aiResponse = messages.last.text;
    await diagramHandler.checkAndHandleDiagramRequest(aiResponse, selectedModel);
  }

  /// Build conversation history for API
  List<Map<String, dynamic>>? _buildConversationHistory(List<ChatMessage> messages) {
    final conversationHistory = messages
        .where((m) => m.text.isNotEmpty)
        .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
        .toList();
    
    return conversationHistory.isNotEmpty ? conversationHistory : null;
  }

  /// Regenerate response
  Future<void> regenerateResponse(
    int userMessageIndex,
    List<ChatMessage> messages,
    String selectedModel,
    bool isWebSearchEnabled,
  ) async {
    if (userMessageIndex < 0 || userMessageIndex >= messages.length) return;

    final userMessage = messages[userMessageIndex];
    
    // Remove all messages after the user message
    final messagesToKeep = messages.take(userMessageIndex + 1).toList();
    
    // Add new placeholder response
    addMessage(ChatMessage(role: 'model', text: ''));
    
    updateChatInfo(selectedModel, false);
    scrollToBottom();

    try {
      String? webSearchResults;
      if (isWebSearchEnabled) {
        webSearchResults = await _getWebSearchContext(userMessage.text);
      }

      await _sendOpenAICompatibleStream(
        userMessage.text,
        messagesToKeep,
        selectedModel,
        webSearchResults: webSearchResults,
      );
    } catch (e) {
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $e'));
    }

    updateChatInfo('', false);
    saveMessages();
  }
}