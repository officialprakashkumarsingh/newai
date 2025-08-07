import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class ExternalToolsService {
  /// Execute a file creation tool
  static Future<Map<String, dynamic>> executeFileTool({
    required String operation,
    required String fileName,
    required String content,
    String? fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Determine file type from extension if not provided
      final actualFileType = fileType ?? fileName.split('.').last.toLowerCase();
      
      // Get the downloads directory (or documents directory on iOS)
      Directory downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      
      final file = File('${downloadsDir.path}/$fileName');
      
      String finalContent = content;
      
      // Handle different file types
      switch (actualFileType) {
        case 'html':
          if (!content.toLowerCase().contains('<html>')) {
            finalContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>${metadata?['title'] ?? 'Document'}</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; line-height: 1.6; }
        pre { white-space: pre-wrap; background: #f5f5f5; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>${metadata?['title'] ?? 'Document'}</h1>
    <div>$content</div>
</body>
</html>''';
          }
          break;
        case 'css':
          if (!content.toLowerCase().contains('/*')) {
            finalContent = '''
/* Generated CSS File */
/* Title: ${metadata?['title'] ?? 'Styles'} */

$content
''';
          }
          break;
        case 'json':
          try {
            // Validate and format JSON
            final jsonData = json.decode(content);
            finalContent = const JsonEncoder.withIndent('  ').convert(jsonData);
          } catch (e) {
            // If not valid JSON, wrap the content
            finalContent = '''
{
  "content": ${json.encode(content)},
  "created_at": "${DateTime.now().toIso8601String()}",
  "title": "${metadata?['title'] ?? 'Document'}"
}''';
          }
          break;
        case 'pdf':
          // Create HTML content that can be saved as PDF
          finalContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>${metadata?['title'] ?? 'Document'}</title>
    <meta charset="UTF-8">
    <style>
        @page { margin: 1in; }
        body { font-family: 'Times New Roman', serif; font-size: 12pt; line-height: 1.5; }
        h1 { color: #333; border-bottom: 2px solid #333; padding-bottom: 10px; }
        pre { white-space: pre-wrap; font-family: 'Courier New', monospace; }
    </style>
</head>
<body>
    <h1>${metadata?['title'] ?? 'Document'}</h1>
    <div>$content</div>
    <br><br>
    <p><small>Generated on ${DateTime.now().toString()}</small></p>
</body>
</html>''';
          break;
        default:
          // For txt and other formats, keep content as-is
          break;
      }
      
      // Write the file
      await file.writeAsString(finalContent, encoding: utf8);
      
      return {
        'success': true,
        'message': 'File created successfully: $fileName',
        'file_path': file.path,
        'file_size': await file.length(),
        'created_at': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create file: $e',
        'file_name': fileName,
      };
    }
  }
  
  /// Share a file via different methods
  static Future<Map<String, dynamic>> shareFile({
    required String filePath,
    required String shareMethod,
    String? recipient,
    String? subject,
    String? message,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return {
          'success': false,
          'error': 'File does not exist: $filePath',
        };
      }

      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      
      switch (shareMethod) {
        case 'email':
          // Use email intent with file attachment
          if (Platform.isAndroid) {
            final result = await _shareViaEmailAndroid(file, recipient, subject, message);
            return result;
          } else {
            return await _shareViaGeneric(file, 'email', recipient, subject, message);
          }
          
        case 'whatsapp':
          return await _shareViaWhatsApp(file, recipient, message);
          
        case 'sms':
          // SMS doesn't support file attachments, so share file content as text
          if (fileSize < 1000000) { // Less than 1MB
            final content = await file.readAsString();
            return await executeCommunicationTool(
              operation: 'send_sms',
              recipient: recipient ?? '',
              content: message ?? 'File: $fileName\n\n$content',
            );
          } else {
            return {
              'success': false,
              'error': 'File too large for SMS. Please use email or WhatsApp.',
            };
          }
          
        case 'share':
        default:
          // Generic share (opens system share dialog)
          await Share.shareXFiles([XFile(filePath)], text: message ?? 'Shared via AhamAI');
          return {
            'success': true,
            'message': 'File shared successfully',
            'file_name': fileName,
          };
      }
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to share file: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> _shareViaEmailAndroid(File file, String? recipient, String? subject, String? message) async {
    try {
      // Try Gmail first, then fallback to generic email
      const String gmailPackage = 'com.google.android.gm';
      final String emailSubject = subject ?? 'File from AhamAI';
      final String emailMessage = message ?? 'Please find the attached file.';
      
      // Create Android intent for email with attachment
      await MethodChannel('flutter/platform').invokeMethod('startActivity', {
        'action': 'android.intent.action.SEND',
        'type': 'text/plain',
        'package': gmailPackage,
        'extras': {
          'android.intent.extra.EMAIL': recipient != null ? [recipient] : null,
          'android.intent.extra.SUBJECT': emailSubject,
          'android.intent.extra.TEXT': emailMessage,
          'android.intent.extra.STREAM': file.path,
        },
      });
      
      return {
        'success': true,
        'message': 'Email app opened with file attachment',
        'recipient': recipient,
      };
    } catch (e) {
      // Fallback to generic share
      return await _shareViaGeneric(file, 'email', recipient, subject, message);
    }
  }
  
  static Future<Map<String, dynamic>> _shareViaWhatsApp(File file, String? recipient, String? message) async {
    try {
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      
      if (fileSize > 100 * 1024 * 1024) { // 100MB limit for WhatsApp
        return {
          'success': false,
          'error': 'File too large for WhatsApp (max 100MB)',
        };
      }
      
      // Use system share with WhatsApp package hint
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message ?? 'File shared via AhamAI: $fileName',
      );
      
      return {
        'success': true,
        'message': 'File shared to WhatsApp successfully',
        'file_name': fileName,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to share via WhatsApp: $e',
      };
    }
  }
  
  static Future<Map<String, dynamic>> _shareViaGeneric(File file, String type, String? recipient, String? subject, String? message) async {
    try {
      final fileName = file.path.split('/').last;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message ?? 'File shared via AhamAI: $fileName',
        subject: subject,
      );
      
      return {
        'success': true,
        'message': 'File shared successfully via $type',
        'file_name': fileName,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to share file: $e',
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
      String? urlToLaunch;
      
      switch (operation) {
        case 'send_email':
          final emailSubject = subject ?? 'Message from AI Assistant';
          // Try multiple email approaches for better compatibility
          if (Platform.isAndroid) {
            // Use intent approach for Android
            try {
              await MethodChannel('flutter/platform').invokeMethod('startActivity', {
                'action': 'android.intent.action.SENDTO',
                'data': 'mailto:$recipient',
                'extras': {
                  'android.intent.extra.SUBJECT': emailSubject,
                  'android.intent.extra.TEXT': content,
                },
              });
              return {
                'success': true,
                'operation': operation,
                'message': 'EMAIL app opened successfully',
                'recipient': recipient,
              };
            } catch (e) {
              // Fallback to URL launcher
              urlToLaunch = 'mailto:$recipient?subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(content)}';
            }
          } else {
            urlToLaunch = 'mailto:$recipient?subject=${Uri.encodeComponent(emailSubject)}&body=${Uri.encodeComponent(content)}';
          }
          break;
          
        case 'send_whatsapp':
          // Clean phone number (remove spaces, hyphens, etc.)
          final cleanPhone = recipient.replaceAll(RegExp(r'[^\d+]'), '');
          urlToLaunch = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(content)}';
          break;
          
        case 'send_sms':
          // Clean phone number
          final cleanPhone = recipient.replaceAll(RegExp(r'[^\d+]'), '');
          if (Platform.isIOS) {
            urlToLaunch = 'sms:$cleanPhone&body=${Uri.encodeComponent(content)}';
          } else {
            urlToLaunch = 'sms:$cleanPhone?body=${Uri.encodeComponent(content)}';
          }
          break;
          
        default:
          return {
            'success': false,
            'error': 'Unknown operation: $operation',
          };
      }
      
      if (urlToLaunch != null) {
        final uri = Uri.parse(urlToLaunch);
        final canLaunch = await canLaunchUrl(uri);
        
        if (canLaunch) {
          await launchUrl(uri);
          return {
            'success': true,
            'operation': operation,
            'message': '${operation.replaceAll('send_', '').toUpperCase()} app opened successfully',
            'recipient': recipient,
          };
        } else {
          return {
            'success': false,
            'error': 'Cannot launch ${operation.replaceAll('send_', '')} app. Make sure you have the app installed.',
          };
        }
      }
      
      return {
        'success': false,
        'error': 'Failed to prepare $operation',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': 'Communication tool execution failed: $e',
      };
    }
  }
  
  /// Get list of available tools
  static Future<List<String>> getAvailableTools() async {
    return [
      'create_file',
      'send_email',
      'send_whatsapp',
      'send_sms',
      'share_file',
    ];
  }
  
  /// Get capabilities of a specific tool
  static Future<Map<String, dynamic>> getToolCapabilities(String toolName) async {
    switch (toolName) {
      case 'create_file':
        return {
          'name': 'File Creation Tool',
          'description': 'Creates files with content in various formats',
          'supported_formats': ['txt', 'html', 'css', 'pdf', 'json', 'xml', 'md'],
          'parameters': ['fileName', 'content', 'fileType', 'metadata'],
        };
      case 'send_email':
        return {
          'name': 'Email Tool',
          'description': 'Opens email app with pre-filled content',
          'parameters': ['recipient', 'subject', 'content'],
        };
      case 'send_whatsapp':
        return {
          'name': 'WhatsApp Tool',
          'description': 'Opens WhatsApp with pre-filled message',
          'parameters': ['recipient', 'content'],
        };
      case 'send_sms':
        return {
          'name': 'SMS Tool',
          'description': 'Opens SMS app with pre-filled message',
          'parameters': ['recipient', 'content'],
        };
      case 'share_file':
        return {
          'name': 'File Sharing Tool',
          'description': 'Shares files via email, WhatsApp, or system share',
          'parameters': ['filePath', 'shareMethod', 'recipient', 'subject', 'message'],
        };
      default:
        return {
          'error': 'Unknown tool: $toolName',
        };
    }
  }
}