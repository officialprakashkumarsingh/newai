import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // <-- ADDED: For Uint8List
import 'package:ahamai/web_search.dart';
import 'package:ahamai/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- FIXED: Correct import path
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'voice_controller.dart'; // Removed for simplification
import 'voice_animation_widget.dart';
import 'background_pattern.dart';
import 'universe_logo.dart';
// import 'background_service.dart'; // Temporarily disabled
// import 'package:google_fonts/google_fonts.dart'; // Removed



import 'chat_screen_simple.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable edge-to-edge mode (system UI will be configured per-theme)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Background service temporarily disabled
  // await BackgroundService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AhamApp(),
    ),
  );
}

class AhamApp extends StatefulWidget {
  const AhamApp({super.key});

  @override
  State<AhamApp> createState() => _AhamAppState();
}

class _AhamAppState extends State<AhamApp> {
  static const platform = MethodChannel('com.ahamai.text_sharing');
  static const widgetPlatform = MethodChannel('com.ahamai.widget');
  String? _sharedText;
  String? _widgetAction;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeSharing();
    _initializeWidget();
    _initializeNotifications();
  }

  void _initializeSharing() {
    // Set up method channel to receive shared text from Android
    platform.setMethodCallHandler((call) async {
      if (call.method == 'sharedText') {
        final String sharedText = call.arguments;
        print("Received shared text: $sharedText");
        setState(() => _sharedText = sharedText);
        _handleSharedText(sharedText);
      }
    });

    // Check for initial shared text when app starts
    _getInitialSharedText();
  }

  Future<void> _getInitialSharedText() async {
    try {
      final String? sharedText = await platform.invokeMethod('getInitialSharedText');
      if (sharedText != null && sharedText.isNotEmpty) {
        print("Received initial shared text: $sharedText");
        setState(() => _sharedText = sharedText);
        _handleSharedText(sharedText);
      }
    } catch (e) {
      print("Error getting initial shared text: $e");
    }
  }

  void _initializeWidget() {
    // Check for widget action when app starts
    _getInitialWidgetAction();
  }

  void _initializeNotifications() {
    // Set up notification handler for background service
    const backgroundChannel = MethodChannel('com.ahamai.background');
    backgroundChannel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTapped') {
        final String chatId = call.arguments['chatId'];
        final String processType = call.arguments['processType'];
        print("Notification tapped: chatId=$chatId, processType=$processType");
        
        // Navigate to the specific chat
        _navigateToSpecificChat(chatId, processType);
      }
    });
  }

  void _navigateToSpecificChat(String chatId, String processType) {
    // Simply navigate to the main screen which will show the completed chat
    // The user can then see their completed request in the chat history
    print("Navigating to chat with completed $processType");
    
    // If we're not already on the main screen, navigate there
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _getInitialWidgetAction() async {
    try {
      final String? action = await widgetPlatform.invokeMethod('getWidgetAction');
      if (action != null && action.isNotEmpty) {
        print("Received widget action: $action");
        setState(() => _widgetAction = action);
        _handleWidgetAction(action);
      }
    } catch (e) {
      print("Error getting widget action: $e");
    }
  }

  void _handleWidgetAction(String action) {
    // Handle widget action after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (action) {
        case 'search_tap':
          _navigateToChat(enableKeyboard: true);
          break;
        case 'voice':
          _startVoiceMode();
          break;
      }
    });
  }

  Future<void> _startVoiceMode() async {
    final voiceController = VoiceController();
    
    // Set up voice result callback - fill input and auto-send
    voiceController.onSpeechResult = (text) {
      // Navigate to chat with voice input and auto-send
      _navigateToChat(initialMessage: text, autoSend: true);
    };
    
    // Start listening
    await voiceController.startListening();
  }

  void _navigateToChat({String? initialMessage, bool autoSend = true, bool enableKeyboard = false}) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatInfoStream: StreamController<ChatInfo>.broadcast(),
          initialMessage: initialMessage,
          autoSend: autoSend,
          enableKeyboard: enableKeyboard,
        ),
      ),
    );
  }

  void _handleSharedText(String text) {
    // Store the shared text - HomeScreen will handle navigation automatically
    setState(() {
      _sharedText = text;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        // Get actual brightness from system theme
        final platformBrightness = MediaQuery.of(context).platformBrightness;
        final isLightMode = platformBrightness == Brightness.light;
        
        final systemIconBrightness = isLightMode ? Brightness.dark : Brightness.light;
            final navBarColor = isLightMode
        ? const Color(0xFFF1F3F4) // Google light theme background for light mode
        : const Color(0xFF202124); // Main Background - Very dark gray for dark mode

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: systemIconBrightness,
          systemNavigationBarIconBrightness: systemIconBrightness,
          systemNavigationBarColor: navBarColor,
          systemNavigationBarDividerColor: Colors.transparent,
        ));

        return MaterialApp(
          title: 'AhamAI',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          theme: ThemeNotifier.lightTheme,
          darkTheme: ThemeNotifier.darkTheme,
          themeMode: theme.themeMode,
          home: HomeScreen(
            key: ValueKey(_sharedText), // Force rebuild when shared text changes
            sharedText: _sharedText,
          ),
        );
      },
    );
  }
}

// DATA MODELS
enum MessageType { text, image, presentation }

class ChatMessage {
  final String role;
  final String text;
  final MessageType type;
  final String? imageUrl;
  final List<String>? slides;
  final List<SearchResult>? searchResults;
  final Uint8List? imageBytes;
  final String? attachedFileName;
  final List<String>? attachedContainedFiles;
  final String? thinkingContent; // Added for thinking/reasoning content

  ChatMessage({
    required this.role,
    required this.text,
    this.type = MessageType.text,
    this.imageUrl,
    this.slides,
    this.searchResults,
    this.imageBytes,
    this.attachedFileName,
    this.attachedContainedFiles,
    this.thinkingContent, // Added thinking content parameter
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'type': type.name,
        'imageUrl': imageUrl,
        'slides': slides,
        'searchResults': searchResults?.map((r) => r.toJson()).toList(),
        'attachedFileName': attachedFileName,
        'thinkingContent': thinkingContent,
        'attachedContainedFiles': attachedContainedFiles,
        // Note: For simplicity, user-uploaded image bytes are not serialized.
        // They will only exist for the current session.
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        text: json['text'],
        type: MessageType.values.byName(json['type'] ?? 'text'),
        imageUrl: json['imageUrl'],
        slides: json['slides'] != null ? List<String>.from(json['slides']) : null,
        searchResults: json['searchResults'] != null ? (json['searchResults'] as List).map((r) => SearchResult.fromJson(r)).toList() : null,
        attachedFileName: json['attachedFileName'],
        attachedContainedFiles: json['attachedContainedFiles'] != null ? List<String>.from(json['attachedContainedFiles']) : null,
        // User image bytes are not loaded from JSON.
      );
}

class ChatInfo {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final bool isPinned;
  final bool isGenerating;
  final bool isStopped;
  final String category;

  ChatInfo({required this.id, required this.title, required this.messages, required this.isPinned, required this.isGenerating, required this.isStopped, required this.category});

  ChatInfo copyWith({String? id, String? title, List<ChatMessage>? messages, bool? isPinned, bool? isGenerating, bool? isStopped, String? category}) =>
      ChatInfo(id: id ?? this.id, title: title ?? this.title, messages: messages ?? this.messages, isPinned: isPinned ?? this.isPinned, isGenerating: isGenerating ?? this.isGenerating, isStopped: isStopped ?? this.isStopped, category: category ?? this.category);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'messages': messages.map((m) => m.toJson()).toList(), 'isPinned': isPinned, 'isGenerating': isGenerating, 'isStopped': isStopped, 'category': category};

  factory ChatInfo.fromJson(Map<String, dynamic> json) => ChatInfo(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
      isPinned: json['isPinned'] ?? false,
      isGenerating: json['isGenerating'] ?? false,
      isStopped: json['isStopped'] ?? false,
      category: json['category'] ?? 'General');
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  final String? sharedText;
  const HomeScreen({super.key, this.sharedText});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<ChatInfo> _chats = [];
  late AnimationController _animationController;
  late Animation<double> _arrowAnimation;
  final _chatInfoStream = StreamController<ChatInfo>.broadcast();
  StreamSubscription<ChatInfo>? _chatInfoSubscription;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _arrowAnimation = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _searchController.addListener(() => setState(() {}));
    
    // Handle shared text - navigate to chat after build completes
    if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
      print("HomeScreen: Handling shared text: ${widget.sharedText}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("HomeScreen: Navigating to chat with shared text");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatInfoStream: _chatInfoStream,
              initialMessage: widget.sharedText!,
            ),
          ),
        );
      });
    }
    _chatInfoSubscription = _chatInfoStream.stream.listen((chatInfo) {
      setState(() {
        final index = _chats.indexWhere((c) => c.id == chatInfo.id);
        if (index != -1) _chats[index] = chatInfo;
        else _chats.insert(0, chatInfo);
        _chats.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return 0;
        });
        _saveChats();
      });
    });
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatData = prefs.getString('chats');
    if (chatData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(chatData);
        setState(() {
          _chats.clear();
          _chats.addAll(decoded.map((e) => ChatInfo.fromJson(e)).toList());
          _chats.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return 0;
          });
        });
      } catch (e) {
        print('Error decoding chats: $e');
        await prefs.remove('chats');
      }
    }
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatData = jsonEncode(_chats.map((e) => e.toJson()).toList());
    await prefs.setString('chats', chatData);
  }

  Future<void> _clearAllChats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Chats?'),
        content: const Text('This will permanently delete all your chat conversations. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _chats.clear());
      await _saveChats();
      if (mounted) {
        Navigator.pop(context); // Close the settings sheet
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All chats have been cleared.')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chatInfoSubscription?.cancel();
    _chatInfoStream.close();
    _searchController.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileSettingsScreen(onClearAllChats: _clearAllChats),
      ),
    );
  }

  void _showRenameDialog(ChatInfo chat, int index) {
    final TextEditingController renameController = TextEditingController(text: chat.title);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rename Chat'),
          content: TextField(
            controller: renameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter new chat title'),
            onSubmitted: (newTitle) {
              if (newTitle.trim().isNotEmpty) {
                Navigator.of(context).pop();
                setState(() {
                  _chats[index] = chat.copyWith(title: newTitle.trim());
                  _saveChats();
                });
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = renameController.text.trim();
                if (newTitle.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() {
                    _chats[index] = chat.copyWith(title: newTitle);
                    _saveChats();
                  });
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() {_isSearching = false; _searchController.clear();})),
        title: TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'Search chats...', border: InputBorder.none), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 18)),
        actions: [if (_searchController.text.isNotEmpty) IconButton(icon: const Icon(Icons.close), onPressed: () => _searchController.clear())],
      );
    } else {
      return AppBar(
        leading: IconButton(icon: const Icon(Icons.account_circle), onPressed: () => _showProfileSheet(context), tooltip: 'Profile & Settings'),
        title: const Text('AhamAI'),
        centerTitle: true,
        actions: [if (_chats.isNotEmpty) IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)), const SizedBox(width: 4)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChatList = _isSearching ? _chats.where((chat) => chat.title.toLowerCase().contains(_searchController.text.toLowerCase()) || chat.messages.any((message) => message.text.toLowerCase().contains(_searchController.text.toLowerCase()))).toList() : _chats;

    return Scaffold(
      appBar: _buildAppBar(context),
      extendBody: true, // Extend body behind system navigation bar
      body: BackgroundPattern(
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
        child: _chats.isEmpty
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Universe Logo
                      UniverseLogo(
                        size: 140.0,
                        isDarkMode: Theme.of(context).brightness == Brightness.dark,
                      ),
                      const SizedBox(height: 60),
                      
                      // Center input area
                      WelcomeInputArea(
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatInfoStream: _chatInfoStream,
                                  initialMessage: text.trim(),
                                )
                              )
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: currentChatList.length,
                itemBuilder: (context, index) {
                  final chat = currentChatList[index];
                  return ListTile(
                    leading: chat.isPinned ? Icon(Icons.push_pin, color: Theme.of(context).primaryColor, size: 20) : null,
                    title: Text(chat.title, style: TextStyle(fontWeight: chat.isPinned ? FontWeight.w600 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      chat.messages.isEmpty ? 'No messages yet' : _stripMarkdown(chat.messages.last.text),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatTitle: chat.title, initialMessages: chat.messages, chatId: chat.id, isPinned: chat.isPinned, isGenerating: chat.isGenerating, isStopped: chat.isStopped, chatInfoStream: _chatInfoStream))),
                    onLongPress: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      builder: (context) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.push_pin_outlined),
                              title: Text(chat.isPinned ? 'Unpin Chat' : 'Pin Chat'),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
                                  final chatIndex = _chats.indexWhere((c) => c.id == chat.id);
                                  if (chatIndex != -1) _chats[chatIndex] = updatedChat;
                                  _chats.sort((a, b) {
                                    if (a.isPinned && !b.isPinned) return -1;
                                    if (!a.isPinned && b.isPinned) return 1;
                                    return 0;
                                  });
                                  _saveChats();
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('Rename Chat'),
                              onTap: () {
                                Navigator.pop(context);
                                _showRenameDialog(chat, _chats.indexWhere((c) => c.id == chat.id));
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _chats.removeWhere((c) => c.id == chat.id);
                                  _saveChats();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),

      floatingActionButton: _chats.isEmpty ? null : Container(
        margin: const EdgeInsets.only(bottom: 20, right: 4),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatInfoStream: _chatInfoStream))),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_rounded, 
                      size: 16, 
                      color: isLightTheme(context)
                          ? const Color(0xFF374151) // Dark for light mode
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'New Chat', 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: isLightTheme(context)
                          ? const Color(0xFF374151) // Dark for light mode
                          : Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}

// --- HELPER WIDGETS AND FUNCTIONS ---

class WelcomeInputArea extends StatefulWidget {
  final Function(String) onSubmitted;
  const WelcomeInputArea({super.key, required this.onSubmitted});

  @override
  State<WelcomeInputArea> createState() => _WelcomeInputAreaState();
}

class _WelcomeInputAreaState extends State<WelcomeInputArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600), // Limit width on larger screens
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (text) {
                widget.onSubmitted(text);
                _controller.clear();
              },
              textInputAction: TextInputAction.send,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Ask AhamAI anything...',
                hintStyle: TextStyle(
                  color: isLightTheme(context) 
                      ? const Color(0xFF5F6368) // Google secondary text
                      : const Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
                filled: true,
                fillColor: isLightTheme(context) 
                    ? const Color(0xFFE8EAED) // Google search bar background
                    : const Color(0xFF2C2C2E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: isLightTheme(context) 
                        ? const Color(0xFFE8EAED) // Google search bar background (subtle border)
                        : const Color(0xFF333438),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(
                    color: isLightTheme(context) 
                        ? const Color(0xFFE8EAED) // Google search bar background (subtle border)
                        : const Color(0xFF333438),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none, // No border when active
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            radius: 24,
            child: IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.onSubmitted(_controller.text.trim());
                  _controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsScreen extends StatefulWidget {
  final VoidCallback onClearAllChats;
  const ProfileSettingsScreen({super.key, required this.onClearAllChats});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _selectedChatModel = '';
  List<String> _availableModels = [];
  bool _isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAvailableModels();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedChatModel = prefs.getString('chat_model') ?? '';
    });
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await ApiService.getAvailableModels();
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
        
        // If no model is selected, use the first available model
        if (_selectedChatModel.isEmpty && models.isNotEmpty) {
          _selectedChatModel = models.first;
          _saveChatModel(_selectedChatModel);
        }
      });
    } catch (e) {
      setState(() {
        _availableModels = [];
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _saveChatModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_model', model);
    setState(() {
      _selectedChatModel = model;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // AI Model Section
            Text(
              'Chat AI Model',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select AI Model',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Dynamic model list from API
                    if (_isLoadingModels)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_availableModels.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No models available. Please check your connection.',
                          style: TextStyle(color: getSecondaryTextColor(context)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._availableModels.map((model) => RadioListTile<String>(
                        title: Text(
                          _getModelDisplayName(model),
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        subtitle: Text(
                          _getModelDescription(model),
                          style: TextStyle(color: getSecondaryTextColor(context)),
                        ),
                        value: model,
                        groupValue: _selectedChatModel,
                        onChanged: (val) => _saveChatModel(val!),
                      )).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data Control Section
            Text(
              'Data Control',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).cardColor,
              child: ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: Theme.of(context).iconTheme.color),
                title: Text(
                  'Clear All Chats',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                subtitle: Text(
                  'Delete all chat history permanently',
                  style: TextStyle(color: getSecondaryTextColor(context)),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onClearAllChats();
                },
              ),
            ),

            const SizedBox(height: 24),

                         // App Info Section
             Text(
               'About',
               style: Theme.of(context).textTheme.titleLarge,
             ),
             const SizedBox(height: 16),
             Card(
               color: Theme.of(context).cardColor,
               child: Column(
                 children: [
                   ListTile(
                     leading: Icon(Icons.info_outline, color: Theme.of(context).iconTheme.color),
                     title: Text(
                       'Version',
                       style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                     ),
                     subtitle: Text(
                       'Latest',
                       style: TextStyle(color: getSecondaryTextColor(context)),
                     ),
                   ),
                   ListTile(
                     leading: Icon(Icons.code, color: Theme.of(context).iconTheme.color),
                     title: Text(
                       'Built with Flutter',
                       style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                     ),
                     subtitle: Text(
                       'AI chat assistant',
                       style: TextStyle(color: getSecondaryTextColor(context)),
                     ),
                   ),
                 ],
               ),
             ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ],
        ),
      ),
    );
  }

  String _getModelDisplayName(String model) {
    // Clean up model names for better display
    switch (model.toLowerCase()) {
      case 'gpt-4o':
        return 'GPT-4o';
      case 'gpt-4o-mini':
        return 'GPT-4o Mini';
      case 'gpt-3.5-turbo':
        return 'GPT-3.5 Turbo';
      case 'deepseek-r1':
        return 'DeepSeek R1';
      case 'claude-3-5-sonnet-20241022':
        return 'Claude 3.5 Sonnet';
      case 'o1-preview':
        return 'OpenAI o1 Preview';
      case 'grok-beta':
        return 'Grok Beta';
      default:
        return model;
    }
  }

  String _getModelDescription(String model) {
    // Provide descriptions for models
    switch (model.toLowerCase()) {
      case 'gpt-4o':
        return 'Advanced multimodal model';
      case 'gpt-4o-mini':
        return 'Fast and efficient model';
      case 'gpt-3.5-turbo':
        return 'Balanced performance model';
      case 'deepseek-r1':
        return 'Advanced reasoning model';
      case 'claude-3-5-sonnet-20241022':
        return 'Best for coding tasks';
      case 'o1-preview':
        return 'Advanced reasoning model';
      case 'grok-beta':
        return 'Experimental model';
      default:
        return 'AI language model';
    }
  }
}

// <-- REMOVED isLightTheme from here, moved to theme.dart


Color _getCategoryColor(String category, BuildContext context) {
  final isDark = !isLightTheme(context);
  const draculaPink = Color(0xFFFF79C6);
  const draculaCyan = Color(0xFF8BE9FD);
  const draculaOrange = Color(0xFFFFB86C);
  const draculaYellow = Color(0xFFF1FA8C);
  const draculaRed = Color(0xFFFF5555);

  switch (category) {
    case 'Coding': return isDark ? draculaGreen.withOpacity(0.3) : Colors.green.shade100;
    case 'Creative': return isDark ? draculaYellow.withOpacity(0.3) : Colors.yellow.shade100;
    case 'Science': return isDark ? draculaCyan.withOpacity(0.3) : Colors.cyan.shade100;
    case 'Health': return isDark ? draculaRed.withOpacity(0.3) : Colors.red.shade100;
    case 'History': return isDark ? draculaOrange.withOpacity(0.3) : Colors.orange.shade100;
    case 'Technology': return isDark ? draculaPink.withOpacity(0.3) : Colors.pink.shade100;
          case 'Travel & Plans': return isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F9FA);
    case 'Weather': return isDark ? const Color(0xFF3C5E7A) : Colors.blue.shade100;
    case 'Facts': return isDark ? draculaComment.withOpacity(0.5) : Colors.blueGrey.shade100;
    default: return isDark ? draculaCurrentLine : Colors.grey.shade200;
  }
}

Color _getCategoryTextColor(String category, BuildContext context) {
  final isDark = !isLightTheme(context);
  const draculaPink = Color(0xFFFF79C6);
  const draculaCyan = Color(0xFF8BE9FD);
  const draculaOrange = Color(0xFFFFB86C);
  const draculaYellow = Color(0xFFF1FA8C);
  const draculaRed = Color(0xFFFF5555);

  switch (category) {
    case 'Coding': return isDark ? draculaGreen : Colors.green.shade800;
    case 'Creative': return isDark ? draculaYellow : Colors.yellow.shade800;
    case 'Science': return isDark ? draculaCyan : Colors.cyan.shade800;
    case 'Health': return isDark ? draculaRed : Colors.red.shade800;
    case 'History': return isDark ? draculaOrange : Colors.orange.shade800;
    case 'Technology': return isDark ? draculaPink : Colors.pink.shade800;
          case 'Travel & Plans': return isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124);
    case 'Weather': return isDark ? Colors.lightBlue.shade100 : Colors.blue.shade800;
    case 'Facts': return isDark ? draculaForeground : Colors.blueGrey.shade800;
    default: return isDark ? draculaComment : Colors.grey.shade800;
  }
}

class HighlightedWelcomeText extends StatelessWidget {
  const HighlightedWelcomeText({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const SizedBox.shrink(), // Empty widget - removed brain icon and AI companion text
    );
  }
}

class ModernStartButton extends StatelessWidget {
  final VoidCallback onPressed;
  const ModernStartButton({required this.onPressed, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_rounded, 
                  size: 18, 
                  color: isLightTheme(context)
                      ? const Color(0xFF374151) // Dark for light mode
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'New Chat', 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: isLightTheme(context)
                      ? const Color(0xFF374151) // Dark for light mode
                      : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to strip markdown formatting for chat preview
String _stripMarkdown(String text) {
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