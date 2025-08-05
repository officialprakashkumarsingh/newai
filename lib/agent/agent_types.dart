/// Shared types and classes for the agent automation system

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

/// A complete task execution plan
class TaskPlan {
  final List<TaskStep> steps;
  final String successCriteria;
  final String failureRecovery;

  TaskPlan({
    required this.steps,
    required this.successCriteria,
    required this.failureRecovery,
  });
}

/// A single step in a task plan
class TaskStep {
  final int id;
  final StepType type;
  final String description;
  final Map<String, String> parameters;
  final String verification;
  final bool retryable;
  final TaskPriority priority;

  TaskStep({
    required this.id,
    required this.type,
    required this.description,
    required this.parameters,
    required this.verification,
    required this.retryable,
    required this.priority,
  });
}

/// Types of steps an agent can execute
enum StepType {
  navigate,
  click,
  type,
  extract,
  screenshot,
  javascript,
  wait,
  scroll,
  hover,
  select,
  upload,
  download,
}

/// Priority levels for task steps
enum TaskPriority {
  high,
  medium,
  low,
}

/// Error recovery plan
class RecoveryPlan {
  final String errorType;
  final String rootCause;
  final RecoveryStrategy strategy;
  final List<RecoveryStep> recoverySteps;
  final int retryDelay;
  final int maxRetries;
  final int successProbability;
  final String alternativeApproach;

  RecoveryPlan({
    required this.errorType,
    required this.rootCause,
    required this.strategy,
    required this.recoverySteps,
    required this.retryDelay,
    required this.maxRetries,
    required this.successProbability,
    required this.alternativeApproach,
  });
}

/// Recovery strategies
enum RecoveryStrategy {
  immediateRetry,
  waitAndRetry,
  alternativeApproach,
  manualIntervention,
}

/// A single recovery step
class RecoveryStep {
  final String action;
  final Map<String, String> parameters;
  final String reasoning;

  RecoveryStep({
    required this.action,
    required this.parameters,
    required this.reasoning,
  });
}