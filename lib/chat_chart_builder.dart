import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import 'theme.dart';

/// Chart Builder for Chat Screen - Contains all chart/diagram building logic
/// This class contains ALL the chart building methods moved from chat_screen.dart
class ChatChartBuilder {
  
  /// Build diagram widget with all chart types
  static Widget buildDiagramWidget(Map<String, dynamic> diagramData, BuildContext context) {
    final type = diagramData['type'] as String? ?? 'bar';
    
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diagramData['title'] as String? ?? 'Chart',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: buildChart(type, diagramData, context),
          ),
        ],
      ),
    );
  }

  /// Build chart based on type
  static Widget buildChart(String type, Map<String, dynamic> diagramData, BuildContext context) {
    switch (type.toLowerCase()) {
      case 'bar':
        return buildBarChart(diagramData, context);
      case 'line':
        return buildLineChart(diagramData, context);
      case 'pie':
        return buildPieChart(diagramData, context);
      case 'doughnut':
        return buildDoughnutChart(diagramData, context);
      case 'scatter':
        return buildScatterChart(diagramData, context);
      case 'radar':
        return buildRadarChart(diagramData, context);
      case 'area':
        return buildAreaChart(diagramData, context);
      case 'flowchart':
        return buildFlowChart(diagramData, context);
      default:
        return buildOptimizedChart(type, diagramData, context);
    }
  }

  /// Build bar chart
  static Widget buildBarChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Theme.of(context).primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => (e['value'] as num?)?.toDouble() ?? 0.0).reduce(math.max) * 1.2,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    data[index]['label'] as String? ?? '',
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  /// Build line chart
  static Widget buildLineChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index, value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    data[index]['label'] as String? ?? '',
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// Build pie chart
  static Widget buildPieChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final sections = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';
      
      final colors = [
        Theme.of(context).primaryColor,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.amber,
      ];
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '$label\n${value.toStringAsFixed(1)}',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  /// Build doughnut chart  
  static Widget buildDoughnutChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final sections = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value as Map<String, dynamic>;
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      final label = item['label'] as String? ?? '';
      
      final colors = [
        Theme.of(context).primaryColor,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.amber,
      ];
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: label,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 80,
      ),
    );
  }

  /// Build scatter chart
  static Widget buildScatterChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final spots = data.map((item) {
      final x = (item['x'] as num?)?.toDouble() ?? 0.0;
      final y = (item['y'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(x, y);
    }).toList();

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots.asMap().entries.map((entry) {
          return ScatterSpot(
            entry.value.x,
            entry.value.y,
          );
        }).toList(),
        minX: spots.map((s) => s.x).reduce(math.min),
        maxX: spots.map((s) => s.x).reduce(math.max),
        minY: spots.map((s) => s.y).reduce(math.min),
        maxY: spots.map((s) => s.y).reduce(math.max),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  /// Build radar chart
  static Widget buildRadarChart(Map<String, dynamic> diagramData, BuildContext context) {
    return const Center(
      child: Text('Radar Chart\n(Advanced chart type)', textAlign: TextAlign.center),
    );
  }

  /// Build area chart
  static Widget buildAreaChart(Map<String, dynamic> diagramData, BuildContext context) {
    final data = diagramData['data'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const Center(child: Text('No data available'));

    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index, value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Text(
                    data[index]['label'] as String? ?? '',
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  /// Build flow chart
  static Widget buildFlowChart(Map<String, dynamic> diagramData, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('Flow Chart\n(Custom flowchart rendering)', textAlign: TextAlign.center),
      ),
    );
  }

  /// Build optimized chart for unknown types
  static Widget buildOptimizedChart(String type, Map<String, dynamic> diagramData, BuildContext context) {
    return buildBarChart(diagramData, context); // Fallback to bar chart
  }

  /// Build fullscreen chart
  static Widget buildFullscreenChart(String type, Map<String, dynamic> diagramData, BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            diagramData['title'] as String? ?? 'Chart',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: buildChart(type, diagramData, context),
          ),
        ],
      ),
    );
  }

  /// Build fullscreen bar chart
  static Widget buildFullscreenBarChart(Map<String, dynamic> diagramData, BuildContext context) {
    return buildFullscreenChart('bar', diagramData, context);
  }

  // Fullscreen chart methods (delegates to main chart builders)
  static Widget buildFullscreenLineChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('line', data, context);
  
  static Widget buildFullscreenPieChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('pie', data, context);
  
  static Widget buildFullscreenDoughnutChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('doughnut', data, context);
  
  static Widget buildFullscreenScatterChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('scatter', data, context);
  
  static Widget buildFullscreenRadarChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('radar', data, context);
  
  static Widget buildFullscreenAreaChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('area', data, context);
  
  static Widget buildFullscreenFlowChart(Map<String, dynamic> data, BuildContext context) => 
      buildFullscreenChart('flowchart', data, context);
}