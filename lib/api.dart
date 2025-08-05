import 'dart:convert';
import 'package:http/http.dart' as http;

// --- API CONFIGURATION ---
class ApiConfig {
  // Main API Configuration
  static const String apiBaseUrl = 'https://ahamai-api.officialprakashkrsingh.workers.dev';
  static const String apiKey = 'ahamaibyprakash25';
  static const String chatUrl = '$apiBaseUrl/v1/chat/completions';
  static const String modelsUrl = '$apiBaseUrl/v1/models';
  
  // Thinking Mode Model
  static const String thinkingModeModel = 'deepseek-r1';
  
  // Brave Search (keeping for web search functionality)
  static const String braveSearchApiKey = 'BSAGvn27KGywhzSPWjem5a_r41ZYaB2';
  static const String braveSearchUrl = 'https://api.search.brave.com/res/v1/web/search';

  // Pollinations (keeping for image generation)
  static String getPollinationsChatUrl(String prompt, String modelName) {
    final encodedPrompt = Uri.encodeComponent(prompt);
    return 'https://text.pollinations.ai/$encodedPrompt';
  }
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
        Uri.parse(ApiConfig.modelsUrl),
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
    return [
      'gpt-4o',
      'gpt-4o-mini',
      'claude-3-5-sonnet-20241022',
      'deepseek-r1',
      'gemini-2.0-flash-exp',
    ];
  }

  static Future<String> getDefaultModel() async {
    final models = await getAvailableModels();
    return models.isNotEmpty ? models.first : 'gpt-4o';
  }
}

// --- IMAGE API (keeping existing Pollinations) ---
class ImageApi {
  static const String _baseUrl = 'https://image.pollinations.ai';

  static Future<List<String>> fetchModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/models'));
      if (response.statusCode == 200) {
        final List<dynamic> modelsJson = jsonDecode(response.body);
        final models = modelsJson.cast<String>();
        if (models.contains('flux')) {
          models.remove('flux');
          models.insert(0, 'flux');
        }
        return models;
      } else {
        return ['flux', 'sdxl', 'dall-e-3']; // Fallback
      }
    } catch (e) {
      print("Error fetching image models: $e");
      return ['flux', 'sdxl', 'dall-e-3']; // Fallback
    }
  }

  static String getImageUrl(String prompt, {String? model}) {
    final encodedPrompt = Uri.encodeComponent(prompt);
    var url = '$_baseUrl/prompt/$encodedPrompt?nologo=true&width=512&height=512';
    if (model != null && model.isNotEmpty && model != 'flux') {
      url += '&model=${Uri.encodeComponent(model)}';
    }
    return url;
  }
}