import 'dart:async';
import 'package:flutter/material.dart';

import 'main.dart';
import 'thinking_panel.dart';
import 'web_search.dart';
import 'diagram_handler.dart';

class ChatStreamingHandler {
  // Streaming optimization
  Timer? _streamingUpdateTimer;
  String _pendingStreamingContent = '';
  String _currentModelResponse = '';
  
  final Function(int, ChatMessage) updateMessage;
  final Function() scrollToBottom;
  final Function() saveMessages;
  final Function(String, bool) updateChatInfo;
  final Function(List<SearchResult>?) setSearchResults;
  final DiagramHandler diagramHandler;

  ChatStreamingHandler({
    required this.updateMessage,
    required this.scrollToBottom,
    required this.saveMessages,
    required this.updateChatInfo,
    required this.setSearchResults,
    required this.diagramHandler,
  });

  /// Handle streaming done
  Future<void> onStreamingDone(
    List<ChatMessage> messages,
    String selectedModel,
    List<SearchResult>? lastSearchResults,
  ) async {
    // Cancel any pending streaming updates and apply final content
    _streamingUpdateTimer?.cancel();
    if (_pendingStreamingContent.isNotEmpty) {
      updateMessage(messages.length - 1, ChatMessage(
        role: 'model', 
        text: _pendingStreamingContent,
      ));
    }
    
    if (lastSearchResults != null && messages.isNotEmpty) {
      final lastMessage = messages.last;
      updateMessage(messages.length - 1, ChatMessage(
        role: lastMessage.role,
        text: lastMessage.text,
        type: lastMessage.type,
        imageUrl: lastMessage.imageUrl,
        slides: lastMessage.slides,
        searchResults: lastSearchResults,
      ));
      setSearchResults(null);
    }
    
    updateChatInfo('', false);
    
    // Automatic diagram detection removed - use bottom sheet instead
    
    scrollToBottom();
    saveMessages(); // Save messages after streaming is complete

    // Stream completed
    print('✅ Stream completed successfully');
    
    // Reset streaming content
    _pendingStreamingContent = '';
    _currentModelResponse = '';
  }

  /// Handle streaming error
  void onStreamingError(dynamic error, List<ChatMessage> messages) {
    _streamingUpdateTimer?.cancel();
    final lastIndex = messages.length - 1;
    updateMessage(lastIndex, ChatMessage(role: 'model', text: '❌ Error: $error'));
    updateChatInfo('', false);
    
    // Reset streaming content
    _pendingStreamingContent = '';
    _currentModelResponse = '';
  }

  /// Optimized streaming update with micro-batching
  void optimizedStreamingUpdate(String chunk, List<ChatMessage> messages) {
    _currentModelResponse += chunk;
    _pendingStreamingContent = _currentModelResponse;
    
    // Cancel previous timer if exists
    _streamingUpdateTimer?.cancel();
    
    // Instant updates with micro-batching for ultra-smooth experience
    _streamingUpdateTimer = Timer(const Duration(milliseconds: 16), () { // 60fps update rate
      // Update message content directly
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(
        role: 'model', 
        text: _pendingStreamingContent,
      ));
      
      scrollToBottom();
    });
  }

  /// Stop streaming
  void stopStreaming() {
    _streamingUpdateTimer?.cancel();
    _pendingStreamingContent = '';
    _currentModelResponse = '';
  }

  /// Dispose resources
  void dispose() {
    _streamingUpdateTimer?.cancel();
  }

  /// Get current streaming content
  String get currentStreamingContent => _pendingStreamingContent;

  /// Check if currently streaming
  bool get isStreaming => _streamingUpdateTimer?.isActive == true;

  void finishStreaming(List<ChatMessage> messages, Function(int, ChatMessage) updateMessage, Function() scrollToBottom) {
    print('🔄 FINISHING STREAMING');
    _streamingUpdateTimer?.cancel();
    if (_pendingStreamingContent.isNotEmpty) {
      updateMessage(messages.length - 1, ChatMessage(
        role: 'model', 
        text: _pendingStreamingContent,
      ));
    }
    
    _pendingStreamingContent = '';
    scrollToBottom();
  }

  void _scheduleUpdate(List<ChatMessage> messages, Function(int, ChatMessage) updateMessage, Function() scrollToBottom) {
    _streamingUpdateTimer?.cancel();
    _streamingUpdateTimer = Timer(const Duration(milliseconds: 16), () { // 60fps update rate
      // Update message content directly
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(
        role: 'model', 
        text: _pendingStreamingContent,
      ));
      
      scrollToBottom();
    });
  }
}