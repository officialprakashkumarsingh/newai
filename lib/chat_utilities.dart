import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'web_search.dart';

/// Chat Utilities - Helper methods for chat functionality
/// This class contains utility methods moved from chat_screen.dart
class ChatUtilities {
  
  /// Copy text to clipboard with feedback
  static void copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
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

  /// Strip markdown formatting for preview text
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

  /// Load messages from SharedPreferences
  static Future<List<ChatMessage>> loadMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('chat_$chatId');
      if (messagesJson != null) {
        return messagesJson.map((jsonString) => ChatMessage.fromJson(json.decode(jsonString))).toList();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
    return [];
  }

  /// Save messages to SharedPreferences
  static Future<void> saveMessages(String chatId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((message) => json.encode(message.toJson())).toList();
      await prefs.setStringList('chat_$chatId', messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  /// Validate input before sending
  static bool isValidInput(String input, dynamic attachment) {
    return input.trim().isNotEmpty || attachment != null;
  }

  /// Check if message should trigger web search
  static bool shouldTriggerWebSearch(String message) {
    final lowerMessage = message.toLowerCase();
    final searchTriggers = [
      'search for', 'look up', 'find information about', 'what is',
      'latest', 'current', 'recent', 'news about', 'today',
      'weather', 'stock price', 'exchange rate',
    ];
    
    return searchTriggers.any((trigger) => lowerMessage.contains(trigger));
  }

  /// Check if message contains diagram request
  static bool containsDiagramRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final diagramKeywords = [
      'chart', 'graph', 'diagram', 'plot', 'visualization',
      'bar chart', 'line chart', 'pie chart', 'scatter plot',
      'flowchart', 'flow chart', 'organogram', 'timeline',
    ];
    
    return diagramKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Format markdown text for display
  static String formatMarkdownText(String text) {
    // Basic markdown formatting
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), '**\$1**') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), '*\$1*') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), '`\$1`') // Inline code
        .replaceAll(RegExp(r'```([\s\S]*?)```'), '```\n\$1\n```'); // Code blocks
  }

  /// Get error message for display
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('auth')) {
      return 'Authentication error. Please check your API key.';
    } else {
      return 'An error occurred: ${error.toString()}';
    }
  }

  /// Calculate optimal scroll position
  static double calculateScrollPosition(ScrollController controller, double itemHeight) {
    if (!controller.hasClients) return 0.0;
    
    final maxScroll = controller.position.maxScrollExtent;
    final currentScroll = controller.position.pixels;
    final viewportHeight = controller.position.viewportDimension;
    
    // If we're near the bottom, scroll to bottom
    if (maxScroll - currentScroll < viewportHeight) {
      return maxScroll;
    }
    
    return currentScroll;
  }

  /// Create user message object
  static ChatMessage createUserMessage(String text, {
    String? attachedFileName,
    List<String>? attachedContainedFiles,
    Uint8List? imageBytes,
  }) {
    return ChatMessage(
      role: 'user',
      text: text,
      attachedFileName: attachedFileName,
      attachedContainedFiles: attachedContainedFiles,
      imageBytes: imageBytes,
    );
  }

  /// Create AI message object
  static ChatMessage createAIMessage(String text, {
    MessageType type = MessageType.text,
    String? imageUrl,
    Map<String, dynamic>? presentationData,
    Map<String, dynamic>? diagramData,
    Widget? researchWidget,
    List<SearchResult>? searchResults,
  }) {
    return ChatMessage(
      role: 'model',
      text: text,
      type: type,
      imageUrl: imageUrl,
      presentationData: presentationData,
      diagramData: diagramData,
      researchWidget: researchWidget,
      searchResults: searchResults,
    );
  }
}