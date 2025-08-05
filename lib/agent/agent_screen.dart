import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'agent_controller.dart';
import '../theme.dart';

/// Dedicated screen for agent automation with web view and controls
class AgentScreen extends StatefulWidget {
  final String? initialTask;

  const AgentScreen({super.key, this.initialTask});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> with TickerProviderStateMixin {
  late AgentController _agentController;
  late AnimationController _statusAnimationController;
  late Animation<double> _statusAnimation;
  
  final TextEditingController _taskController = TextEditingController();
  bool _isExecuting = false;
  String _currentStatus = 'Agent Ready';
  List<String> _executionLog = [];

  @override
  void initState() {
    super.initState();
    
    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _statusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statusAnimationController, curve: Curves.easeInOut),
    );

    _agentController = AgentController();
    _initializeAgent();

    if (widget.initialTask != null) {
      _taskController.text = widget.initialTask!;
    }
  }

  Future<void> _initializeAgent() async {
    try {
      await _agentController.initialize();
      await _agentController.activate();
      
      setState(() {
        _currentStatus = 'Agent Initialized & Ready';
      });
      
      _statusAnimationController.forward();
    } catch (e) {
      setState(() {
        _currentStatus = 'Agent Initialization Failed: $e';
      });
    }
  }

  Future<void> _executeTask() async {
    if (_taskController.text.trim().isEmpty || _isExecuting) return;

    setState(() {
      _isExecuting = true;
      _currentStatus = 'Planning task...';
      _executionLog.clear();
    });

    _statusAnimationController.repeat();

    try {
      final task = _taskController.text.trim();
      _addToLog('🧠 Planning: $task');

      final result = await _agentController.executeTask(task);

      if (result.success) {
        _addToLog('✅ Task completed successfully!');
        _addToLog('📊 ${result.message}');
        
        // Show success haptic feedback
        HapticFeedback.lightImpact();
        
        setState(() {
          _currentStatus = 'Task Completed Successfully';
        });
      } else {
        _addToLog('❌ Task failed: ${result.error ?? result.message}');
        
        // Show error haptic feedback
        HapticFeedback.heavyImpact();
        
        setState(() {
          _currentStatus = 'Task Failed';
        });
      }

      // Show execution details
      if (result.data != null) {
        final steps = result.data!['steps'] as List<dynamic>? ?? [];
        final successfulSteps = result.data!['successfulSteps'] ?? 0;
        final totalSteps = result.data!['totalSteps'] ?? steps.length;
        
        _addToLog('📋 Execution Summary: $successfulSteps/$totalSteps steps successful');
        
        for (int i = 0; i < steps.length && i < 5; i++) {
          final step = steps[i] as Map<String, dynamic>;
          final success = step['success'] == true;
          final message = step['message'] ?? 'Unknown';
          _addToLog('${success ? '✅' : '❌'} Step ${i + 1}: $message');
        }
        
        if (steps.length > 5) {
          _addToLog('... and ${steps.length - 5} more steps');
        }
      }

    } catch (e) {
      _addToLog('💥 Execution error: $e');
      HapticFeedback.heavyImpact();
      
      setState(() {
        _currentStatus = 'Execution Error';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
      
      _statusAnimationController.stop();
      _statusAnimationController.reset();
    }
  }

  void _addToLog(String message) {
    setState(() {
      _executionLog.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
  }

  @override
  void dispose() {
    _statusAnimationController.dispose();
    _taskController.dispose();
    _agentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = !isLightTheme(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _statusAnimation,
              builder: (context, child) {
                return Icon(
                  Icons.smart_toy,
                  color: _isExecuting 
                    ? Colors.orange
                    : Colors.blue.withOpacity(_statusAnimation.value),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text('Agent Automation'),
          ],
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAgentInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _statusAnimationController,
                  builder: (context, child) {
                    return Icon(
                      _isExecuting ? Icons.sync : Icons.check_circle,
                      color: _isExecuting 
                        ? Colors.orange
                        : (_currentStatus.contains('Failed') || _currentStatus.contains('Error'))
                          ? Colors.red
                          : Colors.green,
                      size: 16,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (_isExecuting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Web View Area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _agentController.status.isInitialized
                  ? _agentController.getAgentWebView()
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Initializing Agent Web View...'),
                        ],
                      ),
                    ),
              ),
            ),
          ),

          // Execution Log
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Execution Log',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (_executionLog.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_all, size: 16),
                          onPressed: () => setState(() => _executionLog.clear()),
                          tooltip: 'Clear log',
                        ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: _executionLog.isEmpty
                      ? const Center(
                          child: Text(
                            'No execution log yet.\nRun a task to see detailed logs here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _executionLog.length,
                          itemBuilder: (context, index) {
                            final log = _executionLog[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                  color: log.contains('❌')
                                    ? Colors.red
                                    : log.contains('✅')
                                      ? Colors.green
                                      : log.contains('🧠')
                                        ? Colors.blue
                                        : isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Task Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    enabled: !_isExecuting,
                    decoration: InputDecoration(
                      hintText: 'Enter automation task (e.g., "Navigate to Google and search for Flutter")',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(Icons.psychology),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _executeTask(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isExecuting ? null : _executeTask,
                  child: _isExecuting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAgentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text('Agent Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${_agentController.status.isActive ? 'Active' : 'Inactive'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Capabilities: ${_agentController.status.capabilities.length}'),
            const SizedBox(height: 8),
            Text('Task History: ${_agentController.status.taskHistory.length}'),
            const SizedBox(height: 16),
            const Text(
              'Capabilities:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._agentController.status.capabilities.take(6).map((capability) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        capability,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_agentController.status.capabilities.length > 6)
              Text(
                '... and ${_agentController.status.capabilities.length - 6} more',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}