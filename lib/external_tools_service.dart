import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

class ExternalToolsService {
  static const MethodChannel _channel = MethodChannel('com.ahamai.external_tools');
  
  static Future<Map<String, dynamic>> executeFileTool({
    required String operation,
    required String fileName,
    required String content,
    String? fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _channel.invokeMethod('executeFileTool', {
        'operation': operation,
        'fileName': fileName,
        'content': content,
        'fileType': fileType,
        'metadata': metadata ?? {},
      });
      
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'success': false,
        'error': 'File tool execution failed: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> executeCommunicationTool({
    required String operation,
    required String recipient,
    required String content,
    String? subject,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _channel.invokeMethod('executeCommunicationTool', {
        'operation': operation,
        'recipient': recipient,
        'content': content,
        'subject': subject,
        'metadata': metadata ?? {},
      });
      
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'success': false,
        'error': 'Communication tool execution failed: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> listAvailableTools() async {
    try {
      final result = await _channel.invokeMethod('listAvailableTools');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to list tools: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> getToolCapabilities(String toolName) async {
    try {
      final result = await _channel.invokeMethod('getToolCapabilities', {
        'toolName': toolName,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get tool capabilities: $e',
      };
    }
  }
}