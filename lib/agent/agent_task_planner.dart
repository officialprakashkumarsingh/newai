import 'dart:convert';
import '../api_service.dart';
import 'agent_types.dart';

/// Advanced AI-powered task planner for agent automation
/// Can break down complex tasks, analyze errors, and create recovery plans
class AgentTaskPlanner {
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
    print('🧠 Task Planner initialized');
  }

  /// Create an execution plan for a complex task using AI
  Future<TaskPlan> createPlan(String taskDescription) async {
    try {
      final planningPrompt = '''
You are an advanced browser automation agent planner. Break down this task into specific, executable steps.

Task: "$taskDescription"

Analyze the task and create a detailed execution plan. Consider:
- Navigation steps
- Element interactions (clicks, typing, form fills)
- Data extraction needs
- Error scenarios and recovery
- Screenshot verification points
- Wait conditions

Respond ONLY with a JSON object in this exact format:
{
  "steps": [
    {
      "id": 1,
      "type": "navigate|click|type|extract|screenshot|javascript|wait",
      "description": "Human readable description",
      "parameters": {
        "url": "if navigate",
        "selector": "CSS selector or element identifier",
        "text": "if typing",
        "script": "if javascript",
        "duration": "if wait (milliseconds)"
      },
      "verification": "How to verify this step succeeded",
      "retryable": true,
      "priority": "high|medium|low"
    }
  ],
  "successCriteria": "How to know the entire task succeeded",
  "failureRecovery": "What to do if the task fails"
}''';

      print('🧠 Generating AI task plan...');
      
      final responseStream = ApiService.sendChatMessage(
        message: planningPrompt,
        model: 'gpt-4',
      );

      String fullResponse = '';
      await for (final chunk in responseStream) {
        fullResponse += chunk;
      }

      if (fullResponse.isEmpty) {
        throw Exception('Empty response from AI planner');
      }

      // Extract JSON from response
      final jsonStr = _extractJson(fullResponse);
      final planData = json.decode(jsonStr);

      final steps = (planData['steps'] as List).map((stepData) => TaskStep(
        id: stepData['id'] ?? 0,
        type: StepType.values.firstWhere(
          (e) => e.toString().split('.').last == stepData['type'],
          orElse: () => StepType.wait,
        ),
        description: stepData['description'] ?? '',
        parameters: Map<String, String>.from(stepData['parameters'] ?? {}),
        verification: stepData['verification'] ?? '',
        retryable: stepData['retryable'] ?? true,
        priority: _parsePriority(stepData['priority']),
      )).toList();

      return TaskPlan(
        steps: steps,
        successCriteria: planData['successCriteria'] ?? 'Task completed',
        failureRecovery: planData['failureRecovery'] ?? 'Manual intervention required',
      );

    } catch (e) {
      print('❌ Task planning failed: $e');
      // Fallback: Create a simple plan
      return _createFallbackPlan(taskDescription);
    }
  }

  /// Analyze an error and create a recovery plan
  Future<RecoveryPlan> analyzeError(String error, TaskStep failedStep, String screenshot) async {
    try {
      final analysisPrompt = '''
You are an advanced error analysis agent. Analyze this automation failure and create a recovery plan.

Failed Step: "${failedStep.description}"
Step Type: ${failedStep.type}
Error: "$error"
Screenshot Available: ${screenshot.isNotEmpty ? 'Yes' : 'No'}

Analyze the failure and respond with a JSON object:
{
  "errorType": "network|element_not_found|timeout|javascript_error|permission_denied|other",
  "rootCause": "Detailed analysis of what went wrong",
  "recoveryStrategy": "immediate_retry|wait_and_retry|alternative_approach|manual_intervention",
  "recoverySteps": [
    {
      "action": "What to do",
      "parameters": {"key": "value"},
      "reasoning": "Why this will help"
    }
  ],
  "retryDelay": 1000,
  "maxRetries": 3,
  "successProbability": 85,
  "alternativeApproach": "If retry fails, try this instead"
}''';

      final responseStream = ApiService.sendChatMessage(
        message: analysisPrompt,
        model: 'gpt-4',
      );

      String fullResponse = '';
      await for (final chunk in responseStream) {
        fullResponse += chunk;
      }

      final jsonStr = _extractJson(fullResponse);
      final analysisData = json.decode(jsonStr);

      return RecoveryPlan(
        errorType: analysisData['errorType'] ?? 'other',
        rootCause: analysisData['rootCause'] ?? 'Unknown error',
        strategy: _parseRecoveryStrategy(analysisData['recoveryStrategy']),
        recoverySteps: (analysisData['recoverySteps'] as List? ?? [])
            .map((step) => RecoveryStep(
              action: step['action'] ?? '',
              parameters: Map<String, String>.from(step['parameters'] ?? {}),
              reasoning: step['reasoning'] ?? '',
            )).toList(),
        retryDelay: analysisData['retryDelay'] ?? 1000,
        maxRetries: analysisData['maxRetries'] ?? 3,
        successProbability: analysisData['successProbability'] ?? 50,
        alternativeApproach: analysisData['alternativeApproach'] ?? '',
      );

    } catch (e) {
      print('❌ Error analysis failed: $e');
      return _createFallbackRecovery(error, failedStep);
    }
  }

  /// Optimize a task plan based on execution results
  Future<TaskPlan> optimizePlan(TaskPlan originalPlan, List<StepResult> results) async {
    try {
      final optimizationPrompt = '''
You are a task optimization agent. Analyze this executed plan and optimize it for better performance.

Original Plan: ${originalPlan.steps.length} steps
Execution Results: ${results.where((r) => r.success).length}/${results.length} steps succeeded

Failed Steps:
${results.where((r) => !r.success).map((r) => "- ${r.error}").join('\n')}

Successful Steps:
${results.where((r) => r.success).map((r) => "- ${r.message}").join('\n')}

Create an optimized plan that:
1. Eliminates unnecessary steps
2. Adds better error handling
3. Improves element selection
4. Adds verification points
5. Reduces execution time

Respond with the same JSON format as task planning.''';

      final responseStream = ApiService.sendChatMessage(
        message: optimizationPrompt,
        model: 'gpt-4',
      );

      String fullResponse = '';
      await for (final chunk in responseStream) {
        fullResponse += chunk;
      }

      final jsonStr = _extractJson(fullResponse);
      final planData = json.decode(jsonStr);

      final optimizedSteps = (planData['steps'] as List).map((stepData) => TaskStep(
        id: stepData['id'] ?? 0,
        type: StepType.values.firstWhere(
          (e) => e.toString().split('.').last == stepData['type'],
          orElse: () => StepType.wait,
        ),
        description: stepData['description'] ?? '',
        parameters: Map<String, String>.from(stepData['parameters'] ?? {}),
        verification: stepData['verification'] ?? '',
        retryable: stepData['retryable'] ?? true,
        priority: _parsePriority(stepData['priority']),
      )).toList();

      print('✨ Plan optimized: ${originalPlan.steps.length} → ${optimizedSteps.length} steps');

      return TaskPlan(
        steps: optimizedSteps,
        successCriteria: planData['successCriteria'] ?? originalPlan.successCriteria,
        failureRecovery: planData['failureRecovery'] ?? originalPlan.failureRecovery,
      );

    } catch (e) {
      print('❌ Plan optimization failed: $e');
      return originalPlan; // Return original if optimization fails
    }
  }

  /// Extract JSON from AI response
  String _extractJson(String response) {
    try {
      // Find JSON block
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}') + 1;
      
      if (start == -1 || end == 0) {
        throw Exception('No JSON found in response');
      }
      
      return response.substring(start, end);
    } catch (e) {
      throw Exception('Failed to extract JSON: $e');
    }
  }

  /// Parse priority from string
  TaskPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high': return TaskPriority.high;
      case 'low': return TaskPriority.low;
      default: return TaskPriority.medium;
    }
  }

  /// Parse recovery strategy from string
  RecoveryStrategy _parseRecoveryStrategy(String? strategy) {
    switch (strategy?.toLowerCase()) {
      case 'immediate_retry': return RecoveryStrategy.immediateRetry;
      case 'wait_and_retry': return RecoveryStrategy.waitAndRetry;
      case 'alternative_approach': return RecoveryStrategy.alternativeApproach;
      case 'manual_intervention': return RecoveryStrategy.manualIntervention;
      default: return RecoveryStrategy.waitAndRetry;
    }
  }

  /// Create a fallback plan if AI planning fails
  TaskPlan _createFallbackPlan(String taskDescription) {
    return TaskPlan(
      steps: [
        TaskStep(
          id: 1,
          type: StepType.screenshot,
          description: 'Take initial screenshot',
          parameters: {},
          verification: 'Screenshot captured',
          retryable: true,
          priority: TaskPriority.high,
        ),
        TaskStep(
          id: 2,
          type: StepType.wait,
          description: 'Wait for user guidance',
          parameters: {'duration': '2000'},
          verification: 'Wait completed',
          retryable: false,
          priority: TaskPriority.low,
        ),
      ],
      successCriteria: 'Fallback plan executed',
      failureRecovery: 'Manual task execution required',
    );
  }

  /// Create a fallback recovery plan
  RecoveryPlan _createFallbackRecovery(String error, TaskStep failedStep) {
    return RecoveryPlan(
      errorType: 'other',
      rootCause: 'Unknown error occurred',
      strategy: RecoveryStrategy.waitAndRetry,
      recoverySteps: [
        RecoveryStep(
          action: 'Wait and retry',
          parameters: {'delay': '2000'},
          reasoning: 'Simple retry after delay',
        ),
      ],
      retryDelay: 2000,
      maxRetries: 2,
      successProbability: 30,
      alternativeApproach: 'Manual intervention required',
    );
  }

  void dispose() {
    _isInitialized = false;
  }
}

// All type definitions moved to agent_types.dart