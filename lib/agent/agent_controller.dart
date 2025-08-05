import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'agent_web_view.dart';
import 'agent_screen_control.dart';
import 'agent_javascript_executor.dart';
import 'agent_task_planner.dart';
import 'agent_types.dart';

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

  /// Execute a high-level task using AI planning with advanced error recovery
  Future<AgentResult> executeTask(String taskDescription) async {
    if (!_isActive) {
      return AgentResult.error('Agent is not active');
    }

    try {
      print('🧠 Planning task: $taskDescription');
      _currentTask = taskDescription;

      // 1. Plan the task using AI
      TaskPlan plan = await _taskPlanner.createPlan(taskDescription);
      print('📋 Task plan created: ${plan.steps.length} steps');

      // 2. Execute steps with error recovery and self-healing
      final results = <StepResult>[];
      int retryCount = 0;
      final maxRetries = 3;

      for (int i = 0; i < plan.steps.length; i++) {
        final step = plan.steps[i];
        print('🔄 Executing step ${i + 1}/${plan.steps.length}: ${step.description}');

        StepResult stepResult = await _executeStep(step);
        results.add(stepResult);

        if (!stepResult.success) {
          print('❌ Step ${i + 1} failed: ${stepResult.error}');

          // Take screenshot for error analysis
          final screenshot = await _webView.takeScreenshot();
          final screenshotData = screenshot.success ? (screenshot.data?['screenshot'] ?? '') : '';

          // Analyze error and create recovery plan
          final recoveryPlan = await _taskPlanner.analyzeError(
            stepResult.error ?? 'Unknown error',
            step,
            screenshotData,
          );

          print('🔍 Error analysis complete. Strategy: ${recoveryPlan.strategy}');
          print('💡 Root cause: ${recoveryPlan.rootCause}');
          print('🎯 Success probability: ${recoveryPlan.successProbability}%');

          // Attempt recovery based on strategy
          bool recovered = false;
          if (step.retryable && retryCount < maxRetries) {
            switch (recoveryPlan.strategy) {
              case RecoveryStrategy.immediateRetry:
                print('🔄 Attempting immediate retry...');
                stepResult = await _executeStep(step);
                recovered = stepResult.success;
                break;

              case RecoveryStrategy.waitAndRetry:
                print('⏳ Waiting ${recoveryPlan.retryDelay}ms before retry...');
                await Future.delayed(Duration(milliseconds: recoveryPlan.retryDelay));
                stepResult = await _executeStep(step);
                recovered = stepResult.success;
                break;

              case RecoveryStrategy.alternativeApproach:
                print('🔀 Trying alternative approach...');
                // Execute recovery steps
                for (final recoveryStep in recoveryPlan.recoverySteps) {
                  print('🛠️ Recovery action: ${recoveryStep.action}');
                  // Execute recovery action (simplified for demo)
                  await Future.delayed(const Duration(milliseconds: 500));
                }
                stepResult = await _executeStep(step);
                recovered = stepResult.success;
                break;

              case RecoveryStrategy.manualIntervention:
                print('⚠️ Manual intervention required');
                break;
            }

            if (recovered) {
              print('✅ Step recovered successfully!');
              results[results.length - 1] = stepResult; // Update result
              retryCount = 0; // Reset retry count
            } else {
              retryCount++;
              if (retryCount >= maxRetries) {
                print('❌ Max retries reached. Moving to next step or stopping.');
                if (step.priority == TaskPriority.high) {
                  print('🛑 High priority step failed. Stopping execution.');
                  break;
                }
              } else {
                i--; // Retry the same step
                continue;
              }
            }
          } else {
            print('⚠️ Step not retryable or max retries exceeded');
            if (step.priority == TaskPriority.high) {
              print('🛑 Critical step failed. Stopping execution.');
              break;
            }
          }
        } else {
          print('✅ Step ${i + 1} completed successfully');
          retryCount = 0; // Reset retry count on success
        }

        // Brief pause between steps for stability
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // 3. Analyze execution and optimize plan for future use
      final successfulSteps = results.where((r) => r.success).length;
      final totalSteps = results.length;
      final successRate = totalSteps > 0 ? (successfulSteps / totalSteps) : 0.0;

      print('📊 Execution summary: $successfulSteps/$totalSteps steps successful (${(successRate * 100).toStringAsFixed(1)}%)');

      // If success rate is low, optimize the plan for future use
      if (successRate < 0.8 && results.isNotEmpty) {
        print('🔧 Optimizing plan based on execution results...');
        try {
          final optimizedPlan = await _taskPlanner.optimizePlan(plan, results);
          print('✨ Plan optimization completed');
        } catch (e) {
          print('⚠️ Plan optimization failed: $e');
        }
      }

      // 4. Compile final result with detailed analytics
      final success = successRate >= 0.8; // Consider successful if 80%+ steps succeeded
      final result = AgentResult(
        success: success,
        message: success 
          ? 'Task completed successfully ($successfulSteps/$totalSteps steps)'
          : 'Task partially completed ($successfulSteps/$totalSteps steps)',
        data: {
          'steps': results.map((r) => r.toJson()).toList(),
          'successRate': successRate,
          'totalSteps': totalSteps,
          'successfulSteps': successfulSteps,
          'executionTime': DateTime.now().toIso8601String(),
        },
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

// All type definitions moved to agent_types.dart