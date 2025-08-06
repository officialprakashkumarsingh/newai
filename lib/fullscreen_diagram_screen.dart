import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import 'diagram_service.dart';

class FullscreenDiagramScreen extends StatelessWidget {
  final Map<String, dynamic> diagramData;

  const FullscreenDiagramScreen({super.key, required this.diagramData});

  @override
  Widget build(BuildContext context) {
    final String type = diagramData['type'] ?? 'bar';
    final String title = diagramData['title'] ?? 'Chart';
    final GlobalKey chartKey = GlobalKey();

    // Calculate flexible height for fullscreen
    double getFullscreenHeight() {
      final screenHeight = MediaQuery.of(context).size.height;
      final data = diagramData['data'];
      
      switch (type.toLowerCase()) {
        case 'mindmap':
          final branches = data is Map ? (data['branches'] as List?) ?? [] : [];
          return (screenHeight * 0.8).clamp(400.0, screenHeight * 0.9);
        case 'flowchart':
          final steps = diagramData['steps'] ?? [];
          return (screenHeight * 0.7).clamp(300.0, screenHeight * 0.8);
        case 'gantt':
          final tasks = data is List ? data : [];
          return (screenHeight * 0.7).clamp(400.0, screenHeight * 0.8);
        case 'orgchart':
          return (screenHeight * 0.8).clamp(500.0, screenHeight * 0.9);
        case 'network':
          final nodes = data is Map ? (data['nodes'] as List?) ?? [] : [];
          return (screenHeight * 0.8).clamp(400.0, screenHeight * 0.9);
        case 'radar':
          return (screenHeight * 0.6).clamp(400.0, 600.0);
        case 'pie':
        case 'doughnut':
          return (screenHeight * 0.6).clamp(400.0, 600.0);
        default:
          final dataList = data is List ? data : [];
          return (screenHeight * 0.7).clamp(400.0, screenHeight * 0.8);
      }
    }

    double getFullscreenWidth() {
      final screenWidth = MediaQuery.of(context).size.width;
      
      switch (type.toLowerCase()) {
        case 'flowchart':
          final steps = diagramData['steps'] ?? [];
          return (screenWidth * 0.9).clamp(400.0, screenWidth * 0.95);
        case 'gantt':
          return (screenWidth * 0.9).clamp(500.0, screenWidth * 0.95);
        default:
          return screenWidth * 0.9;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFullscreenDiagram(context, chartKey, title, type),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: chartKey,
              child: Container(
                width: getFullscreenWidth(),
                height: getFullscreenHeight(),
                decoration: BoxDecoration(
                  color: Colors.white, // Clean white background for download
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title for the diagram
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // The actual diagram
                      Expanded(
                        child: DiagramService.buildChart(type, diagramData, context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadFullscreenDiagram(BuildContext context, GlobalKey chartKey, String title, String type) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading fullscreen diagram...')),
      );

      final RenderRepaintBoundary boundary = 
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // High resolution capture for better quality
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${type}_fullscreen_${DateTime.now().millisecondsSinceEpoch}.png';
      
      await _saveImageToAhamAIFolder(pngBytes, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fullscreen diagram saved to Downloads/AhamAI/$fileName')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving diagram: $error')),
      );
    }
  }

  Future<void> _saveImageToAhamAIFolder(Uint8List bytes, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory!.parent.parent.parent.parent.path}/Download';
      final ahamAIPath = '$downloadsPath/AhamAI';
      
      // Create AhamAI folder if it doesn't exist
      final ahamAIDirectory = Directory(ahamAIPath);
      if (!await ahamAIDirectory.exists()) {
        await ahamAIDirectory.create(recursive: true);
      }
      
      final file = File('$ahamAIPath/$fileName');
      await file.writeAsBytes(bytes);
    } catch (error) {
      // Fallback to app directory
      final directory = await getApplicationDocumentsDirectory();
      final ahamAIPath = '${directory.path}/AhamAI';
      
      final ahamAIDirectory = Directory(ahamAIPath);
      if (!await ahamAIDirectory.exists()) {
        await ahamAIDirectory.create(recursive: true);
      }
      
      final file = File('$ahamAIPath/$fileName');
      await file.writeAsBytes(bytes);
    }
  }
}