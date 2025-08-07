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

/// Message Processing Helpers - Provides utility methods for message handling
/// This class provides helper methods without replacing core chat functionality
class ChatMessageHandler {
  
  /// Helper to build conversation history for API calls
  static List<Map<String, dynamic>>? buildConversationHistory(List<ChatMessage> messages) {
    final conversationHistory = messages
        .where((m) => m.text.isNotEmpty)
        .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
        .toList();
    
    return conversationHistory.isNotEmpty ? conversationHistory : null;
  }

  /// Helper to extract web search context
  static Future<String?> getWebSearchContext(String query) async {
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

  /// Helper to format research mode input
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

  /// Helper to check if a message should trigger web search
  static bool shouldTriggerWebSearch(String message) {
    final lowerMessage = message.toLowerCase();
    final searchTriggers = [
      'search for', 'look up', 'find information about', 'what is',
      'latest', 'current', 'recent', 'news about', 'today',
    ];
    
    return searchTriggers.any((trigger) => lowerMessage.contains(trigger));
  }

  /// Helper to validate message input
  static bool isValidInput(String input, ChatAttachment? attachment) {
    return input.trim().isNotEmpty || attachment != null;
  }

  /// Helper to create user message
  static ChatMessage createUserMessage(String text, {ChatAttachment? attachment, List<int>? imageBytes}) {
    return ChatMessage(
      role: 'user',
      text: text,
      attachedFileName: attachment?.fileName,
      attachedContainedFiles: attachment?.containedFileNames,
      imageBytes: imageBytes != null ? Uint8List.fromList(imageBytes) : null,
    );
  }

  /// Helper to create AI placeholder message
  static ChatMessage createAIPlaceholderMessage() {
    return ChatMessage(role: 'model', text: '');
  }

  /// Helper to update chat title from messages
  static String generateChatTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'New Chat';
    
    final userMessages = messages.where((m) => m.role == 'user').toList();
    final aiMessages = messages.where((m) => m.role == 'model').toList();
    
    if (userMessages.isNotEmpty && aiMessages.isNotEmpty) {
      final lastUserMessage = userMessages.last.text;
      final lastAiMessage = aiMessages.last.text;
      
      // Combine user message with AI response for title
      final combinedTitle = '$lastUserMessage → ${_stripMarkdown(lastAiMessage)}';
      final truncatedTitle = combinedTitle.length > 60 
        ? '${combinedTitle.substring(0, 57)}...' 
        : combinedTitle;
      
      return truncatedTitle;
    } else if (userMessages.isNotEmpty) {
      // Fallback to just user message if no AI response
      final lastUserMessage = _stripMarkdown(userMessages.last.text);
      final truncatedTitle = lastUserMessage.length > 60 
        ? '${lastUserMessage.substring(0, 57)}...' 
        : lastUserMessage;
      
      return truncatedTitle;
    }
    
    return 'New Chat';
  }

  /// Helper function to strip markdown formatting for chat preview
  static String _stripMarkdown(String text) {
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
}