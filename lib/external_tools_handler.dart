import 'dart:async';
import 'package:flutter/material.dart';
import 'external_tools_service.dart';
import 'external_tools_integration.dart';

class ExternalToolsHandler {
  String? _lastCreatedFilePath;
  final Function(String) _addMessage;

  ExternalToolsHandler(this._addMessage);

  /// Check if AI response contains tool usage and handle it
  Future<void> checkAndHandleToolUsage(String aiResponse) async {
    final toolUsage = ExternalToolsIntegration.detectToolUsage(aiResponse);
    if (toolUsage != null) {
      await _handleToolUsage(toolUsage);
    }
  }

  /// Handle detected tool usage
  Future<void> _handleToolUsage(Map<String, dynamic> toolUsage) async {
    final action = toolUsage['action'] as String;
    final response = toolUsage['response'] as String;
    
    print('🔧 Tool usage detected: $action');
    
    try {
      switch (action) {
        case 'create_file':
          await _handleFileCreationTool(response);
          break;
        case 'send_email':
          await _handleEmailTool(response);
          break;
        case 'send_whatsapp':
          await _handleWhatsAppTool(response);
          break;
        case 'send_sms':
          await _handleSMSTool(response);
          break;
        case 'share_file':
          await _handleShareFileTool(response);
          break;
      }
    } catch (e) {
      print('❌ Tool execution failed: $e');
      _addMessage('Tool execution failed: $e');
    }
  }

  /// Handle file creation tool
  Future<void> _handleFileCreationTool(String aiResponse) async {
    // Extract file details from AI response
    final fileName = _extractFileName(aiResponse) ?? 'ai_generated_file.txt';
    final content = _extractFileContent(aiResponse) ?? aiResponse;
    final fileType = _extractFileType(fileName);
    
    _addMessage('🔧 Creating file: $fileName...');
    
    final result = await ExternalToolsService.executeFileTool(
      operation: 'create',
      fileName: fileName,
      content: content,
      fileType: fileType,
      metadata: {
        'created_by': 'AI Assistant',
        'timestamp': DateTime.now().toIso8601String(),
        'title': _extractFileTitle(aiResponse) ?? 'AI Generated Document',
      },
    );
    
    if (result['success'] == true) {
      final filePath = result['file_path'] as String?;
      final fileName = result['file_name'] as String?;
      final fileSize = result['file_size'] as int?;
      final fileType = result['file_type'] as String?;
      final isExternal = result['is_external'] as bool? ?? false;
      final folderPath = result['folder_path'] as String? ?? 'Unknown';
      final sizeText = fileSize != null ? ' (${(fileSize / 1024).toStringAsFixed(1)} KB)' : '';
      
      // Show file creation success with location
      _addMessage('✅ File created successfully!\n📁 ${fileName ?? 'File'}$sizeText\n📂 Saved in: $folderPath\n🎯 Format: ${fileType?.toUpperCase() ?? 'TXT'}');
      
      // Store the file path for potential sharing
      if (filePath != null) {
        _lastCreatedFilePath = filePath;
        _addMessage('💡 You can now say "share this file via email" or "send this file to someone" to share it!');
      }
    } else {
      _addMessage('❌ Failed to create file: ${result['error']}');
    }
  }

  /// Handle email tool
  Future<void> _handleEmailTool(String aiResponse) async {
    final recipient = _extractEmailRecipient(aiResponse) ?? '';
    final subject = _extractEmailSubject(aiResponse) ?? 'Message from AI Assistant';
    final content = _extractEmailContent(aiResponse) ?? aiResponse;
    
    if (recipient.isEmpty) {
      _addMessage('⚠️ Please specify an email address.');
      return;
    }
    
    final result = await ExternalToolsService.executeCommunicationTool(
      operation: 'send_email',
      recipient: recipient,
      content: content,
      subject: subject,
    );
    
    if (result['success'] == true) {
      final method = result['method'] ?? 'email';
      _addMessage('📧 Email app opened successfully for $recipient\n🔧 Method: $method');
    } else {
      String errorMessage = '❌ Failed to open email: ${result['error']}';
      
      // Add suggestions if available
      if (result['suggestions'] != null) {
        final suggestions = result['suggestions'] as List;
        errorMessage += '\n\n💡 Suggestions:\n';
        for (final suggestion in suggestions) {
          errorMessage += '• $suggestion\n';
        }
      }
      
      _addMessage(errorMessage);
    }
  }

  /// Handle WhatsApp tool
  Future<void> _handleWhatsAppTool(String aiResponse) async {
    final recipient = _extractPhoneNumber(aiResponse) ?? '';
    final content = _extractWhatsAppContent(aiResponse) ?? aiResponse;
    
    if (recipient.isEmpty) {
      _addMessage('⚠️ Please specify a phone number for WhatsApp.');
      return;
    }
    
    final result = await ExternalToolsService.executeCommunicationTool(
      operation: 'send_whatsapp',
      recipient: recipient,
      content: content,
    );
    
    if (result['success'] == true) {
      _addMessage('✅ WhatsApp opened successfully!\n📱 To: $recipient');
    } else {
      _addMessage('❌ Failed to open WhatsApp: ${result['error']}');
    }
  }

  /// Handle SMS tool
  Future<void> _handleSMSTool(String aiResponse) async {
    final recipient = _extractPhoneNumber(aiResponse) ?? '';
    final content = _extractSMSContent(aiResponse) ?? aiResponse;
    
    if (recipient.isEmpty) {
      _addMessage('⚠️ Please specify a phone number for SMS.');
      return;
    }
    
    final result = await ExternalToolsService.executeCommunicationTool(
      operation: 'send_sms',
      recipient: recipient,
      content: content,
    );
    
    if (result['success'] == true) {
      _addMessage('✅ SMS app opened successfully!\n📱 To: $recipient');
    } else {
      _addMessage('❌ Failed to open SMS: ${result['error']}');
    }
  }

  /// Handle file sharing tool
  Future<void> _handleShareFileTool(String aiResponse) async {
    if (_lastCreatedFilePath == null) {
      _addMessage('⚠️ No file to share. Please create a file first.');
      return;
    }
    
    final recipient = _extractEmailRecipient(aiResponse) ?? _extractPhoneNumber(aiResponse) ?? '';
    final shareMethod = _extractShareMethod(aiResponse);
    final subject = _extractEmailSubject(aiResponse) ?? 'File from AhamAI';
    final message = _extractShareMessage(aiResponse) ?? 'Please find the attached file.';
    
    _addMessage('📁 Sharing file...');
    
    Map<String, dynamic> result;
    
    // Use specialized email method for email sharing
    if (shareMethod == 'email' && recipient.isNotEmpty) {
      result = await ExternalToolsService.shareFileViaEmail(
        filePath: _lastCreatedFilePath!,
        recipient: recipient,
        subject: subject,
        message: message,
      );
    } else {
      result = await ExternalToolsService.shareFile(
        filePath: _lastCreatedFilePath!,
        shareMethod: shareMethod,
        recipient: recipient,
        subject: subject,
        message: message,
      );
    }
    
    if (result['success'] == true) {
      final method = result['method'] ?? shareMethod;
      _addMessage('✅ File shared successfully!\n📁 Method: ${method.toUpperCase()}\n📤 ${result['message']}');
    } else {
      _addMessage('❌ Failed to share file: ${result['error']}');
    }
  }

  // Helper methods for extracting information from AI responses
  String? _extractFileName(String response) {
    final patterns = [
      RegExp(r'file.*?([a-zA-Z0-9_-]+\.[a-zA-Z]{2,4})', caseSensitive: false),
      RegExp(r'named?\s+"([^"]+)"', caseSensitive: false),
      RegExp(r'call.*?it\s+"([^"]+)"', caseSensitive: false),
      RegExp(r'as\s+"([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String? _extractFileContent(String response) {
    // Try to extract content between quotes or after "content:"
    final patterns = [
      RegExp(r'content[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'with[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'containing[:\s]+"([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    // If no specific content found, use the response itself
    return response;
  }

  String _extractFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  String? _extractFileTitle(String response) {
    final patterns = [
      RegExp(r'title[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'titled?\s+"([^"]+)"', caseSensitive: false),
      RegExp(r'called?\s+"([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String? _extractEmailRecipient(String response) {
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final match = emailPattern.firstMatch(response);
    return match?.group(0);
  }

  String? _extractPhoneNumber(String response) {
    final phonePatterns = [
      RegExp(r'\+\d{1,3}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}'),
      RegExp(r'\b\d{10,15}\b'),
    ];

    for (final pattern in phonePatterns) {
      final match = pattern.firstMatch(response);
      if (match != null) return match.group(0);
    }
    return null;
  }

  String? _extractEmailSubject(String response) {
    final patterns = [
      RegExp(r'subject[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'title[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'regarding[:\s]+"([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  String? _extractEmailContent(String response) {
    final contentMatch = RegExp(r'message[:\s]+"([^"]+)"', caseSensitive: false).firstMatch(response);
    return contentMatch?.group(1);
  }

  String? _extractWhatsAppContent(String response) {
    final contentMatch = RegExp(r'message[:\s]+"([^"]+)"', caseSensitive: false).firstMatch(response);
    return contentMatch?.group(1);
  }

  String? _extractSMSContent(String response) {
    final contentMatch = RegExp(r'message[:\s]+"([^"]+)"', caseSensitive: false).firstMatch(response);
    return contentMatch?.group(1);
  }

  String _extractShareMethod(String response) {
    final lowerResponse = response.toLowerCase();
    
    if (lowerResponse.contains('email') || lowerResponse.contains('e-mail')) {
      return 'email';
    } else if (lowerResponse.contains('whatsapp') || lowerResponse.contains('whats app')) {
      return 'whatsapp';
    } else if (lowerResponse.contains('sms') || lowerResponse.contains('text message')) {
      return 'sms';
    } else {
      return 'share'; // Default to system share dialog
    }
  }

  String? _extractShareMessage(String response) {
    // Try to extract message content for sharing
    final patterns = [
      RegExp(r'with message[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'message[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'saying[:\s]+"([^"]+)"', caseSensitive: false),
      RegExp(r'text[:\s]+"([^"]+)"', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(response);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }
}