class ChatMessage {
  final String role;
  final String text;
  final List<int>? imageBytes;
  final MessageType? type;
  final String? imageUrl;
  final List<dynamic>? slides;
  final List<SearchResult>? searchResults;
  final String? thinkingContent;

  ChatMessage({
    required this.role,
    required this.text,
    this.imageBytes,
    this.type,
    this.imageUrl,
    this.slides,
    this.searchResults,
    this.thinkingContent,
  });
}

enum MessageType {
  text,
  image,
  presentation,
}

class ChatInfo {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final bool isPinned;
  final bool isGenerating;
  final bool isStopped;
  final String category;

  ChatInfo({
    required this.id,
    required this.title,
    required this.messages,
    required this.isPinned,
    required this.isGenerating,
    required this.isStopped,
    required this.category,
  });
}

class SearchResult {
  final String title;
  final String url;
  final String snippet;

  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });
}

class ChatAttachment {
  final String name;
  final String content;
  final String type;

  ChatAttachment({
    required this.name,
    required this.content,
    required this.type,
  });
}