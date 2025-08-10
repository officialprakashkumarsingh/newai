import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'api_service.dart';
import 'thinking_panel.dart';
import 'theme.dart';

class ChatMessage {
  final String role;
  final String text;
  final String? thinkingContent;

  ChatMessage({
    required this.role,
    required this.text,
    this.thinkingContent,
  });
}

class ChatScreenSimple extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final List<ChatMessage>? initialMessages;

  const ChatScreenSimple({
    Key? key,
    required this.chatId,
    required this.chatTitle,
    this.initialMessages,
  }) : super(key: key);

  @override
  State<ChatScreenSimple> createState() => _ChatScreenSimpleState();
}

class _ChatScreenSimpleState extends State<ChatScreenSimple> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String _currentModelResponse = '';
  String _selectedChatModel = 'gemini-1.5-flash';

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null) {
      _messages = List.from(widget.initialMessages!);
    }
    _loadChatModel();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadChatModel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedChatModel = prefs.getString('chat_model') ?? 'gemini-1.5-flash';
    });
  }

  Future<void> _sendMessage(String input) async {
    if (input.trim().isEmpty || _isStreaming) return;

    final userMessage = ChatMessage(role: 'user', text: input);
    setState(() {
      _messages.add(userMessage);
      _messages.add(ChatMessage(role: 'model', text: ''));
      _isStreaming = true;
      _currentModelResponse = '';
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Prepare conversation history
      final conversationHistory = _messages
          .where((m) => m.text.isNotEmpty)
          .map((m) => {
        'role': m.role == 'user' ? 'user' : 'assistant', 
        'content': m.text
      }).toList();

      await for (final chunk in ApiService.sendChatMessage(
        message: input,
        model: _selectedChatModel,
        conversationHistory: conversationHistory,
      )) {
        setState(() {
          _currentModelResponse += chunk;
          _messages[_messages.length - 1] = ChatMessage(
            role: 'model', 
            text: _currentModelResponse
          );
        });
        _scrollToBottom();
      }
    } catch (error) {
      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          role: 'model', 
          text: '❌ Error: $error'
        );
      });
    } finally {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(ChatMessage message, int index) {
    final bool isModelMessage = message.role == 'model';
    
    if (isModelMessage) {
      // AI message with GptMarkdown
      if (message.text.isEmpty && _isStreaming && index == _messages.length - 1) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: message.thinkingContent != null && message.thinkingContent!.isNotEmpty
              ? ThinkingPanel(
                  thinkingContent: message.thinkingContent!,
                  isStreaming: false, // Simple screen doesn't track streaming
                  finalContent: message.text,
                )
              : MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
        ),
      );
    } else {
      // User message
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isLightTheme(context) 
                ? const Color(0xFF1976D2)
                : const Color(0xFF1976D2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(
            message.text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _sendMessage(value),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isStreaming 
                      ? null 
                      : () => _sendMessage(_textController.text),
                  mini: true,
                  child: Icon(_isStreaming ? Icons.stop : Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}