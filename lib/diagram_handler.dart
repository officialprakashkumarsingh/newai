import 'package:flutter/material.dart';
import 'diagram_service.dart';
import 'fullscreen_diagram_screen.dart';

class DiagramHandler {
  final BuildContext context;

  DiagramHandler(this.context);

  /// Check if message contains diagram request and handle it
  Future<void> checkAndHandleDiagramRequest(String message, String selectedModel) async {
    if (_containsDiagramRequest(message)) {
      await _handleDiagramGeneration(message, selectedModel);
    }
  }

  /// Handle diagram generation directly (for manual requests from bottom sheet)
  Future<void> handleManualDiagramRequest(String message, String selectedModel) async {
    await _handleDiagramGeneration(message, selectedModel);
  }

  /// Check if message contains diagram-related keywords
  bool _containsDiagramRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final diagramKeywords = [
      'chart', 'graph', 'diagram', 'plot', 'visualization', 'visualize',
      'bar chart', 'line chart', 'pie chart', 'scatter plot', 'flowchart',
      'mind map', 'mindmap', 'gantt chart', 'radar chart', 'doughnut chart',
      'area chart', 'bubble chart', 'histogram', 'timeline', 'org chart',
      'organization chart', 'tree diagram', 'network diagram', 'venn diagram'
    ];
    
    return diagramKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Handle diagram generation
  Future<void> _handleDiagramGeneration(String message, String selectedModel) async {
    try {
      final diagramData = await DiagramService.generateDiagramData(message, selectedModel);
      
      if (diagramData != null) {
        // Navigate to fullscreen diagram
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullscreenDiagramScreen(
                diagramData: diagramData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating diagram: $e');
    }
  }

  /// Get diagram widget for display (if needed in chat)
  Widget? buildDiagramWidget(Map<String, dynamic> diagramData, BuildContext context, Function(Map<String, dynamic>) onFullscreen) {
    try {
      return DiagramService.buildDiagramWidget(diagramData, context, onFullscreen);
    } catch (e) {
      print('Error building diagram widget: $e');
      return null;
    }
  }
}