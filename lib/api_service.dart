import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://ahamai-api.officialprakashkrsingh.workers.dev';
  static const String _apiKey = 'ahamaibyprakash25';
  static const String _thinkingModeModel = 'deepseek-r1';
  
  // Cache for models
  static List<String> _cachedModels = [];
  static DateTime? _lastModelsFetch;
  static const Duration _cacheTimeout = Duration(hours: 1);
  
  /// Fetch available models from the API
  static Future<List<String>> getAvailableModels() async {
    // Return cached models if still valid
    if (_cachedModels.isNotEmpty && 
        _lastModelsFetch != null && 
        DateTime.now().difference(_lastModelsFetch!) < _cacheTimeout) {
      return _cachedModels;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final models = (data['data'] as List)
              .map((model) => model['id'] as String)
              .where((id) => id.isNotEmpty)
              .toList();
          
          if (models.isNotEmpty) {
            _cachedModels = models;
            _lastModelsFetch = DateTime.now();
            return models;
          }
        }
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    
    // Return empty list if API fails - no fallbacks
    return [];
  }
  
  /// Get the default model (first available)
  static Future<String> getDefaultModel() async {
    final models = await getAvailableModels();
    return models.isNotEmpty ? models.first : '';
  }
  
  /// Send a chat message with streaming response
  static Stream<String> sendChatMessage({
    required String message,
    required String model,
    bool isThinkingMode = false,
    List<Map<String, dynamic>>? conversationHistory,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async* {
    try {
      // Use thinking mode model if enabled, otherwise use user-selected model
      final selectedModel = isThinkingMode ? _thinkingModeModel : model;
      
      // Build messages array
      final messages = <Map<String, dynamic>>[];
      
      // Add system prompt if provided
      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        print('🔍 API SERVICE: Adding system prompt (length: ${systemPrompt.length})');
        print('🔍 API SERVICE: System prompt contains "screenshot": ${systemPrompt.toLowerCase().contains('screenshot')}');
        print('🔍 API SERVICE: System prompt contains "mshots": ${systemPrompt.toLowerCase().contains('mshots')}');
        print('🔍 API SERVICE: First 200 chars: ${systemPrompt.substring(0, math.min(200, systemPrompt.length))}...');
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      } else {
        print('❌ API SERVICE: No system prompt provided! systemPrompt = $systemPrompt');
      }
      
      // Add conversation history
      if (conversationHistory != null) {
        messages.addAll(conversationHistory);
      }
      
      // Add current message
      messages.add({
        'role': 'user',
        'content': message,
      });
      
      final requestBody = {
        'model': selectedModel,
        'messages': messages,
        'stream': true,
        'temperature': 0.7,
      };
      
      // Add tools if provided
      if (tools != null && tools.isNotEmpty) {
        requestBody['tools'] = tools;
        requestBody['tool_choice'] = 'auto';
      }
      
      final request = http.Request('POST', Uri.parse('$_baseUrl/v1/chat/completions'))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        })
        ..body = jsonEncode(requestBody);
      
      final client = http.Client();
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        yield* Stream.error('API Error: ${response.statusCode} ${response.reasonPhrase}');
        return;
      }
      
      // Handle SSE streaming response
      String buffer = '';
      bool isFirstChunk = true;
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // Process complete lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);
          
          if (line.isEmpty) continue;
          
          // Handle SSE format
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            
            // Check for end of stream
            if (data == '[DONE]') {
              client.close();
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              
              if (choices != null && choices.isNotEmpty) {
                final choice = choices[0];
                final delta = choice['delta'];
                
                if (delta != null && delta['content'] != null) {
                  final content = delta['content'] as String;
                  if (content.isNotEmpty) {
                    yield content;
                  }
                }
                
                // Check if finished
                final finishReason = choice['finish_reason'];
                if (finishReason != null && finishReason != 'null') {
                  client.close();
                  return;
                }
              }
            } catch (e) {
              // Skip invalid JSON chunks - common in streaming
              continue;
            }
          }
        }
      }
      
      client.close();
    } catch (e) {
      yield* Stream.error('Streaming error: $e');
    }
  }
  
  /// Send a vision message (image + text)
  static Stream<String> sendVisionMessage({
    required String message,
    required String imageBase64,
    String? model,
  }) async* {
    try {
      if (model == null || model.isEmpty) {
      throw Exception('No model specified for vision generation');
    }
    final selectedModel = model;
      
      final requestBody = {
        'model': selectedModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': message,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$imageBase64',
                },
              },
            ],
          }
        ],
        'stream': true,
      };
      
      final request = http.Request('POST', Uri.parse('$_baseUrl/v1/chat/completions'))
        ..headers.addAll({
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode(requestBody);
      
      final client = http.Client();
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        yield* Stream.error('Vision API Error: ${response.statusCode}');
        return;
      }
      
      String buffer = '';
      
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);
          
          if (line.isEmpty) continue;
          
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            
            if (data == '[DONE]') {
              client.close();
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'];
                if (delta != null && delta['content'] != null) {
                  final content = delta['content'] as String;
                  if (content.isNotEmpty) {
                    yield content;
                  }
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      client.close();
    } catch (e) {
      yield* Stream.error('Vision streaming error: $e');
    }
  }
  
  /// Test API connection
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/models'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get API status and info
  static Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final models = await getAvailableModels();
      final isConnected = await testConnection();
      
      return {
        'connected': isConnected,
        'baseUrl': _baseUrl,
        'modelCount': models.length,
        'models': models,
        'thinkingModel': _thinkingModeModel,
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }
}