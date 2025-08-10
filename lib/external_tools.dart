import 'dart:convert';
import 'package:flutter/material.dart';
import 'main.dart';
import 'api_service.dart';
import 'presentation_service.dart';
import 'diagram_service.dart';
import 'web_search.dart';
import 'api.dart';
import 'global_system_prompt.dart';

/// External Tools Manager - Handles all AI function calling for various features
/// Provides tools for: presentation generation, web search, diagram creation, and image generation
class ExternalToolsManager {
  
  /// Get system prompt with tool definitions and screenshot feature
  /// @deprecated Use GlobalSystemPrompt.getGlobalSystemPrompt() instead
  static String getSystemPromptWithTools() {
    return GlobalSystemPrompt.getGlobalSystemPrompt(
      isThinkingMode: false,
      isResearchMode: false,
      includeTools: true,
    );
  }

  /// Get tool definitions for the API
  /// @deprecated Use GlobalSystemPrompt.getToolDefinitions() instead
  static List<Map<String, dynamic>> getToolDefinitions() {
    return GlobalSystemPrompt.getToolDefinitions();
  }

  /// Execute a tool function call
  static Future<Map<String, dynamic>> executeTool({
    required String functionName,
    required Map<String, dynamic> arguments,
    required BuildContext context,
    required String selectedModel,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required List<ChatMessage> messages,
  }) async {
    try {
      switch (functionName) {
        case 'generate_presentation':
          return await _handlePresentationGeneration(
            arguments, context, selectedModel, addMessage, updateMessage, messages
          );
        
        case 'search_web':
          return await _handleWebSearch(arguments);
        
        case 'create_diagram':
          return await _handleDiagramCreation(
            arguments, context, selectedModel, addMessage, updateMessage, messages
          );
        
        case 'generate_image':
          return await _handleImageGeneration(
            arguments, context, selectedModel, addMessage, updateMessage, messages
          );
        

        default:
          return {
            'success': false,
            'error': 'Unknown function: $functionName'
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Tool execution failed: $e'
      };
    }
  }

  /// Handle presentation generation tool call
  static Future<Map<String, dynamic>> _handlePresentationGeneration(
    Map<String, dynamic> arguments,
    BuildContext context,
    String selectedModel,
    Function(ChatMessage) addMessage,
    Function(int, ChatMessage) updateMessage,
    List<ChatMessage> messages,
  ) async {
    try {
      final topic = arguments['topic'] as String;
      final slideCount = arguments['slide_count'] as int? ?? 8;
      
      // Add user message
      addMessage(ChatMessage(role: 'user', text: 'Generate presentation: $topic'));
      
      // Add placeholder for AI response
      addMessage(ChatMessage(role: 'model', text: '', type: MessageType.presentation));
      
      // Generate presentation
      final presentationData = await PresentationService.generatePresentationData(topic, selectedModel);
      
      // Update with results
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(
        role: 'model',
        text: '',
        type: MessageType.presentation,
        presentationData: presentationData ?? <String, dynamic>{},
      ));
      
      return {
        'success': true,
        'data': presentationData,
        'message': 'Presentation generated successfully for: $topic'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to generate presentation: $e'
      };
    }
  }

  /// Handle web search tool call
  static Future<Map<String, dynamic>> _handleWebSearch(Map<String, dynamic> arguments) async {
    try {
      final query = arguments['query'] as String;
      final maxResults = arguments['max_results'] as int? ?? 5;
      
      final searchResponse = await WebSearchService.search(query);
      
      if (searchResponse != null && searchResponse.results.isNotEmpty) {
        final results = searchResponse.results.take(maxResults).map((r) => {
          'title': r.title,
          'snippet': r.snippet,
          'url': r.url,
        }).toList();
        
        return {
          'success': true,
          'data': results,
          'message': 'Found ${results.length} search results for: $query'
        };
      } else {
        return {
          'success': false,
          'error': 'No search results found for: $query'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Web search failed: $e'
      };
    }
  }

  /// Handle diagram creation tool call
  static Future<Map<String, dynamic>> _handleDiagramCreation(
    Map<String, dynamic> arguments,
    BuildContext context,
    String selectedModel,
    Function(ChatMessage) addMessage,
    Function(int, ChatMessage) updateMessage,
    List<ChatMessage> messages,
  ) async {
    try {
      final description = arguments['description'] as String;
      final chartType = arguments['chart_type'] as String? ?? 'auto';
      
      // Add user message
      addMessage(ChatMessage(role: 'user', text: 'Create diagram: $description'));
      
      // Add placeholder for AI response
      addMessage(ChatMessage(role: 'model', text: '', type: MessageType.diagram, diagramData: null));
      
      // Generate diagram
      final diagramData = await DiagramService.generateDiagramData(description, selectedModel);
      
      // Update with results
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(
        role: 'model',
        text: '',
        type: MessageType.diagram,
        diagramData: diagramData ?? <String, dynamic>{},
      ));
      
      return {
        'success': true,
        'data': diagramData,
        'message': 'Diagram created successfully: $description'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create diagram: $e'
      };
    }
  }

  /// Handle image generation tool call
  static Future<Map<String, dynamic>> _handleImageGeneration(
    Map<String, dynamic> arguments,
    BuildContext context,
    String selectedModel,
    Function(ChatMessage) addMessage,
    Function(int, ChatMessage) updateMessage,
    List<ChatMessage> messages,
  ) async {
    try {
      final prompt = arguments['prompt'] as String;
      final model = arguments['model'] as String? ?? 'dall-e-3';
      
      // Add user message
      addMessage(ChatMessage(role: 'user', text: 'Generate image: $prompt'));
      
      // Add placeholder for AI response
      addMessage(ChatMessage(role: 'model', text: '', type: MessageType.image));
      
      // Generate image
      final imageUrl = await ImageApi.generateImage(prompt, model: model);
      
      // Update with results
      final lastIndex = messages.length - 1;
      updateMessage(lastIndex, ChatMessage(
        role: 'model',
        text: '',
        type: MessageType.image,
        imageUrl: imageUrl,
      ));
      
      return {
        'success': true,
        'data': {'imageUrl': imageUrl},
        'message': 'Image generated successfully: $prompt'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to generate image: $e'
      };
    }
  }

  /// Parse tool calls from AI response
  static List<Map<String, dynamic>> parseToolCalls(String aiResponse) {
    final toolCalls = <Map<String, dynamic>>[];
    
    // Look for function call patterns in the response
    final functionCallRegex = RegExp(r'<function_call>(.*?)</function_call>', dotAll: true);
    final matches = functionCallRegex.allMatches(aiResponse);
    
    for (final match in matches) {
      try {
        final functionCallJson = match.group(1)?.trim();
        if (functionCallJson != null) {
          final functionCall = jsonDecode(functionCallJson);
          toolCalls.add(functionCall);
        }
      } catch (e) {
        print('Error parsing function call: $e');
      }
    }
    
    return toolCalls;
  }

  /// Generate URL for website screenshots
  static String generateScreenshotUrl(String websiteUrl) {
    // Encode the URL for the screenshot service
    final encodedUrl = Uri.encodeComponent(websiteUrl);
    return 'https://s.wordpress.com/mshots/v1/$encodedUrl?w=1920&h=1080';
  }

  /// Check if a message contains a tool call request
  static bool containsToolRequest(String message) {
    final toolKeywords = [
      'generate presentation', 'create presentation', 'make slides',
      'search web', 'search internet', 'look up', 'find information',
      'create diagram', 'make chart', 'generate chart', 'draw diagram',
      'generate image', 'create image', 'make picture', 'draw image',
      'screenshot', 'capture website', 'website screenshot'
    ];
    
    final lowerMessage = message.toLowerCase();
    return toolKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Get tool usage examples for help
  static String getToolUsageExamples() {
    return '''
## Tool Usage Examples:

**Presentations:**
- "Generate a presentation about renewable energy"
- "Create slides on machine learning basics"
- "Make a presentation about space exploration with 10 slides"

**Web Search:**
- "Search for latest news about AI developments"
- "Look up current cryptocurrency prices"
- "Find information about climate change solutions"

**Diagrams:**
- "Create a bar chart showing sales data"
- "Make a flowchart for user registration process"
- "Generate an organizational chart for my company"

**Image Generation:**
- "Generate an image of a futuristic city"
- "Create a logo for my coffee shop"
- "Make a picture of a sunset over mountains"

**Website Screenshots:**
- "Take a screenshot of google.com"
- "Show me what apple.com looks like"
- "Capture the homepage of github.com"
''';
  }
}

/// Tool execution result wrapper
class ToolExecutionResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;
  final String? error;

  ToolExecutionResult({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ToolExecutionResult.fromMap(Map<String, dynamic> map) {
    return ToolExecutionResult(
      success: map['success'] ?? false,
      data: map['data'],
      message: map['message'],
      error: map['error'],
    );
  }
}

/// Enhanced API service for tool calling
class ToolAwareApiService extends ApiService {
  
  /// Send chat message with tool support
  static Stream<String> sendChatMessageWithTools({
    required String message,
    required String model,
    required BuildContext context,
    required Function(ChatMessage) addMessage,
    required Function(int, ChatMessage) updateMessage,
    required List<ChatMessage> messages,
    bool isThinkingMode = false,
    List<Map<String, dynamic>>? conversationHistory,
  }) async* {
    // Check if the message might benefit from tools
    final shouldUseTools = ExternalToolsManager.containsToolRequest(message);
    
    if (shouldUseTools) {
      // Use system prompt with tool definitions
      final systemPrompt = ExternalToolsManager.getSystemPromptWithTools();
      final tools = ExternalToolsManager.getToolDefinitions();
      
      // Send request with tool definitions
      yield* ApiService.sendChatMessage(
        message: message,
        model: model,
        isThinkingMode: isThinkingMode,
        conversationHistory: conversationHistory,
        systemPrompt: systemPrompt,
        tools: tools,
      );
    } else {
      // Regular chat message without tools
      yield* ApiService.sendChatMessage(
        message: message,
        model: model,
        isThinkingMode: isThinkingMode,
        conversationHistory: conversationHistory,
      );
    }
  }


}