import 'dart:convert';
import 'external_tools_service.dart';

class ExternalToolsIntegration {
  /// Definitions of available external tools for AI context
  static const Map<String, Map<String, dynamic>> toolDefinitions = {
    'create_file': {
      'name': 'File Creation Tool',
      'description': 'Creates files with content in various formats (txt, html, css, pdf, zip)',
      'parameters': {
        'fileName': 'Name of the file to create',
        'content': 'Content to write to the file',
        'fileType': 'File type (txt, html, css, pdf, zip)',
      },
      'examples': [
        'Create a report.pdf with the analysis data',
        'Generate index.html with the website code',
        'Save the project files as project.zip',
      ],
    },
    'send_email': {
      'name': 'Email Tool',
      'description': 'Composes and sends emails with content',
      'parameters': {
        'recipient': 'Email address of the recipient',
        'subject': 'Email subject line',
        'content': 'Email body content',
      },
      'examples': [
        'Send this report to john@company.com',
        'Email the meeting notes to the team',
        'Send the proposal to client@business.com',
      ],
    },
    'send_whatsapp': {
      'name': 'WhatsApp Tool',
      'description': 'Sends messages via WhatsApp',
      'parameters': {
        'recipient': 'Phone number or contact name',
        'content': 'Message content to send',
      },
      'examples': [
        'Send this update to +1234567890 on WhatsApp',
        'WhatsApp the schedule to the team',
        'Share this information via WhatsApp',
      ],
    },
    'send_sms': {
      'name': 'SMS Tool',
      'description': 'Sends text messages via SMS',
      'parameters': {
        'recipient': 'Phone number to send SMS to',
        'content': 'SMS message content',
      },
      'examples': [
        'Send an SMS reminder to +1234567890',
        'Text the confirmation code',
        'Send this alert via SMS',
      ],
    },
  };

  /// Execute a specific tool with parameters
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
          'error': 'Unknown tool: $toolName',
        };
    }
  }

  /// Execute file creation tool
  static Future<Map<String, dynamic>> _executeFileCreation(Map<String, dynamic> params) async {
    final fileName = params['fileName'] as String?;
    final content = params['content'] as String?;
    final fileType = params['fileType'] as String?;

    if (fileName == null || content == null) {
      return {
        'success': false,
        'error': 'Missing required parameters: fileName and content',
      };
    }

    return await ExternalToolsService.executeFileTool(
      operation: 'create_file',
      fileName: fileName,
      content: content,
      fileType: fileType,
      metadata: params['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Execute email sending tool
  static Future<Map<String, dynamic>> _executeSendEmail(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String?;
    final content = params['content'] as String?;
    final subject = params['subject'] as String?;

    if (recipient == null || content == null) {
      return {
        'success': false,
        'error': 'Missing required parameters: recipient and content',
      };
    }

    return await ExternalToolsService.executeCommunicationTool(
      operation: 'send_email',
      recipient: recipient,
      content: content,
      subject: subject,
      metadata: params['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Execute WhatsApp sending tool
  static Future<Map<String, dynamic>> _executeSendWhatsApp(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String?;
    final content = params['content'] as String?;

    if (recipient == null || content == null) {
      return {
        'success': false,
        'error': 'Missing required parameters: recipient and content',
      };
    }

    return await ExternalToolsService.executeCommunicationTool(
      operation: 'send_whatsapp',
      recipient: recipient,
      content: content,
      metadata: params['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Execute SMS sending tool
  static Future<Map<String, dynamic>> _executeSendSMS(Map<String, dynamic> params) async {
    final recipient = params['recipient'] as String?;
    final content = params['content'] as String?;

    if (recipient == null || content == null) {
      return {
        'success': false,
        'error': 'Missing required parameters: recipient and content',
      };
    }

    return await ExternalToolsService.executeCommunicationTool(
      operation: 'send_sms',
      recipient: recipient,
      content: content,
      metadata: params['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Generate tool definitions for AI context
  static String getToolDefinitionsForAI() {
    final buffer = StringBuffer();
    buffer.writeln('Available External Tools:');
    buffer.writeln('You have access to the following external tools that can perform actions outside of our conversation:');
    buffer.writeln();

    for (final entry in toolDefinitions.entries) {
      final toolName = entry.key;
      final toolInfo = entry.value;
      
      buffer.writeln('🔧 ${toolInfo['name']}');
      buffer.writeln('   Description: ${toolInfo['description']}');
      buffer.writeln('   Usage: When the user requests actions that match this tool, respond naturally and I will execute it automatically.');
      buffer.writeln('   Examples: ${(toolInfo['examples'] as List).join(', ')}');
      buffer.writeln();
    }

    buffer.writeln('Important: When you detect that the user wants to use any of these tools, respond naturally explaining what you will do, and the system will automatically execute the appropriate tool. Do not ask for confirmation or additional details unless absolutely necessary.');
    
    return buffer.toString();
  }

  /// Detect if AI response indicates tool usage
  static Map<String, dynamic>? detectToolUsage(String aiResponse) {
    final response = aiResponse.toLowerCase();

    // File creation patterns
    if (_containsFileCreationIntent(response)) {
      return {
        'action': 'create_file',
        'response': aiResponse,
      };
    }

    // Email patterns
    if (_containsEmailIntent(response)) {
      return {
        'action': 'send_email',
        'response': aiResponse,
      };
    }

    // WhatsApp patterns
    if (_containsWhatsAppIntent(response)) {
      return {
        'action': 'send_whatsapp',
        'response': aiResponse,
      };
    }

    // SMS patterns
    if (_containsSMSIntent(response)) {
      return {
        'action': 'send_sms',
        'response': aiResponse,
      };
    }

    return null;
  }

  /// Check if response contains file creation intent
  static bool _containsFileCreationIntent(String response) {
    final patterns = [
      'create a file',
      'save as',
      'generate a file',
      'create.*\\.txt',
      'create.*\\.html',
      'create.*\\.css',
      'create.*\\.pdf',
      'create.*\\.zip',
      'save.*file',
      'download.*file',
      'export.*file',
    ];

    return patterns.any((pattern) => RegExp(pattern).hasMatch(response));
  }

  /// Check if response contains email intent
  static bool _containsEmailIntent(String response) {
    final patterns = [
      'send.*email',
      'email.*to',
      'compose.*email',
      'mail.*to',
      'send.*to.*@',
      'email.*this',
    ];

    return patterns.any((pattern) => RegExp(pattern).hasMatch(response));
  }

  /// Check if response contains WhatsApp intent
  static bool _containsWhatsAppIntent(String response) {
    final patterns = [
      'send.*whatsapp',
      'whatsapp.*to',
      'share.*whatsapp',
      'message.*whatsapp',
      'send.*via whatsapp',
    ];

    return patterns.any((pattern) => RegExp(pattern).hasMatch(response));
  }

  /// Check if response contains SMS intent
  static bool _containsSMSIntent(String response) {
    final patterns = [
      'send.*sms',
      'text.*to',
      'send.*text',
      'sms.*to',
      'message.*to.*\\+',
    ];

    return patterns.any((pattern) => RegExp(pattern).hasMatch(response));
  }
}