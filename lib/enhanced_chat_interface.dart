import 'package:flutter/material.dart';
import 'premium_ui_enhancements.dart';
import 'enhanced_content_widget.dart';

/// Enhanced Chat Interface with Premium UI - Standalone Demo
class EnhancedChatInterface extends StatefulWidget {
  const EnhancedChatInterface({super.key});

  @override
  State<EnhancedChatInterface> createState() => _EnhancedChatInterfaceState();
}

class _EnhancedChatInterfaceState extends State<EnhancedChatInterface>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late TextEditingController _messageController;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  bool _isComposing = false;
  bool _isLoading = false;
  
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _messageController = TextEditingController();
    
    _sendButtonController = AnimationController(
      duration: PremiumUIEnhancements.fastDuration,
      vsync: this,
    );
    
    _sendButtonScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: PremiumUIEnhancements.bouncyCurve,
    ));

    _messageController.addListener(() {
      final isComposing = _messageController.text.isNotEmpty;
      if (isComposing != _isComposing) {
        setState(() {
          _isComposing = isComposing;
        });
        if (isComposing) {
          _sendButtonController.forward();
        } else {
          _sendButtonController.reverse();
        }
      }
    });

    // Add some demo messages
    _addDemoMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _addDemoMessages() {
    _messages = [
      ChatMessage(
        content: "Hello! I'm AhamAI with enhanced premium UI. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        id: '1',
      ),
      ChatMessage(
        content: "Hi! This UI looks amazing with smooth animations!",
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        id: '2',
      ),
      ChatMessage(
        content: "Thank you! The new interface includes:\n\n• **Smooth animations** with premium curves\n• **Haptic feedback** for all interactions\n• **Enhanced cards** with beautiful shadows\n• **Staggered list animations** for messages\n• **Premium button interactions** with scale effects\n\nTry typing a message to see the enhanced input field!",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        id: '3',
      ),
    ];
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: PremiumUIEnhancements.mediumDuration,
          curve: PremiumUIEnhancements.smoothCurve,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text.trim();
    PremiumUIEnhancements.mediumHaptic();
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            content: _generateAIResponse(message),
            isUser: false,
            timestamp: DateTime.now(),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    });
  }

  String _generateAIResponse(String userMessage) {
    final responses = [
      "Great question! The premium UI enhancements include smooth animations, haptic feedback, and beautiful transitions.",
      "I love how the new interface feels so responsive! Each interaction has been carefully crafted for the best user experience.",
      "The **enhanced content widget** now supports rich markdown with beautiful styling and smooth fade-in animations.",
      "Did you notice the haptic feedback when you sent that message? It's part of the premium feel we've implemented!",
      "The app now features:\n\n1. **Smooth scrolling** with bouncing physics\n2. **Premium buttons** with scale animations\n3. **Enhanced text fields** with focus animations\n4. **Staggered list animations** for better visual flow",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return PremiumCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      elevation: 2,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'AhamAI Premium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isLoading) 
            const SmoothLoadingIndicator(size: 20)
          else
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return SmoothFadeIn(
          delay: Duration(milliseconds: index * 50),
          child: _buildMessageBubble(message, index),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SmoothFadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Premium Chat Experience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enhanced with smooth animations and premium interactions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: PremiumAnimatedContainer(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnhancedContentWidget(
                    content: message.content,
                    isUserMessage: isUser,
                    isThinkingMode: false,
                  ),
                  if (message.timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formatTimestamp(message.timestamp!),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser 
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser 
            ? Theme.of(context).primaryColor
            : Colors.grey.shade100,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 20,
        color: isUser 
            ? Colors.white
            : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: PremiumTextField(
                controller: _messageController,
                hintText: 'Type your message...',
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onSubmitted: _sendMessage,
                onChanged: (value) {
                  // Handled by controller listener
                },
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _sendButtonScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScale.value,
                  child: PremiumButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    isLoading: _isLoading,
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      _isComposing ? Icons.send : Icons.add,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Enhanced Chat Message Model for Premium UI
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime? timestamp;
  final String? id;

  ChatMessage({
    required this.content,
    required this.isUser,
    this.timestamp,
    this.id,
  });
}