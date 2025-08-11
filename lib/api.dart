import 'dart:convert';
import 'package:http/http.dart' as http;

// --- CHAT MODELS ---
// Only keep thinking mode model hardcoded
class ChatModels {
  static const String deepseek_r1 = 'deepseek-r1';
}

// --- API CONFIGURATION ---
class ApiConfig {
  // Main API Configuration
  static const String apiBaseUrl = 'https://ahamai-api.officialprakashkrsingh.workers.dev';
  static const String apiKey = 'ahamaibyprakash25';
  
  // Thinking mode model (only hardcoded model allowed)
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
        return models;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching image models: $e");
      return [];
    }
  }

  static Future<String> generateImage(String prompt, {String? model}) async {
    try {
      // Use specific model or fallback to working models
      String selectedModel;
      if (model != null && model.isNotEmpty) {
        selectedModel = model;
      } else {
        final availableModels = await fetchModels();
        if (availableModels.isEmpty) {
          // Fallback to known working models
          selectedModel = 'flux';
          print("⚠️ No models available from API, falling back to flux");
        } else {
          selectedModel = availableModels.first;
        }
      }
      
      print("🎨 Generating image with model: $selectedModel, prompt: $prompt");
      
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
          // Removed 'size' parameter - API uses default size
        }),
      );

      print("📡 Image generation response status: ${response.statusCode}");
      print("📡 Image generation response headers: ${response.headers}");

      if (response.statusCode == 200) {
        // Check if response is image data (binary) or JSON
        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.startsWith('image/')) {
          // Response is direct image data (flux/turbo models)
          try {
            if (response.bodyBytes.isEmpty) {
              throw Exception('Empty image response');
            }
            
            final base64Image = base64Encode(response.bodyBytes);
            final mimeType = contentType.split(';')[0].trim(); // Remove any additional parameters
            print("✅ Successfully generated image with $selectedModel, size: ${response.bodyBytes.length} bytes, type: $mimeType");
            
            // Return data URL for immediate display
            return 'data:$mimeType;base64,$base64Image';
          } catch (e) {
            print("Error encoding image to base64: $e");
            throw Exception('Failed to encode image data: $e');
          }
        } else {
          // Try to parse as JSON (img3/img4/uncen/gemini2.0 models)
          try {
            final Map<String, dynamic> responseJson = jsonDecode(response.body);
            final List<dynamic> data = responseJson['data'] ?? [];
            if (data.isNotEmpty && data[0]['url'] != null) {
              final imageUrl = data[0]['url'] as String;
              print("✅ Successfully generated image with $selectedModel, URL: $imageUrl");
              return imageUrl;
            } else {
              throw Exception('No valid image URL in JSON response');
            }
          } catch (jsonError) {
            print("Failed to parse JSON response: $jsonError");
            print("Response body: ${response.body}");
            throw Exception('Invalid JSON response: $jsonError');
          }
        }
      }
      
      // Handle error responses
      String errorMessage;
      try {
        final errorJson = jsonDecode(response.body);
        errorMessage = errorJson['error'] ?? 'Unknown error';
      } catch (e) {
        errorMessage = response.body.isEmpty ? 'Empty response' : response.body;
      }
      
      print("❌ Image generation error response body: ${response.body}");
      
      // Retry with flux model if original model failed and it wasn't flux
      if (selectedModel != 'flux' && (response.statusCode == 503 || response.statusCode == 500)) {
        print("🔄 Retrying with flux model due to ${response.statusCode} error...");
        try {
          return await generateImage(prompt, model: 'flux');
        } catch (retryError) {
          print("❌ Retry with flux also failed: $retryError");
        }
      }
      
      throw Exception('API returned ${response.statusCode}: $errorMessage');
    } catch (e) {
      print("❌ Error generating image: $e");
      
      // If it's not a retry and not already using flux, try flux as fallback
      if (model != 'flux' && selectedModel != 'flux') {
        print("🔄 Attempting fallback to flux model...");
        try {
          return await generateImage(prompt, model: 'flux');
        } catch (fallbackError) {
          print("❌ Fallback to flux also failed: $fallbackError");
        }
      }
      
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