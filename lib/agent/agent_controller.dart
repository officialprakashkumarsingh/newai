import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'agent_web_view.dart';
import 'agent_screen_control.dart';
import 'agent_javascript_executor.dart';
import 'agent_task_planner.dart';

/// Main controller for the AhamAI automation agent
/// Inspired by Comet browser and modern agentic automation
class AgentController {
  static final AgentController _instance = AgentController._internal();
  factory AgentController() => _instance;
  AgentController._internal();

  // Agent components
  late AgentWebView _webView;
  late AgentScreenControl _screenControl;
  late AgentJavaScriptExecutor _jsExecutor;
  late AgentTaskPlanner _taskPlanner;

  // Agent state
  bool _isInitialized = false;
  bool _isActive = false;
  String? _currentTask;
  List<String> _taskHistory = [];

  // Agent capabilities
  final List<String> _capabilities = [
    'Web browsing and navigation',
    'Form filling and submission',
    'Data extraction and scraping',
    'Screenshot capture and analysis',
    'JavaScript execution and automation',
    'Multi-step task planning',
    'Real-time screen monitoring',
    'API interaction and data processing',
  ];

  /// Initialize the agent system
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _webView = AgentWebView();
      _screenControl = AgentScreenControl();
      _jsExecutor = AgentJavaScriptExecutor();
      _taskPlanner = AgentTaskPlanner();

      await _webView.initialize();
      await _screenControl.initialize();
      await _jsExecutor.initialize();
      await _taskPlanner.initialize();

      _isInitialized = true;
      print('🤖 Agent Controller initialized successfully');
    } catch (e) {
      print('❌ Agent initialization failed: $e');
      rethrow;
    }
  }

  /// Activate agent mode
  Future<void> activate() async {
    if (!_isInitialized) {
      await initialize();
    }

    _isActive = true;
    print('🚀 Agent activated - ready for automation tasks');
  }

  /// Deactivate agent mode
  void deactivate() {
    _isActive = false;
    _currentTask = null;
    print('⏹️ Agent deactivated');
  }

  /// Execute a high-level task using AI planning
  Future<AgentResult> executeTask(String taskDescription) async {
    if (!_isActive) {
      return AgentResult.error('Agent is not active');
    }

    try {
      print('🧠 Planning task: $taskDescription');
      _currentTask = taskDescription;

      // 1. Plan the task using AI
      final plan = await _taskPlanner.createPlan(taskDescription);
      print('📋 Task plan created: ${plan.steps.length} steps');

      // 2. Execute each step
      final results = <StepResult>[];
      for (int i = 0; i < plan.steps.length; i++) {
        final step = plan.steps[i];
        print('🔄 Executing step ${i + 1}: ${step.description}');

        final stepResult = await _executeStep(step);
        results.add(stepResult);

        if (!stepResult.success) {
          print('❌ Step failed: ${stepResult.error}');
          break;
        }
      }

      // 3. Compile final result
      final success = results.every((r) => r.success);
      final result = AgentResult(
        success: success,
        message: success ? 'Task completed successfully' : 'Task failed',
        data: {'steps': results.map((r) => r.toJson()).toList()},
      );

      _taskHistory.add(taskDescription);
      _currentTask = null;

      return result;
    } catch (e) {
      print('❌ Task execution failed: $e');
      _currentTask = null;
      return AgentResult.error('Task execution failed: $e');
    }
  }

  /// Execute a single step of a task
  Future<StepResult> _executeStep(TaskStep step) async {
    switch (step.type) {
      case StepType.navigate:
        return await _webView.navigate(step.parameters['url'] ?? '');
      
      case StepType.click:
        return await _screenControl.click(step.parameters['selector'] ?? '');
      
      case StepType.type:
        return await _screenControl.type(
          step.parameters['selector'] ?? '',
          step.parameters['text'] ?? '',
        );
      
      case StepType.extract:
        return await _jsExecutor.extractData(step.parameters['selector'] ?? '');
      
      case StepType.screenshot:
        return await _screenControl.takeScreenshot();
      
      case StepType.javascript:
        return await _jsExecutor.executeScript(step.parameters['script'] ?? '');
      
      case StepType.wait:
        await Future.delayed(Duration(
          milliseconds: int.tryParse(step.parameters['duration'] ?? '1000') ?? 1000,
        ));
        return StepResult.success('Wait completed');
      
      default:
        return StepResult.error('Unknown step type: ${step.type}');
    }
  }

  /// Get agent status
  AgentStatus get status => AgentStatus(
    isInitialized: _isInitialized,
    isActive: _isActive,
    currentTask: _currentTask,
    capabilities: _capabilities,
    taskHistory: _taskHistory,
  );

  /// Get agent web view widget for UI integration
  Widget getAgentWebView() {
    if (!_isInitialized) {
      return const Center(
        child: Text('Agent not initialized'),
      );
    }
    return _webView.getWidget();
  }

  /// Dispose agent resources
  void dispose() {
    _webView.dispose();
    _screenControl.dispose();
    _jsExecutor.dispose();
    _taskPlanner.dispose();
    _isInitialized = false;
    _isActive = false;
  }
}

/// Result of an agent task execution
class AgentResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  AgentResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AgentResult.success(String message, [Map<String, dynamic>? data]) {
    return AgentResult(success: true, message: message, data: data);
  }

  factory AgentResult.error(String error) {
    return AgentResult(success: false, message: 'Error', error: error);
  }
}

/// Result of a single task step
class StepResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  StepResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory StepResult.success(String message, [Map<String, dynamic>? data]) {
    return StepResult(success: true, message: message, data: data);
  }

  factory StepResult.error(String error) {
    return StepResult(success: false, message: 'Error', error: error);
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
    'error': error,
  };
}

/// Current status of the agent
class AgentStatus {
  final bool isInitialized;
  final bool isActive;
  final String? currentTask;
  final List<String> capabilities;
  final List<String> taskHistory;

  AgentStatus({
    required this.isInitialized,
    required this.isActive,
    this.currentTask,
    required this.capabilities,
    required this.taskHistory,
  });
}