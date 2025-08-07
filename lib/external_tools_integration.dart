import 'dart:convert';
import 'external_tools_service.dart';

class ExternalToolsIntegration {
  
  // Tool definitions for AI understanding
  static const Map<String, Map<String, dynamic>> toolDefinitions = {
    'create_file': {
      'name': 'create_file',
      'description': 'Creates files of various types (txt, html, css, pdf, zip) with AI-generated or user-provided content',
      'parameters': {
        'fileName': {
          'type': 'string',
          'description': 'Name of the file to create (with extension)',
        },
        'content': {
          'type': 'string', 
          'description': 'Content to write to the file',
        },
        'fileType': {
          'type': 'string',
          'description': 'Type of file (txt, html, css, pdf, zip, json, xml, etc.)',
          'optional': true,
        },
        'metadata': {
          'type': 'object',
          'description': 'Additional file metadata (author, title, description, etc.)',
          'optional': true,
        }
      }
    },
    'send_email': {
      'name': 'send_email', 
      'description': 'Sends email with content to specified recipient',
      'parameters': {
        'recipient': {
          'type': 'string',
          'description': 'Email address of the recipient',
        },
        'content': {
          'type': 'string',
          'description': 'Email content/message',
        },
        'subject': {
          'type': 'string', 
          'description': 'Email subject line',
          'optional': true,
        }
      }
    },
    'send_whatsapp': {
      'name': 'send_whatsapp',
      'description': 'Sends WhatsApp message to specified contact',
      'parameters': {
        'recipient': {
          'type': 'string',
          'description': 'Phone number or WhatsApp contact',
        },
        'content': {
          'type': 'string',
          'description': 'Message content',
        }
      }
    },
    'send_sms': {
      'name': 'send_sms',
      'description': 'Sends SMS text message to specified phone number',
      'parameters': {
        'recipient': {
          'type': 'string',
          'description': 'Phone number to send SMS to',
        },
        'content': {
          'type': 'string',
          'description': 'SMS message content',
        }
      }
    }
  };
  
  // Execute tool based on AI request
  static Future<Map<String, dynamic>> executeTool(String toolName, Map<String, dynamic> parameters) async {
    switch (toolName) {
      case 'create_file':
        return await _executeFileCreation(parameters);
      case 'send_email':
        return await _executeSendEmail(parameters);
      case 'send_whatsapp':
        return await _executeSendWhatsApp(parameters);
      case 'send_sms':
        return await _executeSendSMS(parameters);
      default:
        return {
          'success': false,
          'error': 'Unknown tool: $toolName'
        };
    }
  }
  
  static Future<Map<String, dynamic>> _executeFileCreation(Map<String, dynamic> params) async {
    final fileName = params['fileName'] as String;
    final content = params['content'] as String;
    final fileType = params['fileType'] as String?;
    final metadata = params['metadata'] as Map<String, dynamic>?;
    
    return await ExternalToolsService.executeFileTool(
      operation: 'create',
      fileName: fileName,
      content: content,
      fileType: fileType,
      metadata: metadata,
    );
  }
  
  static Future<Map<String, dynamic>> _executeSendEmail(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String;
    final content = params['content'] as String;
    final subject = params['subject'] as String?;
    
    return await ExternalToolsService.executeCommunicationTool(
      operation: 'email',
      recipient: recipient,
      content: content,
      subject: subject,
    );
  }
  
  static Future<Map<String, dynamic>> _executeSendWhatsApp(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String;
    final content = params['content'] as String;
    
    return await ExternalToolsService.executeCommunicationTool(
      operation: 'whatsapp',
      recipient: recipient,
      content: content,
    );
  }
  
  static Future<Map<String, dynamic>> _executeSendSMS(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String;
    final content = params['content'] as String;
    
    return await ExternalToolsService.executeCommunicationTool(
      operation: 'sms',
      recipient: recipient,
      content: content,
    );
  }
  
  // Get tool definitions for AI prompt
  static String getToolDefinitionsForAI() {
    return '''
You have access to the following external tools that you can use when appropriate:

${toolDefinitions.entries.map((entry) {
  final tool = entry.value;
  final params = tool['parameters'] as Map<String, dynamic>;
  final paramsList = params.entries.map((param) {
    final paramInfo = param.value as Map<String, dynamic>;
    final optional = paramInfo['optional'] == true ? ' (optional)' : '';
    return '  - ${param.key}: ${paramInfo['type']} - ${paramInfo['description']}$optional';
  }).join('\n');
  
  return '''
Tool: ${tool['name']}
Description: ${tool['description']}
Parameters:
$paramsList
''';
}).join('\n')}

To use these tools, simply mention in your response that you need to perform an action like:
- "I'll create a file for you"
- "Let me send that email"
- "I'll send this via WhatsApp"

The system will automatically detect when you need to use tools and execute them for you.
''';
  }
  
  // Detect if AI response indicates tool usage
  static Map<String, dynamic>? detectToolUsage(String aiResponse) {
    final response = aiResponse.toLowerCase();
    
    // File creation patterns
    if (response.contains(RegExp(r'i.*(ll|will)\s*(create|generate|make)\s*(a|an|the)?\s*(file|document)'))) {
      return {'action': 'prepare_file_creation', 'response': aiResponse};
    }
    
    // Email patterns  
    if (response.contains(RegExp(r'i.*(ll|will)\s*send\s*(an|the)?\s*email'))) {
      return {'action': 'prepare_email', 'response': aiResponse};
    }
    
    // WhatsApp patterns
    if (response.contains(RegExp(r'i.*(ll|will)\s*send\s*(this|that|it)\s*(via|through|on)\s*whatsapp'))) {
      return {'action': 'prepare_whatsapp', 'response': aiResponse};
    }
    
    // SMS patterns
    if (response.contains(RegExp(r'i.*(ll|will)\s*send\s*(an|a)?\s*(sms|text\s*message)'))) {
      return {'action': 'prepare_sms', 'response': aiResponse};
    }
    
    return null;
  }
}