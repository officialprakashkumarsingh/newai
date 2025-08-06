import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';

import 'api_service.dart';

class DiagramService {
  static Future<Map<String, dynamic>?> generateDiagramData(String prompt, String selectedModel) async {
    try {
      print('Starting diagram generation for: $prompt');
      
      // Collect the complete AI response from the stream
      String fullResponse = '';
      await for (final chunk in ApiService.sendChatMessage(
        message: '''Create structured data for this diagram request: "$prompt"

IMPORTANT: Respond with ONLY a valid JSON object (no markdown, no explanation, no extra text).

For bar/line/pie/doughnut/area charts, use this exact format:
{
  "type": "bar",
  "title": "Your Chart Title",
  "data": [
    {"label": "Category 1", "value": 25},
    {"label": "Category 2", "value": 35},
    {"label": "Category 3", "value": 40}
  ]
}

For scatter charts, use this format:
{
  "type": "scatter",
  "title": "Scatter Plot Title",
  "data": [
    {"x": 10, "y": 20, "label": "Point 1"},
    {"x": 15, "y": 30, "label": "Point 2"},
    {"x": 25, "y": 15, "label": "Point 3"}
  ]
}

For radar charts, use this format:
{
  "type": "radar",
  "title": "Performance Analysis",
  "data": [
    {"category": "Speed", "value": 80},
    {"category": "Accuracy", "value": 95},
    {"category": "Efficiency", "value": 70}
  ]
}

For mindmap, use this format:
{
  "type": "mindmap",
  "title": "Central Topic",
  "data": {
    "center": "Main Idea",
    "branches": [
      {
        "title": "Branch 1",
        "color": "blue",
        "subbranches": ["Sub 1", "Sub 2"]
      },
      {
        "title": "Branch 2", 
        "color": "green",
        "subbranches": ["Sub A", "Sub B", "Sub C"]
      }
    ]
  }
}

For flowcharts, use this exact format:
{
  "type": "flowchart",
  "title": "Process Title",
  "steps": [
    {"id": "start", "text": "Start", "type": "start"},
    {"id": "step1", "text": "Step 1", "type": "process"},
    {"id": "decision1", "text": "Decision?", "type": "decision"},
    {"id": "end", "text": "End", "type": "end"}
  ],
  "connections": [
    {"from": "start", "to": "step1"},
    {"from": "step1", "to": "decision1"},
    {"from": "decision1", "to": "end"}
  ]
}

For gantt charts, use this format:
{
  "type": "gantt",
  "title": "Project Timeline",
  "data": [
    {"task": "Task 1", "start": 0, "duration": 5, "color": "blue"},
    {"task": "Task 2", "start": 3, "duration": 4, "color": "green"},
    {"task": "Task 3", "start": 6, "duration": 3, "color": "orange"}
  ]
}

For org charts, use this format:
{
  "type": "orgchart",
  "title": "Organization Structure",
  "data": {
    "root": "CEO",
    "children": [
      {
        "name": "CTO",
        "children": ["Dev Lead", "QA Lead"]
      },
      {
        "name": "CFO", 
        "children": ["Accountant", "Finance Manager"]
      }
    ]
  }
}

For network diagrams, use this format:
{
  "type": "network",
  "title": "Network Topology",
  "data": {
    "nodes": [
      {"id": "router", "label": "Router", "type": "router"},
      {"id": "server", "label": "Server", "type": "server"},
      {"id": "client1", "label": "Client 1", "type": "client"}
    ],
    "connections": [
      {"from": "router", "to": "server"},
      {"from": "router", "to": "client1"}
    ]
  }
}

Valid types: "bar", "line", "pie", "doughnut", "scatter", "radar", "area", "flowchart", "mindmap", "gantt", "orgchart", "network", "timeline", "venn"
Generate realistic data relevant to: $prompt''',
        model: selectedModel,
      )) {
        fullResponse += chunk;
      }

      print('AI Response: $fullResponse');
      
      // Clean the response - remove markdown formatting if present
      String cleanResponse = fullResponse.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      
      cleanResponse = cleanResponse.trim();
      print('Cleaned Response: $cleanResponse');

      // Parse the JSON response
      final jsonData = json.decode(cleanResponse);
      print('Parsed JSON: $jsonData');
      
      // Validate the response structure
      if (jsonData is Map<String, dynamic> && 
          jsonData.containsKey('type') && 
          jsonData.containsKey('title')) {
        return jsonData;
      } else {
        throw Exception('Invalid response structure from AI');
      }
      
    } catch (error) {
      print('Error generating diagram data: $error');
      return null;
    }
  }

  static Widget buildDiagramWidget(Map<String, dynamic> diagramData, BuildContext context, Function(Map<String, dynamic>) onFullscreen) {
    final String type = diagramData['type'] ?? 'bar';
    final String title = diagramData['title'] ?? 'Chart';
    final GlobalKey chartKey = GlobalKey();

    // Calculate flexible dimensions based on chart type and data
    Size getFlexibleSize() {
      final data = diagramData['data'];
      double width = 400; // Default width
      double height = 300; // Default height
      
      switch (type.toLowerCase()) {
        case 'mindmap':
          final branches = data is Map ? (data['branches'] as List?) ?? [] : [];
          width = math.max(500, branches.length * 120.0 + 300);
          height = math.max(400, branches.length * 100.0 + 300);
          break;
        case 'flowchart':
          final steps = diagramData['steps'] ?? [];
          width = math.max(600, steps.length * 150.0 + 200);
          height = math.max(250, 350);
          break;
        case 'gantt':
          final tasks = data is List ? data : [];
          width = math.max(800, 1000); // Wide for timeline
          height = math.max(300, tasks.length * 50.0 + 150);
          break;
        case 'orgchart':
          width = 600;
          height = 500;
          break;
        case 'network':
          final nodes = data is Map ? (data['nodes'] as List?) ?? [] : [];
          width = math.max(500, nodes.length * 80.0 + 300);
          height = math.max(400, nodes.length * 60.0 + 300);
          break;
        case 'radar':
          width = 400;
          height = 400;
          break;
        case 'pie':
        case 'doughnut':
          width = 350;
          height = 350;
          break;
        default:
          final dataList = data is List ? data : [];
          width = math.max(400, dataList.length * 60.0 + 200);
          height = math.max(300, dataList.length * 30.0 + 200);
      }
      
      return Size(width, height);
    }

    final size = getFlexibleSize();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => downloadDiagram(chartKey, title, type, diagramData, context),
                  tooltip: 'Save',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          // Direct diagram rendering without extra containers
          Container(
            height: math.min(size.height, 350),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(10),
              minScale: 0.1,
              maxScale: 5.0,
              constrained: false,
              child: RepaintBoundary(
                key: chartKey,
                child: Container(
                  width: size.width,
                  height: size.height,
                  child: _buildOptimizedChart(type, diagramData, context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _getChartIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bar': return const Icon(Icons.bar_chart, size: 20);
      case 'line': return const Icon(Icons.show_chart, size: 20);
      case 'pie': case 'doughnut': return const Icon(Icons.pie_chart, size: 20);
      case 'scatter': return const Icon(Icons.scatter_plot, size: 20);
      case 'radar': return const Icon(Icons.radar, size: 20);
      case 'area': return const Icon(Icons.area_chart, size: 20);
      case 'flowchart': return const Icon(Icons.account_tree, size: 20);
      case 'mindmap': return const Icon(Icons.account_tree, size: 20);
      case 'gantt': return const Icon(Icons.timeline, size: 20);
      case 'orgchart': return const Icon(Icons.corporate_fare, size: 20);
      case 'network': return const Icon(Icons.hub, size: 20);
      default: return const Icon(Icons.bar_chart, size: 20);
    }
  }

  static Widget _buildOptimizedChart(String type, Map<String, dynamic> diagramData, BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildChartAsync(type, diagramData, context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error rendering chart: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        return snapshot.data ?? const Center(child: Text('Failed to render chart'));
      },
    );
  }

  static Future<Widget> _buildChartAsync(String type, Map<String, dynamic> diagramData, BuildContext context) async {
    return Future.microtask(() => buildChart(type, diagramData, context));
  }

  static Widget buildChart(String type, Map<String, dynamic> diagramData, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'bar':
        return _buildBarChart(diagramData);
      case 'line':
        return _buildLineChart(diagramData);
      case 'pie':
        return _buildPieChart(diagramData);
      case 'doughnut':
        return _buildDoughnutChart(diagramData);
      case 'scatter':
        return _buildScatterChart(diagramData);
      case 'radar':
        return _buildRadarChart(diagramData);
      case 'area':
        return _buildAreaChart(diagramData);
      case 'flowchart':
        return _buildFlowChart(diagramData);
      case 'mindmap':
        return _buildMindMap(diagramData, context);
      case 'gantt':
        return _buildGanttChart(diagramData);
      case 'orgchart':
        return _buildOrgChart(diagramData, context);
      case 'network':
        return _buildNetworkDiagram(diagramData, context);
      default:
        return _buildBarChart(diagramData);
    }
  }

  static Widget _buildBarChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['value'] as num).toDouble(),
                color: Colors.lightBlueAccent,
                width: 22,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildLineChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPieChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num).toDouble();
          final double total = data.fold(0.0, (sum, item) => sum + (item['value'] as num));
          final double percentage = (value / total) * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildDoughnutChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 80,
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num).toDouble();
          final double total = data.fold(0.0, (sum, item) => sum + (item['value'] as num));
          final double percentage = (value / total) * 100;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildScatterChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.map((item) {
              final x = (item['x'] as num?)?.toDouble() ?? 0;
              final y = (item['y'] as num?)?.toDouble() ?? 0;
              return FlSpot(x, y);
            }).toList(),
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRadarChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return CustomPaint(
      size: const Size(250, 250),
      painter: RadarChartPainter(data),
    );
  }

  static Widget _buildAreaChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index]['label'] ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.isNotEmpty 
          ? data.map((e) => (e['value'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.3),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.6),
                  Colors.blue.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFlowChart(Map<String, dynamic> diagramData) {
    final List<dynamic> steps = diagramData['steps'] ?? [];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final step = entry.value;
          final isLast = entry.key == steps.length - 1;
          
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getFlowChartStepColor(step['type']),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  step['text'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildMindMap(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as Map<String, dynamic>? ?? {};
    final String centerText = data['center'] ?? 'Main Topic';
    final List<dynamic> branches = data['branches'] ?? [];

    return CustomPaint(
      size: Size.infinite,
      painter: MindMapPainter(centerText, branches, context),
    );
  }

  static Widget _buildGanttChart(Map<String, dynamic> diagramData) {
    final List<dynamic> data = diagramData['data'] ?? [];
    final int maxWeeks = 12; // Timeline weeks
    final double weekWidth = 80.0; // Width per week
    final double taskHeight = 45.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline header
        Container(
          height: 35,
          child: Row(
            children: [
              // Task name header
              Container(
                width: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Task',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              // Week headers
              ...List.generate(maxWeeks, (index) => 
                Container(
                  width: weekWidth,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    'W${index + 1}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tasks
        ...data.asMap().entries.map((entry) {
          final task = entry.value;
          final taskName = task['task'] ?? 'Task ${entry.key + 1}';
          final start = (task['start'] as num?)?.toDouble() ?? 0;
          final duration = (task['duration'] as num?)?.toDouble() ?? 1;
          final color = _getColorFromString(task['color'] ?? 'blue');

          return Container(
            height: taskHeight,
            child: Row(
              children: [
                // Task name
                Container(
                  width: 150,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    taskName,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Timeline area
                Container(
                  width: maxWeeks * weekWidth,
                  height: taskHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines
                      ...List.generate(maxWeeks, (index) => 
                        Positioned(
                          left: index * weekWidth,
                          child: Container(
                            width: 1,
                            height: taskHeight,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      // Task bar
                      Positioned(
                        left: start * weekWidth,
                        child: Container(
                          height: 25,
                          width: duration * weekWidth,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${duration.toInt()}w',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static Widget _buildOrgChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as Map<String, dynamic>? ?? {};
    final String rootName = data['root'] ?? 'CEO';
    final List<dynamic> children = data['children'] ?? [];

    return CustomPaint(
      size: Size.infinite,
      painter: OrgChartPainter(rootName, children, context),
    );
  }

  static Widget _buildNetworkDiagram(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> nodes = data['nodes'] ?? [];
    final List<dynamic> connections = data['connections'] ?? [];

    return CustomPaint(
      size: Size.infinite,
      painter: NetworkDiagramPainter(nodes, connections, context),
    );
  }

  static Color _getFlowChartStepColor(String? type) {
    switch (type) {
      case 'start': return Colors.green;
      case 'end': return Colors.red;
      case 'decision': return Colors.orange;
      case 'process':
      default: return Colors.blue;
    }
  }

  static Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'amber': return Colors.amber;
      default: return Colors.blue;
    }
  }

  static Future<void> downloadDiagram(GlobalKey chartKey, String title, String type, Map<String, dynamic> diagramData, BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving diagram...'), duration: Duration(seconds: 1)),
      );

      final RenderRepaintBoundary boundary = 
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Get the actual size of the diagram
      final size = boundary.size;
      print('Diagram size: ${size.width} x ${size.height}');
      
      // Capture at high resolution to ensure full diagram is saved
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      print('Image size: ${image.width} x ${image.height} pixels');

      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${type}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      await _saveImageToAhamAIFolder(pngBytes, fileName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagram saved to Downloads/AhamAI/$fileName'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (error) {
      print('Error saving diagram: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving diagram: $error')),
      );
    }
  }

  static Future<void> _saveImageToAhamAIFolder(Uint8List bytes, String fileName) async {
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

// Custom Painters for complex diagrams
class RadarChartPainter extends CustomPainter {
  final List<dynamic> data;
  
  RadarChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw radar grid
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, paint);
    }

    // Draw axes
    final angleStep = 2 * math.pi / data.length;
    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
    }

    // Draw data points
    final dataPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dataPath = Path();
    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = (data[i]['value'] as num?)?.toDouble() ?? 0;
      final normalizedValue = (value / 100) * radius;
      
      final point = Offset(
        center.dx + normalizedValue * math.cos(angle),
        center.dy + normalizedValue * math.sin(angle),
      );
      
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);

    // Draw data point circles
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = (data[i]['value'] as num?)?.toDouble() ?? 0;
      final normalizedValue = (value / 100) * radius;
      
      final point = Offset(
        center.dx + normalizedValue * math.cos(angle),
        center.dy + normalizedValue * math.sin(angle),
      );
      
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MindMapPainter extends CustomPainter {
  final String centerText;
  final List<dynamic> branches;
  final BuildContext context;
  
  MindMapPainter(this.centerText, this.branches, this.context);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw center node
    paint.color = Colors.blue;
    canvas.drawCircle(center, 40, paint);

    // Draw center text
    final centerTextPainter = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    centerTextPainter.layout();
    centerTextPainter.paint(
      canvas,
      Offset(center.dx - centerTextPainter.width / 2, center.dy - centerTextPainter.height / 2),
    );

    // Draw branches with improved spacing
    final branchRadius = math.max(150, branches.length * 25.0); // Dynamic radius based on branch count
    final angleStep = 2 * math.pi / math.max(branches.length, 4); // Ensure minimum spacing
    
    for (int i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final angle = i * angleStep;
      final branchCenter = Offset(
        center.dx + branchRadius * math.cos(angle),
        center.dy + branchRadius * math.sin(angle),
      );

      // Draw connection line
      final linePaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 3;
      canvas.drawLine(center, branchCenter, linePaint);

      // Draw branch node with better sizing
      final color = DiagramService._getColorFromString(branch['color'] ?? 'green');
      paint.color = color;
      canvas.drawCircle(branchCenter, 35, paint);

      // Draw branch text with word wrapping
      final branchText = branch['title'] ?? 'Branch';
      final words = branchText.split(' ');
      final displayText = words.length > 2 ? '${words.take(2).join(' ')}...' : branchText;
      
      final branchTextPainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      branchTextPainter.layout(maxWidth: 60);
      branchTextPainter.paint(
        canvas,
        Offset(branchCenter.dx - branchTextPainter.width / 2, branchCenter.dy - branchTextPainter.height / 2),
      );

      // Draw sub-branches with improved positioning
      final subbranches = branch['subbranches'] as List<dynamic>? ?? [];
      if (subbranches.isNotEmpty) {
        final subRadius = 80; // Fixed sub-branch radius
        final subAngleRange = math.pi / 2; // 90 degree spread for sub-branches
        final subAngleStep = subAngleRange / math.max(subbranches.length - 1, 1);
        final startSubAngle = angle - subAngleRange / 2;
        
        for (int j = 0; j < subbranches.length; j++) {
          final subAngle = startSubAngle + (j * subAngleStep);
          final subCenter = Offset(
            branchCenter.dx + subRadius * math.cos(subAngle),
            branchCenter.dy + subRadius * math.sin(subAngle),
          );

          // Draw sub-connection
          canvas.drawLine(branchCenter, subCenter, linePaint);

          // Draw sub-node
          paint.color = color.withOpacity(0.8);
          canvas.drawCircle(subCenter, 20, paint);

          // Draw sub-text with truncation
          final subText = subbranches[j].toString();
          final truncatedSubText = subText.length > 12 ? '${subText.substring(0, 12)}...' : subText;
          
          final subTextPainter = TextPainter(
            text: TextSpan(
              text: truncatedSubText,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          subTextPainter.layout(maxWidth: 35);
          subTextPainter.paint(
            canvas,
            Offset(subCenter.dx - subTextPainter.width / 2, subCenter.dy - subTextPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class OrgChartPainter extends CustomPainter {
  final String rootName;
  final List<dynamic> children;
  final BuildContext context;
  
  OrgChartPainter(this.rootName, this.children, this.context);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw root
    final rootRect = Rect.fromCenter(
      center: Offset(size.width / 2, 60),
      width: 120,
      height: 40,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(rootRect, const Radius.circular(8)), paint);

    // Draw root text
    final rootTextPainter = TextPainter(
      text: TextSpan(
        text: rootName,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    rootTextPainter.layout();
    rootTextPainter.paint(
      canvas,
      Offset(rootRect.center.dx - rootTextPainter.width / 2, rootRect.center.dy - rootTextPainter.height / 2),
    );

    // Draw children
    final childWidth = size.width / children.length;
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final childName = child['name'] ?? 'Employee';
      final childCenter = Offset(childWidth * i + childWidth / 2, 160);

      // Draw connection line
      final linePaint = Paint()
        ..color = Colors.grey
        ..strokeWidth = 2;
      canvas.drawLine(rootRect.bottomCenter, childCenter.translate(0, -20), linePaint);

      // Draw child box
      final childRect = Rect.fromCenter(
        center: childCenter,
        width: 100,
        height: 40,
      );
      paint.color = Colors.green;
      canvas.drawRRect(RRect.fromRectAndRadius(childRect, const Radius.circular(8)), paint);

      // Draw child text
      final childTextPainter = TextPainter(
        text: TextSpan(
          text: childName,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      childTextPainter.layout();
      childTextPainter.paint(
        canvas,
        Offset(childRect.center.dx - childTextPainter.width / 2, childRect.center.dy - childTextPainter.height / 2),
      );

      // Draw grandchildren
      final grandChildren = child['children'] as List<dynamic>? ?? [];
      if (grandChildren.isNotEmpty) {
        final grandChildWidth = childWidth / grandChildren.length;
        for (int j = 0; j < grandChildren.length; j++) {
          final grandChildName = grandChildren[j].toString();
          final grandChildCenter = Offset(
            childCenter.dx - childWidth / 2 + grandChildWidth * j + grandChildWidth / 2,
            260,
          );

          // Draw connection
          canvas.drawLine(childRect.bottomCenter, grandChildCenter.translate(0, -20), linePaint);

          // Draw grandchild box
          final grandChildRect = Rect.fromCenter(
            center: grandChildCenter,
            width: 80,
            height: 30,
          );
          paint.color = Colors.orange;
          canvas.drawRRect(RRect.fromRectAndRadius(grandChildRect, const Radius.circular(6)), paint);

          // Draw grandchild text
          final grandChildTextPainter = TextPainter(
            text: TextSpan(
              text: grandChildName,
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
            textDirection: TextDirection.ltr,
          );
          grandChildTextPainter.layout();
          grandChildTextPainter.paint(
            canvas,
            Offset(grandChildRect.center.dx - grandChildTextPainter.width / 2, grandChildRect.center.dy - grandChildTextPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NetworkDiagramPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> connections;
  final BuildContext context;
  
  NetworkDiagramPainter(this.nodes, this.connections, this.context);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Position nodes in a circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    Map<String, Offset> nodePositions = {};

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final nodeId = node['id'] ?? 'node_$i';
      final angle = (i / nodes.length) * 2 * math.pi;
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      nodePositions[nodeId] = position;

      // Draw node
      Color nodeColor;
      switch (node['type']) {
        case 'router': nodeColor = Colors.blue; break;
        case 'server': nodeColor = Colors.green; break;
        case 'client': nodeColor = Colors.orange; break;
        default: nodeColor = Colors.grey;
      }
      
      paint.color = nodeColor;
      canvas.drawCircle(position, 25, paint);

      // Draw node label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node['label'] ?? nodeId,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
      );
    }

    // Draw connections
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    for (final connection in connections) {
      final fromId = connection['from'];
      final toId = connection['to'];
      final fromPos = nodePositions[fromId];
      final toPos = nodePositions[toId];

      if (fromPos != null && toPos != null) {
        canvas.drawLine(fromPos, toPos, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}