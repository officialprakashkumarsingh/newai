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
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
          // Simple title row with fixed save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
        return _buildBarChart(diagramData, context);
      case 'line':
        return _buildLineChart(diagramData, context);
      case 'pie':
        return _buildPieChart(diagramData, context);
      case 'doughnut':
        return _buildDoughnutChart(diagramData, context);
      case 'scatter':
        return _buildScatterChart(diagramData, context);
      case 'radar':
        return _buildRadarChart(diagramData);
      case 'area':
        return _buildAreaChart(diagramData, context);
      case 'flowchart':
        return _buildFlowChart(diagramData);
      case 'mindmap':
        return _buildMindMap(diagramData, context);
      case 'gantt':
        return _buildGanttChart(diagramData, context);
      case 'orgchart':
        return _buildOrgChart(diagramData, context);
      case 'network':
        return _buildNetworkDiagram(diagramData, context);
      default:
        return _buildBarChart(diagramData, context);
    }
  }

  static Widget _buildBarChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for bar chart'));
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartData.isNotEmpty 
          ? chartData.map((e) => (e['value'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2
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
                if (index >= 0 && index < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartData[index]['label']?.toString() ?? '',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: chartData.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['value'] as num?)?.toDouble() ?? 0,
                color: _getColorFromString(entry.value['color']?.toString() ?? 'blue'),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildLineChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for line chart'));
    }

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
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartData[index]['label']?.toString() ?? '',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY: chartData.isNotEmpty 
          ? chartData.map((e) => (e['value'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num?)?.toDouble() ?? 0,
              );
            }).toList(),
            isCurved: true,
            color: _getColorFromString(data['color']?.toString() ?? 'blue'),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  static Widget _buildPieChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for pie chart'));
    }

    final colors = [
      _getColorFromString('blue'),
      _getColorFromString('red'),
      _getColorFromString('green'),
      _getColorFromString('orange'),
      _getColorFromString('purple'),
      _getColorFromString('yellow'),
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num?)?.toDouble() ?? 0;
          final double total = chartData.fold(0.0, (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0));
          final double percentage = total > 0 ? (value / total) * 100 : 0;

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

  static Widget _buildDoughnutChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for doughnut chart'));
    }

    final colors = [
      _getColorFromString('blue'),
      _getColorFromString('red'),
      _getColorFromString('green'),
      _getColorFromString('orange'),
      _getColorFromString('purple'),
      _getColorFromString('yellow'),
    ];

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 80,
        sections: chartData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final double value = (item['value'] as num?)?.toDouble() ?? 0;
          final double total = chartData.fold(0.0, (sum, item) => sum + ((item['value'] as num?)?.toDouble() ?? 0));
          final double percentage = total > 0 ? (value / total) * 100 : 0;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildScatterChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for scatter chart'));
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: chartData.map<ScatterSpot>((item) {
          final x = (item['x'] as num?)?.toDouble() ?? 0;
          final y = (item['y'] as num?)?.toDouble() ?? 0;
          return ScatterSpot(x, y);
        }).toList(),
        minX: 0,
        maxX: chartData.isNotEmpty 
          ? chartData.map((e) => (e['x'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        minY: 0,
        maxY: chartData.isNotEmpty 
          ? chartData.map((e) => (e['y'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
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

  static Widget _buildAreaChart(Map<String, dynamic> data, BuildContext context) {
    final chartData = data['data'] as List<dynamic>? ?? [];
    
    if (chartData.isEmpty) {
      return const Center(child: Text('No data available for area chart'));
    }

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
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartData[index]['label']?.toString() ?? '',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY: chartData.isNotEmpty 
          ? chartData.map((e) => (e['value'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b) * 1.2
          : 100,
        lineBarsData: [
          LineChartBarData(
            spots: chartData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value['value'] as num?)?.toDouble() ?? 0,
              );
            }).toList(),
            isCurved: true,
            color: _getColorFromString(data['color']?.toString() ?? 'blue'),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _getColorFromString(data['color']?.toString() ?? 'blue').withOpacity(0.3),
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

  static Widget _buildGanttChart(Map<String, dynamic> data, BuildContext context) {
    final tasks = data['tasks'] as List<dynamic>? ?? [];
    
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks available for Gantt chart'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: math.max(600, tasks.length * 80.0),
        height: 300,
        child: CustomPaint(
          painter: GanttChartPainter(tasks),
          size: Size(math.max(600, tasks.length * 80.0), 300),
        ),
      ),
    );
  }

  static Widget _buildOrgChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as Map<String, dynamic>? ?? {};
    final String rootName = data['root'] ?? 'CEO';
    final List<dynamic> children = data['children'] ?? [];

    return CustomPaint(
      size: Size.infinite,
      painter: OrgChartPainter(data),
    );
  }

  static Widget _buildNetworkDiagram(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> nodes = data['nodes'] ?? [];
    final List<dynamic> connections = data['connections'] ?? [];

    return CustomPaint(
      size: Size.infinite,
      painter: NetworkDiagramPainter(data),
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

  // Custom snackbar with theme-appropriate styling
  static void showStyledSnackBar(BuildContext context, String message, {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        duration: duration ?? const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  static Future<void> downloadDiagram(GlobalKey chartKey, String title, String type, Map<String, dynamic> diagramData, BuildContext context) async {
    try {
      showStyledSnackBar(context, 'Saving diagram...');

      final boundary = chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        showStyledSnackBar(
          context, 
          'Error: Could not capture diagram. Please try again.',
          backgroundColor: Colors.red.shade600,
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final uint8List = byteData?.buffer.asUint8List();

      if (uint8List != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${title.replaceAll(' ', '_')}_${type}_$timestamp.png';
        
        final result = await _saveImageToAhamAIFolder(uint8List, fileName);
        if (result['success']) {
          showStyledSnackBar(
            context, 
            'Diagram saved as $fileName\nLocation: ${result['path']}',
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
          );
        } else {
          showStyledSnackBar(
            context, 
            'Error saving diagram: ${result['error']}',
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        showStyledSnackBar(
          context, 
          'Error capturing diagram image',
          backgroundColor: Colors.red.shade600,
        );
      }
    } catch (error) {
      print('Error in downloadDiagram: $error');
      showStyledSnackBar(
        context, 
        'Error saving diagram: ${error.toString()}',
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      );
    }
  }



  static Future<Map<String, dynamic>> _saveImageToAhamAIFolder(Uint8List bytes, String fileName) async {
    // Simple, reliable approach - just use app external directory (no permissions needed)
    try {
      print('Saving image with simplified approach...');
      
      // Get app-specific external directory (no permission required)
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final ahamAIPath = '${directory.path}/AhamAI';
        
        // Create AhamAI folder
        final ahamAIDirectory = Directory(ahamAIPath);
        if (!await ahamAIDirectory.exists()) {
          await ahamAIDirectory.create(recursive: true);
        }
        
        // Save file
        final filePath = '$ahamAIPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        print('✅ File saved successfully to: $filePath');
        return {
          'success': true,
          'path': 'App Storage/AhamAI/$fileName',
          'fullPath': filePath,
        };
      } else {
        throw Exception('External storage not available');
      }
    } catch (e) {
      print('❌ Save failed: $e');
      // Try app documents as absolute fallback
      try {
        final directory = await getApplicationDocumentsDirectory();
        final ahamAIPath = '${directory.path}/AhamAI';
        
        final ahamAIDirectory = Directory(ahamAIPath);
        if (!await ahamAIDirectory.exists()) {
          await ahamAIDirectory.create(recursive: true);
        }
        
        final filePath = '$ahamAIPath/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        print('✅ File saved to app documents: $filePath');
        return {
          'success': true,
          'path': 'Documents/AhamAI/$fileName',
          'fullPath': filePath,
        };
      } catch (finalError) {
        print('❌ Final save attempt failed: $finalError');
        return {
          'success': false,
          'error': 'Unable to save file: $finalError',
        };
      }
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
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final dataCount = data.length;
    if (dataCount == 0) return;

    // Draw radar grid
    for (int i = 1; i <= 5; i++) {
      final gridRadius = radius * i / 5;
      canvas.drawCircle(center, gridRadius, paint);
    }

    // Draw axes
    for (int i = 0; i < dataCount; i++) {
      final angle = (i * 2 * math.pi / dataCount) - math.pi / 2;
      final endPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endPoint, paint);
      
      // Draw labels
      final labelOffset = Offset(
        center.dx + (radius + 15) * math.cos(angle),
        center.dy + (radius + 15) * math.sin(angle),
      );
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i]['label']?.toString() ?? '',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelOffset.dx - textPainter.width / 2, labelOffset.dy - textPainter.height / 2),
      );
    }

    // Draw data
    final dataPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dataStroke = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < dataCount; i++) {
      final value = (data[i]['value'] as num?)?.toDouble() ?? 0;
      final maxValue = data.map((e) => (e['value'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);
      final normalizedValue = maxValue > 0 ? value / maxValue : 0;
      
      final angle = (i * 2 * math.pi / dataCount) - math.pi / 2;
      final point = Offset(
        center.dx + radius * normalizedValue * math.cos(angle),
        center.dy + radius * normalizedValue * math.sin(angle),
      );
      
      dataPoints.add(point);
      
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    
    if (dataPoints.isNotEmpty) {
      path.lineTo(dataPoints.first.dx, dataPoints.first.dy);
      canvas.drawPath(path, dataPaint);
      canvas.drawPath(path, dataStroke);
      
      // Draw data points
      for (final point in dataPoints) {
        canvas.drawCircle(point, 4, Paint()..color = Colors.blue);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GanttChartPainter extends CustomPainter {
  final List<dynamic> tasks;

  GanttChartPainter(this.tasks);

  @override
  void paint(Canvas canvas, Size size) {
    if (tasks.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final taskHeight = 40.0;
    final taskSpacing = 10.0;
    final leftMargin = 150.0;
    final topMargin = 30.0;

    // Find the maximum duration to scale the chart
    double maxDuration = 0;
    for (final task in tasks) {
      final start = (task['start'] as num?)?.toDouble() ?? 0;
      final duration = (task['duration'] as num?)?.toDouble() ?? 1;
      maxDuration = math.max(maxDuration, start + duration);
    }

    final chartWidth = size.width - leftMargin - 20;
    final scale = maxDuration > 0 ? chartWidth / maxDuration : 1;

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final taskName = task['name']?.toString() ?? 'Task ${i + 1}';
      final start = (task['start'] as num?)?.toDouble() ?? 0;
      final duration = (task['duration'] as num?)?.toDouble() ?? 1;
      
      final y = topMargin + i * (taskHeight + taskSpacing);
      final barX = leftMargin + start * scale;
      final barWidth = duration * scale;

      // Draw task bar
      paint.color = DiagramService._getColorFromString(task['color']?.toString() ?? 'blue');
      canvas.drawRRect(
        RRect.fromLTRBR(barX, y, barX + barWidth, y + taskHeight, const Radius.circular(4)),
        paint,
      );

      // Draw task name
      final textPainter = TextPainter(
        text: TextSpan(
          text: taskName,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout(maxWidth: leftMargin - 10);
      textPainter.paint(canvas, Offset(10, y + (taskHeight - textPainter.height) / 2));
    }

    // Draw time scale
    final timeSteps = 5;
    for (int i = 0; i <= timeSteps; i++) {
      final time = (maxDuration * i / timeSteps);
      final x = leftMargin + time * scale;
      
      // Draw time line
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()..color = Colors.grey.withOpacity(0.3)..strokeWidth = 1,
      );
      
      // Draw time label
      final textPainter = TextPainter(
        text: TextSpan(
          text: time.toStringAsFixed(1),
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 5));
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

    // Draw center node with better text handling
    paint.color = Colors.blue.shade700;
    final centerRadius = 50.0;
    canvas.drawCircle(center, centerRadius, paint);

    // Draw center text with proper wrapping
    final centerWords = centerText.split(' ');
    final centerDisplayText = centerWords.length > 3 ? '${centerWords.take(3).join(' ')}...' : centerText;
    
    final centerTextPainter = TextPainter(
      text: TextSpan(
        text: centerDisplayText,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    centerTextPainter.layout(maxWidth: centerRadius * 1.6);
    centerTextPainter.paint(
      canvas,
      Offset(center.dx - centerTextPainter.width / 2, center.dy - centerTextPainter.height / 2),
    );

    // Draw branches with improved spacing to prevent collisions
    final distanceFromCenter = math.max(200.0, branches.length * 35.0); // Distance from center to branch centers
    final angleStep = 2 * math.pi / math.max(branches.length, 4); // Ensure minimum spacing
    
    for (int i = 0; i < branches.length; i++) {
      final branch = branches[i];
      final angle = i * angleStep;
      
      // Calculate node size based on text
      final branchText = branch['title'] ?? 'Branch';
      final textBasedSize = (branchText.length.toDouble() * 3.5).clamp(35.0, 55.0);
      final branchNodeRadius = math.max<double>(40.0, textBasedSize);
      
      final branchCenter = Offset(
        center.dx + distanceFromCenter * math.cos(angle),
        center.dy + distanceFromCenter * math.sin(angle),
      );

      // Draw connection line with proper clipping
      final linePaint = Paint()
        ..color = Colors.grey.shade600
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      // Calculate line endpoints to avoid cutting through nodes
      final centerEdge = Offset(
        center.dx + (centerRadius + 5) * math.cos(angle),
        center.dy + (centerRadius + 5) * math.sin(angle),
      );
      final branchEdge = Offset(
        branchCenter.dx - branchNodeRadius * math.cos(angle),
        branchCenter.dy - branchNodeRadius * math.sin(angle),
      );
      canvas.drawLine(centerEdge, branchEdge, linePaint);

      // Draw branch node with dynamic sizing based on text
      final color = DiagramService._getColorFromString(branch['color'] ?? 'green');
      
      paint.color = color;
      canvas.drawCircle(branchCenter, branchNodeRadius, paint);

      // Draw branch text with better wrapping
      final words = branchText.split(' ');
      String displayText;
      if (branchText.length <= 15) {
        displayText = branchText;
      } else if (words.length > 1) {
        displayText = '${words.first}\n${words.skip(1).join(' ')}';
        if (displayText.length > 20) {
          displayText = '${words.first}\n${words.skip(1).take(2).join(' ')}...';
        }
      } else {
        displayText = '${branchText.substring(0, 12)}...';
      }
      
      final branchTextPainter = TextPainter(
        text: TextSpan(
          text: displayText,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      branchTextPainter.layout(maxWidth: branchNodeRadius * 1.6);
      branchTextPainter.paint(
        canvas,
        Offset(branchCenter.dx - branchTextPainter.width / 2, branchCenter.dy - branchTextPainter.height / 2),
      );

      // Draw sub-branches with improved positioning and clipping
      final subbranches = branch['subbranches'] as List<dynamic>? ?? [];
      if (subbranches.isNotEmpty) {
        final subDistanceFromBranch = 100.0; // Distance from branch center to sub-nodes
        final subAngleRange = math.pi / 2; // 90 degree spread for sub-branches
        final subAngleStep = subAngleRange / math.max(subbranches.length - 1, 1);
        final startSubAngle = angle - subAngleRange / 2;
        
        for (int j = 0; j < subbranches.length; j++) {
          final subAngle = startSubAngle + (j * subAngleStep);
          
          // Calculate sub-node size first
          final subText = subbranches[j].toString();
          final subTextBasedSize = (subText.length.toDouble() * 2.5).clamp(20.0, 35.0);
          final subNodeRadius = math.max<double>(25.0, subTextBasedSize);
          
          final subCenter = Offset(
            branchCenter.dx + subDistanceFromBranch * math.cos(subAngle),
            branchCenter.dy + subDistanceFromBranch * math.sin(subAngle),
          );

          // Draw sub-connection with proper edge calculation
          final branchSubEdge = Offset(
            branchCenter.dx + branchNodeRadius * math.cos(subAngle),
            branchCenter.dy + branchNodeRadius * math.sin(subAngle),
          );
          final subEdge = Offset(
            subCenter.dx - subNodeRadius * math.cos(subAngle),
            subCenter.dy - subNodeRadius * math.sin(subAngle),
          );
          canvas.drawLine(branchSubEdge, subEdge, linePaint);

          // Draw sub-node with dynamic sizing
          
          paint.color = color.withOpacity(0.85);
          canvas.drawCircle(subCenter, subNodeRadius, paint);

          // Draw sub-text with better handling
          String displaySubText;
          if (subText.length <= 10) {
            displaySubText = subText;
          } else if (subText.contains(' ')) {
            final subWords = subText.split(' ');
            displaySubText = subWords.length > 1 ? '${subWords.first}\n${subWords.skip(1).first}' : subText.substring(0, 8) + '...';
          } else {
            displaySubText = '${subText.substring(0, 8)}...';
          }
          
          final subTextPainter = TextPainter(
            text: TextSpan(
              text: displaySubText,
              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          );
          subTextPainter.layout(maxWidth: subNodeRadius * 1.6);
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
  final Map<String, dynamic> orgData;

  OrgChartPainter(this.orgData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, 50);
    final boxWidth = 120.0;
    final boxHeight = 40.0;
    final levelHeight = 80.0;

    void drawNode(Map<String, dynamic> node, Offset position, int level) {
      // Draw box
      final rect = Rect.fromCenter(
        center: position,
        width: boxWidth,
        height: boxHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: node['name']?.toString() ?? 'Node',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: boxWidth - 10);
      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
      );

      // Draw children
      final children = node['children'] as List<dynamic>? ?? [];
      if (children.isNotEmpty) {
        final childY = position.dy + levelHeight;
        final totalWidth = children.length * (boxWidth + 20) - 20;
        final startX = position.dx - totalWidth / 2 + boxWidth / 2;

        for (int i = 0; i < children.length; i++) {
          final childX = startX + i * (boxWidth + 20);
          final childPosition = Offset(childX, childY);

          // Draw line to child
          canvas.drawLine(
            Offset(position.dx, position.dy + boxHeight / 2),
            Offset(childPosition.dx, childPosition.dy - boxHeight / 2),
            linePaint,
          );

          // Recursively draw child
          drawNode(children[i], childPosition, level + 1);
        }
      }
    }

    drawNode(orgData, center, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NetworkDiagramPainter extends CustomPainter {
  final Map<String, dynamic> networkData;

  NetworkDiagramPainter(this.networkData);

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = networkData['nodes'] as List<dynamic>? ?? [];
    final edges = networkData['edges'] as List<dynamic>? ?? [];
    
    if (nodes.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Position nodes in a circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 50;
    final nodePositions = <String, Offset>{};
    final nodeRadius = 25.0;

    // Calculate node positions
    for (int i = 0; i < nodes.length; i++) {
      final angle = (i * 2 * math.pi / nodes.length);
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      nodePositions[nodes[i]['id']?.toString() ?? i.toString()] = position;
    }

    // Draw edges
    for (final edge in edges) {
      final sourceId = edge['source']?.toString() ?? '';
      final targetId = edge['target']?.toString() ?? '';
      final sourcePos = nodePositions[sourceId];
      final targetPos = nodePositions[targetId];

      if (sourcePos != null && targetPos != null) {
        canvas.drawLine(sourcePos, targetPos, linePaint);
      }
    }

    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final nodeId = node['id']?.toString() ?? i.toString();
      final position = nodePositions[nodeId];
      
      if (position != null) {
        // Draw node circle
        paint.color = DiagramService._getColorFromString(node['color']?.toString() ?? 'blue');
        canvas.drawCircle(position, nodeRadius, paint);

        // Draw node label
        final textPainter = TextPainter(
          text: TextSpan(
            text: node['label']?.toString() ?? nodeId,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout(maxWidth: nodeRadius * 2 - 4);
        textPainter.paint(
          canvas,
          Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}