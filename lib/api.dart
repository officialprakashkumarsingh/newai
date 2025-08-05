import 'dart:convert';
import 'package:http/http.dart' as http;

// --- CHAT MODELS ---
// Keeping the same structure for compatibility
class ChatModels {
  static const String gemini = 'gpt-4o'; // Default model from new API
  static const String gpt4_1_mini = 'gpt-4o-mini';
  static const String gpt4_1 = 'gpt-4o';
  static const String openai_o3 = 'o1-preview';
  static const String deepseek_r1 = 'deepseek-r1';
  static const String searchGpt = 'gpt-4o';
  static const String grok_3 = 'grok-beta';
  static const String grok_3_mini = 'grok-beta';
  static const String grok_3_fast = 'grok-beta';
  static const String grok_3_mini_fast = 'grok-beta';
  static const String claude_4_sonnet = 'claude-3-5-sonnet-20241022';
}

// --- API CONFIGURATION ---
class ApiConfig {
  // Main API Configuration
  static const String apiBaseUrl = 'https://ahamai-api.officialprakashkrsingh.workers.dev';
  static const String apiKey = 'ahamaibyprakash25';
  
  // Chat configuration (replacing all old endpoints)
  static const String geminiApiKey = apiKey;
  static const String geminiChatModel = ChatModels.gemini;
  static const String geminiVisionModel = 'gpt-4o'; // Vision model
  static const String presentationModelName = 'gpt-4o';
  
  // OpenRouter replacement (now points to our API)
  static const String openRouterApiKey = apiKey;
  static const String openRouterChatUrl = '$apiBaseUrl/v1/chat/completions';
  static const String openRouterModel = ChatModels.deepseek_r1; // For thinking mode
  
  // Grok replacement
  static const String grokApiKey = apiKey;
  static const String grokApiBaseUrl = apiBaseUrl;
  
  // Claude replacement
  static const String claudeApiBaseUrl = apiBaseUrl;
  static const String claudeApiKey = apiKey;
  
  // Thinking mode model
  static const String thinkingModeModel = ChatModels.deepseek_r1;
  
  // Brave Search (keeping for web search functionality)
  static const String braveSearchApiKey = 'BSAGvn27KGywhzSPWjem5a_r41ZYaB2';
  static const String braveSearchUrl = 'https://api.search.brave.com/res/v1/web/search';

  // Note: Pollinations text API removed - now using unified ApiService
  // Image generation now uses OpenAI-compatible endpoint with dynamic models
}

// --- DYNAMIC MODEL FETCHING ---
class ModelService {
  static List<String> _cachedModels = [];
  static DateTime? _lastFetched;
  static const Duration cacheTimeout = Duration(hours: 1);

  static Future<List<String>> getAvailableModels() async {
    // Return cached models if still valid
    if (_cachedModels.isNotEmpty && 
        _lastFetched != null && 
        DateTime.now().difference(_lastFetched!) < cacheTimeout) {
      return _cachedModels;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/v1/models'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final models = (data['data'] as List)
              .map((model) => model['id'] as String)
              .toList();
          
          _cachedModels = models;
          _lastFetched = DateTime.now();
          return models;
        }
      }
      
      // Fallback models if API fails
      return _getFallbackModels();
    } catch (e) {
      print('Error fetching models: $e');
      return _getFallbackModels();
    }
  }

  static List<String> _getFallbackModels() {
    return []; // No fallback models - only use API fetched models
  }

  static Future<String> getDefaultModel() async {
    final models = await getAvailableModels();
    return models.isNotEmpty ? models.first : '';
  }
}

// --- IMAGE API ---
class ImageApi {
  static const String _baseUrl = 'https://ahamai-api.officialprakashkrsingh.workers.dev';
  static const String _apiKey = 'ahamaibyprakash25';

  static Future<List<String>> fetchModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/images/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        final List<dynamic> modelsData = responseJson['data'] ?? [];
        final models = modelsData.map((model) => model['id'] as String).toList();
        return models.isNotEmpty ? models : ['flux']; // Default fallback
      } else {
        return ['flux']; // Fallback
      }
    } catch (e) {
      print("Error fetching image models: $e");
      return ['flux']; // Fallback
    }
  }

  static Future<String> generateImage(String prompt, {String? model}) async {
    try {
      final selectedModel = model ?? 'flux';
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': selectedModel,
          'prompt': prompt,
          'n': 1,
          'size': '512x512',
        }),
      );

      if (response.statusCode == 200) {
        // Check if response is image data (binary) or JSON
        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.startsWith('image/')) {
          // Response is direct image data, convert to base64 data URL
          final base64Image = base64Encode(response.bodyBytes);
          final mimeType = contentType.split(';')[0]; // Remove any additional parameters
          return 'data:$mimeType;base64,$base64Image';
        } else {
          // Try to parse as JSON (standard OpenAI format)
          try {
            final Map<String, dynamic> responseJson = jsonDecode(response.body);
            final List<dynamic> data = responseJson['data'] ?? [];
            if (data.isNotEmpty) {
              return data[0]['url'] as String;
            }
          } catch (jsonError) {
            print("Failed to parse JSON response: $jsonError");
          }
        }
      }
      throw Exception('Failed to generate image: ${response.statusCode}');
    } catch (e) {
      print("Error generating image: $e");
      throw Exception('Image generation failed: $e');
    }
  }

  // Deprecated: Use generateImage() instead
  static String getImageUrl(String prompt, {String? model}) {
    // This method is kept for backward compatibility but should be replaced
    // with async generateImage() method
    return 'placeholder_url_will_be_replaced_async';
  }
}