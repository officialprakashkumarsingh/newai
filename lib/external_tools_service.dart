import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

class ExternalToolsService {
  static const MethodChannel _channel = MethodChannel('com.ahamai.external_tools');

  /// Execute a file creation tool
  static Future<Map<String, dynamic>> executeFileTool({
    required String operation,
    required String fileName,
    required String content,
    String? fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'operation': operation,
        'fileName': fileName,
        'content': content,
        'fileType': fileType,
        'metadata': metadata ?? {},
      };

      final result = await _channel.invokeMethod('executeFileTool', arguments);
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': 'Platform error: ${e.message}',
        'details': e.details,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Execute a communication tool (email, WhatsApp, SMS)
  static Future<Map<String, dynamic>> executeCommunicationTool({
    required String operation,
    required String recipient,
    required String content,
    String? subject,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final Map<String, dynamic> arguments = {
        'operation': operation,
        'recipient': recipient,
        'content': content,
        'subject': subject,
        'metadata': metadata ?? {},
      };

      final result = await _channel.invokeMethod('executeCommunicationTool', arguments);
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      return {
        'success': false,
        'error': 'Platform error: ${e.message}',
        'details': e.details,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Get list of available tools
  static Future<List<String>> getAvailableTools() async {
    try {
      final result = await _channel.invokeMethod('getAvailableTools');
      return List<String>.from(result);
    } catch (e) {
      return [];
    }
  }

  /// Get capabilities of a specific tool
  static Future<Map<String, dynamic>> getToolCapabilities(String toolName) async {
    try {
      final result = await _channel.invokeMethod('getToolCapabilities', {'toolName': toolName});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }
}