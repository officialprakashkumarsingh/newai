import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // <-- ADDED: For Uint8List
import 'package:ahamai/web_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- FIXED: Correct import path
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'chat_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AhamApp(),
    ),
  );
}

class AhamApp extends StatelessWidget {
  const AhamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, child) {
        final systemIconBrightness = theme.themeMode == ThemeMode.light ? Brightness.dark : Brightness.light;
        final navBarColor = theme.themeMode == ThemeMode.light
            ? ThemeNotifier.lightTheme.scaffoldBackgroundColor
            : ThemeNotifier.darkTheme.scaffoldBackgroundColor;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarIconBrightness: systemIconBrightness,
          systemNavigationBarIconBrightness: systemIconBrightness,
          systemNavigationBarColor: navBarColor,
        ));

        return MaterialApp(
          title: 'AhamAI',
          debugShowCheckedModeBanner: false,
          theme: ThemeNotifier.lightTheme,
          darkTheme: ThemeNotifier.darkTheme,
          themeMode: theme.themeMode,
          home: const HomeScreen(),
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
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'type': type.name,
        'imageUrl': imageUrl,
        'slides': slides,
        'searchResults': searchResults?.map((r) => r.toJson()).toList(),
        'attachedFileName': attachedFileName,
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
  const HomeScreen({super.key});
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ProfileSettingsSheet(onClearAllChats: _clearAllChats),
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
        leading: IconButton(icon: const Icon(Icons.person_outline), onPressed: () => _showProfileSheet(context), tooltip: 'Profile & Settings'),
        title: const Text('AhamAI'),
        centerTitle: true,
        actions: [if (_chats.isNotEmpty) IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)), const SizedBox(width: 4)],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      {'text': 'Ask about the weather', 'icon': Icons.wb_sunny},
      {'text': 'Get help with coding', 'icon': Icons.code},
      {'text': 'Explore fun facts', 'icon': Icons.lightbulb_outline},
      {'text': 'Plan a trip itinerary', 'icon': Icons.map},
    ];
    final currentChatList = _isSearching ? _chats.where((chat) => chat.title.toLowerCase().contains(_searchController.text.toLowerCase()) || chat.messages.any((message) => message.text.toLowerCase().contains(_searchController.text.toLowerCase()))).toList() : _chats;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _chats.isEmpty
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HighlightedWelcomeText(),
                    const SizedBox(height: 32),
                    // "Start with?" text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Start with?',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Suggestions in 2x2 grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // First row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSuggestionCard(context, suggestions[0]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSuggestionCard(context, suggestions[1]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Second row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSuggestionCard(context, suggestions[2]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSuggestionCard(context, suggestions[3]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ModernStartButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatInfoStream: _chatInfoStream)))),
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
                  title: Row(
                    children: [
                      Expanded(child: Text(chat.title, style: TextStyle(fontWeight: chat.isPinned ? FontWeight.w600 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _getCategoryColor(chat.category, context), borderRadius: BorderRadius.circular(10)), child: Text(chat.category, style: TextStyle(fontSize: 12, color: _getCategoryTextColor(chat.category, context), fontWeight: FontWeight.w500))),
                    ],
                  ),
                                      subtitle: Text(
                      chat.messages.isEmpty ? 'No messages yet' : chat.messages.last.text,
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
                            leading: const Icon(Icons.drive_file_rename_outline),
                            title: const Text('Rename Chat'),
                            onTap: () {
                              Navigator.pop(context);
                              final originalIndex = _chats.indexWhere((c) => c.id == chat.id);
                              if (originalIndex != -1) {
                                _showRenameDialog(chat, originalIndex);
                              }
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Delete Chat'),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() => _chats.removeWhere((c) => c.id == chat.id));
                              _saveChats();
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'New Chat', 
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildSuggestionCard(BuildContext context, Map<String, dynamic> suggestion) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(initialMessage: suggestion['text'], chatInfoStream: _chatInfoStream))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              suggestion['icon'],
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              suggestion['text'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER WIDGETS AND FUNCTIONS ---

class ProfileSettingsSheet extends StatefulWidget {
  final VoidCallback onClearAllChats;
  const ProfileSettingsSheet({super.key, required this.onClearAllChats});

  @override
  State<ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<ProfileSettingsSheet> {
  String _selectedChatModel = '';
  List<String> _availableModels = [];
  bool _isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedChatModel = prefs.getString('chat_model') ?? ChatModels.gemini;
    });
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Profile & Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Data Control', style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade400),
              title: Text('Clear All Chats', style: TextStyle(color: Colors.red.shade400)),
              onTap: widget.onClearAllChats,
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Chat AI Model', style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gemini 2.5 Flash'),
              subtitle: const Text('depth and good response'),
              value: ChatModels.gemini,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('GPT 4.1 Mini'),
              subtitle: const Text('Creative model'),
              value: ChatModels.gpt4_1_mini,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('GPT 4.1'),
              subtitle: const Text('Advanced creative model'),
              value: ChatModels.gpt4_1,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('OpenAI O3'),
              subtitle: const Text('Advanced reasoning model'),
              value: ChatModels.openai_o3,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('DeepSeek R1 0528'),
              subtitle: const Text('Advanced reasoning model'),
              value: ChatModels.deepseek_r1,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('SearchGPT'),
              subtitle: const Text('Web-connected search model'),
              value: ChatModels.searchGpt,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Grok 3'),
              subtitle: const Text('Stable'),
              value: ChatModels.grok_3,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Grok 3 Mini'),
              subtitle: const Text('Stable'),
              value: ChatModels.grok_3_mini,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Grok 3 Fast'),
              subtitle: const Text('Stable, fast'),
              value: ChatModels.grok_3_fast,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Grok 3 Mini Fast'),
              subtitle: const Text('Stable, mini, fast'),
              value: ChatModels.grok_3_mini_fast,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Claude 4 Sonnet'),
              subtitle: const Text('Best for coding'),
              value: ChatModels.claude_4_sonnet,
              groupValue: _selectedChatModel,
              onChanged: (val) => _saveChatModel(val!),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
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
    case 'Travel & Plans': return isDark ? draculaPurple.withOpacity(0.3) : Colors.purple.shade100;
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
    case 'Travel & Plans': return isDark ? draculaPurple : Colors.purple.shade800;
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'New Chat', 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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