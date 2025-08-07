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
        'Make a summary.txt file',
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
    'share_file': {
      'name': 'File Sharing Tool',
      'description': 'Shares created files via email, WhatsApp, SMS, or system share',
      'parameters': {
        'filePath': 'Path to the file to share',
        'shareMethod': 'How to share (email, whatsapp, sms, share)',
        'recipient': 'Recipient for the file',
        'subject': 'Subject for email sharing',
        'message': 'Message to include with the file',
      },
      'examples': [
        'Share this file via email to john@company.com',
        'Send the created document to +1234567890 via WhatsApp',
        'Share the generated report',
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
      case 'share_file':
        return await _executeShareFile(parameters);
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

  /// Execute file sharing tool
  static Future<Map<String, dynamic>> _executeShareFile(Map<String, dynamic> params) async {
    final filePath = params['filePath'] as String?;
    final shareMethod = params['shareMethod'] as String?;
    final recipient = params['recipient'] as String?;
    final subject = params['subject'] as String?;
    final message = params['message'] as String?;

    if (filePath == null) {
      return {
        'success': false,
        'error': 'Missing required parameter: filePath',
      };
    }

    return await ExternalToolsService.shareFile(
      filePath: filePath,
      shareMethod: shareMethod ?? 'share',
      recipient: recipient,
      subject: subject,
      message: message,
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

    buffer.writeln('IMPORTANT GUIDELINES:');
    buffer.writeln('1. FILE CREATION: Only create files when the user explicitly asks for a file to be created, saved, or downloaded. Do NOT create files for general responses, explanations, or analysis.');
    buffer.writeln('2. COMMUNICATION: Only use email/WhatsApp/SMS when the user specifically wants to send a message to someone.');
    buffer.writeln('3. NATURAL RESPONSES: Most of your responses should be regular text without triggering any tools.');
    buffer.writeln('4. USER INTENT: Pay attention to keywords like "create file", "save as", "download", "send to", "email", "WhatsApp".');
    buffer.writeln('5. FILE CONTENT: When you do create a file, always show the file content in your response message as well.');
    buffer.writeln();
    buffer.writeln('Examples of when NOT to create files:');
    buffer.writeln('- "Explain SWOT analysis" → Just explain, no file');
    buffer.writeln('- "What is machine learning?" → Text response only');
    buffer.writeln('- "Analyze this data" → Provide analysis in text');
    buffer.writeln();
    buffer.writeln('Examples of when TO create files:');
    buffer.writeln('- "Create a SWOT analysis template file"');
    buffer.writeln('- "Save this analysis as a PDF"');
    buffer.writeln('- "Generate an HTML report and download it"');
    buffer.writeln('- "Make a summary.txt file of our conversation"');
    
    return buffer.toString();
  }

  /// Detect if AI response indicates tool usage
  static Map<String, dynamic>? detectToolUsage(String aiResponse) {
    final response = aiResponse.toLowerCase();

    print('🔍 Checking tool usage in response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');

    // File creation patterns
    if (_containsFileCreationIntent(response)) {
      print('✅ File creation tool detected');
      return {
        'action': 'create_file',
        'response': aiResponse,
      };
    }

    // Email patterns
    if (_containsEmailIntent(response)) {
      print('✅ Email tool detected');
      return {
        'action': 'send_email',
        'response': aiResponse,
      };
    }

    // WhatsApp patterns
    if (_containsWhatsAppIntent(response)) {
      print('✅ WhatsApp tool detected');
      return {
        'action': 'send_whatsapp',
        'response': aiResponse,
      };
    }

    // SMS patterns
    if (_containsSMSIntent(response)) {
      print('✅ SMS tool detected');
      return {
        'action': 'send_sms',
        'response': aiResponse,
      };
    }

    // File sharing patterns
    if (_containsShareFileIntent(response)) {
      print('✅ File sharing tool detected');
      return {
        'action': 'share_file',
        'response': aiResponse,
      };
    }

    print('❌ No tool usage detected');
    return null;
  }

  /// Check if response contains file creation intent
  static bool _containsFileCreationIntent(String response) {
    final patterns = [
      r'create a file',
      r'save as',
      r'generate a file',
      r'make a file',
      r'write.*file',
      r'create.*\.txt',
      r'create.*\.html',
      r'create.*\.css',
      r'create.*\.pdf',
      r'create.*\.zip',
      r'create.*\.json',
      r'save.*file',
      r'download.*file',
      r'export.*file',
      r'generate.*document',
      r'i will create',
      r'let me create',
      r'creating.*file',
      r"i'll create",
      r'create.*document',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(response)) {
        print('📄 File creation pattern matched: $pattern');
        return true;
      }
    }
    return false;
  }

  /// Check if response contains email intent
  static bool _containsEmailIntent(String response) {
    final patterns = [
      r'send.*email',
      r'email.*to',
      r'compose.*email',
      r'mail.*to',
      r'send.*to.*@',
      r'email.*this',
      r'i will email',
      r'let me email',
      r'sending.*email',
      r"i'll email",
      r'compose.*message.*@',
      r'draft.*email',
      r'open.*email',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(response)) {
        print('📧 Email pattern matched: $pattern');
        return true;
      }
    }
    return false;
  }

  /// Check if response contains WhatsApp intent
  static bool _containsWhatsAppIntent(String response) {
    final patterns = [
      r'send.*whatsapp',
      r'whatsapp.*to',
      r'share.*whatsapp',
      r'message.*whatsapp',
      r'send.*via whatsapp',
      r'i will whatsapp',
      r'let me whatsapp',
      r'sending.*whatsapp',
      r"i'll whatsapp",
      r'open.*whatsapp',
      r'whatsapp.*message',
      r'wa\.me',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(response)) {
        print('💬 WhatsApp pattern matched: $pattern');
        return true;
      }
    }
    return false;
  }

  /// Check if response contains SMS intent
  static bool _containsSMSIntent(String response) {
    final patterns = [
      r'send.*sms',
      r'text.*to',
      r'send.*text',
      r'sms.*to',
      r'message.*to.*\+',
      r'i will text',
      r'let me text',
      r'sending.*text',
      r"i'll text",
      r'send.*text message',
      r'text message.*to',
      r'sms.*message',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(response)) {
        print('📱 SMS pattern matched: $pattern');
        return true;
      }
    }
    return false;
  }

  /// Check if response contains file sharing intent
  static bool _containsShareFileIntent(String response) {
    final patterns = [
      r'share.*file',
      r'send.*file',
      r'email.*file',
      r'whatsapp.*file',
      r'sms.*file',
      r'system.*share',
      r'share.*this.*file',
      r'send.*this.*file',
      r'email.*this.*file',
      r'whatsapp.*this.*file',
      r'sms.*this.*file',
      r'share.*document',
      r'send.*document',
      r'email.*document',
      r'whatsapp.*document',
      r'sms.*document',
    ];

    for (final pattern in patterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(response)) {
        print('📁 File sharing pattern matched: $pattern');
        return true;
      }
    }
    return false;
  }
}