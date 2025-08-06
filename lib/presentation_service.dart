import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ahamai/diagram_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'api_service.dart';

class PresentationService {
  static Future<Map<String, dynamic>?> generatePresentationData(String topic, String selectedModel) async {
    try {
      print('Starting presentation generation for: $topic');
      
      String fullResponse = '';
      await for (final chunk in ApiService.sendChatMessage(
        message: '''Create a comprehensive presentation for this topic: "$topic"

IMPORTANT: Respond with ONLY a valid JSON object (no markdown, no explanation, no extra text).

Use this exact format with ANY NUMBER OF SLIDES based on topic complexity:
{
  "title": "Presentation Title",
  "subtitle": "Brief subtitle or tagline",
  "slides": [
    {
      "type": "title",
      "title": "Main Title",
      "subtitle": "Subtitle or description",
      "background": "blue"
    },
    {
      "type": "content",
      "title": "Slide Title",
      "content": [
        "• First point with detailed explanation",
        "• Second point with examples",
        "• Third point with benefits"
      ],
      "background": "white"
    },
    {
      "type": "formula",
      "title": "Mathematical Formula",
      "formula": "E = mc²",
      "explanation": "Einstein's mass-energy equivalence equation",
      "variables": [
        {"symbol": "E", "meaning": "Energy"},
        {"symbol": "m", "meaning": "Mass"},
        {"symbol": "c", "meaning": "Speed of light"}
      ],
      "background": "white"
    },
    {
      "type": "comparison",
      "title": "Comparison Slide",
      "left_title": "Before/Option A",
      "right_title": "After/Option B", 
      "left_content": [
        "• Point 1",
        "• Point 2"
      ],
      "right_content": [
        "• Point 1",
        "• Point 2"
      ],
      "background": "gradient"
    },
    {
      "type": "diagram",
      "title": "Process Flow Diagram",
      "diagram_type": "flowchart",
      "diagram_data": {
        "steps": [
          {"id": "start", "label": "Start Process", "type": "start"},
          {"id": "step1", "label": "Analyze Data", "type": "process"},
          {"id": "decision", "label": "Valid?", "type": "decision"},
          {"id": "end", "label": "Complete", "type": "end"}
        ],
        "connections": [
          {"from": "start", "to": "step1"},
          {"from": "step1", "to": "decision"},
          {"from": "decision", "to": "end"}
        ]
      },
      "background": "white"
    },
    {
      "type": "statistics",
      "title": "Key Statistics",
      "stats": [
        {"label": "Growth Rate", "value": "45%", "description": "Year over year increase"},
        {"label": "Market Share", "value": "23%", "description": "Current position"},
        {"label": "Customer Satisfaction", "value": "92%", "description": "User feedback score"}
      ],
      "background": "light"
    },
    {
      "type": "timeline",
      "title": "Project Timeline",
      "events": [
        {"date": "Q1 2024", "title": "Phase 1", "description": "Initial setup and planning"},
        {"date": "Q2 2024", "title": "Phase 2", "description": "Development and testing"},
        {"date": "Q3 2024", "title": "Phase 3", "description": "Launch and optimization"}
      ],
      "background": "white"
    },
    {
      "type": "process",
      "title": "Step-by-Step Process",
      "steps": [
        {"number": "1", "title": "Research", "description": "Gather requirements and analyze market"},
        {"number": "2", "title": "Design", "description": "Create wireframes and prototypes"},
        {"number": "3", "title": "Develop", "description": "Build and test the solution"},
        {"number": "4", "title": "Deploy", "description": "Launch and monitor performance"}
      ],
      "background": "gradient"
    },
    {
      "type": "quote",
      "title": "Industry Insights",
      "quote": "Innovation distinguishes between a leader and a follower.",
      "author": "Steve Jobs",
      "context": "This quote emphasizes the importance of continuous innovation in business",
      "background": "dark"
    },
    {
      "type": "pros_cons",
      "title": "Advantages & Disadvantages",
      "pros": [
        "Cost-effective solution",
        "Scalable architecture",
        "User-friendly interface"
      ],
      "cons": [
        "Initial setup complexity",
        "Learning curve required",
        "Ongoing maintenance needs"
      ],
      "background": "white"
    },
    {
      "type": "team",
      "title": "Meet the Team",
      "members": [
        {"name": "John Doe", "role": "Project Manager", "description": "10+ years experience"},
        {"name": "Jane Smith", "role": "Lead Developer", "description": "Expert in mobile development"},
        {"name": "Mike Wilson", "role": "UX Designer", "description": "Award-winning design portfolio"}
      ],
      "background": "light"
    },
         {
       "type": "agenda",
       "title": "Today's Agenda",
       "items": [
         {"time": "9:00 AM", "topic": "Welcome & Introductions"},
         {"time": "9:30 AM", "topic": "Project Overview"},
         {"time": "10:15 AM", "topic": "Technical Deep Dive"},
         {"time": "11:00 AM", "topic": "Q&A Session"}
       ],
       "background": "blue"
     },
     {
       "type": "financial",
       "title": "Financial Analysis",
       "metrics": [
         {"label": "Revenue", "value": "\$2.5M", "change": "+15%", "trend": "up"},
         {"label": "Profit Margin", "value": "23%", "change": "+3%", "trend": "up"},
         {"label": "Expenses", "value": "\$1.9M", "change": "-5%", "trend": "down"}
       ],
       "background": "light"
     },
     {
       "type": "scientific",
       "title": "Research Results",
       "hypothesis": "Increased temperature affects reaction rate",
       "methodology": "Controlled experiment with 3 temperature conditions",
       "results": [
         "25°C: 2.3 mol/L reaction rate",
         "50°C: 4.8 mol/L reaction rate", 
         "75°C: 8.1 mol/L reaction rate"
       ],
       "conclusion": "Reaction rate doubles approximately every 25°C increase",
       "background": "white"
     },
     {
       "type": "data_table",
       "title": "Performance Metrics",
       "headers": ["Quarter", "Sales", "Growth", "Target"],
       "rows": [
         ["Q1 2024", "\$1.2M", "8%", "\$1.1M"],
         ["Q2 2024", "\$1.5M", "12%", "\$1.3M"],
         ["Q3 2024", "\$1.8M", "15%", "\$1.6M"]
       ],
       "background": "light"
     },
     {
       "type": "flowchart",
       "title": "Process Flow",
       "steps": [
         {"id": "start", "text": "Start Process", "type": "start"},
         {"id": "step1", "text": "Collect Data", "type": "process"},
         {"id": "decision", "text": "Valid Data?", "type": "decision"},
         {"id": "step2", "text": "Process Data", "type": "process"},
         {"id": "end", "text": "Generate Report", "type": "end"}
       ],
       "connections": [
         {"from": "start", "to": "step1"},
         {"from": "step1", "to": "decision"},
         {"from": "decision", "to": "step2", "label": "Yes"},
         {"from": "decision", "to": "step1", "label": "No"},
         {"from": "step2", "to": "end"}
       ],
       "background": "white"
     },
    {
      "type": "conclusion",
      "title": "Key Takeaways",
      "content": [
        "• Main conclusion point 1",
        "• Main conclusion point 2", 
        "• Call to action"
      ],
      "background": "dark"
    },
    {
      "type": "matrix",
      "title": "Decision Matrix",
      "criteria": ["Cost", "Time", "Quality", "Risk"],
      "options": [
        {"name": "Option A", "scores": [8, 6, 9, 7]},
        {"name": "Option B", "scores": [6, 9, 7, 8]},
        {"name": "Option C", "scores": [9, 5, 8, 6]}
      ],
      "background": "white"
    },
    {
      "type": "hierarchy",
      "title": "Organizational Structure",
      "levels": [
        {"level": 1, "items": ["CEO"]},
        {"level": 2, "items": ["CTO", "CFO", "CMO"]},
        {"level": 3, "items": ["Dev Team", "QA Team", "Marketing Team", "Sales Team"]}
      ],
      "background": "light"
    },
    {
      "type": "roadmap",
      "title": "Product Roadmap",
      "phases": [
        {"phase": "Phase 1", "duration": "Q1 2024", "milestones": ["MVP Development", "Core Features"]},
        {"phase": "Phase 2", "duration": "Q2 2024", "milestones": ["Beta Testing", "User Feedback"]},
        {"phase": "Phase 3", "duration": "Q3 2024", "milestones": ["Public Launch", "Marketing Campaign"]}
      ],
      "background": "gradient"
    },
    {
      "type": "equation_set",
      "title": "System of Equations",
      "equations": [
        {"equation": "x + 2y = 5", "description": "Linear equation 1"},
        {"equation": "3x - y = 1", "description": "Linear equation 2"},
        {"equation": "Solution: x = 1, y = 2", "description": "System solution"}
      ],
      "method": "Substitution method",
      "background": "white"
    },
    {
      "type": "theorem",
      "title": "Pythagorean Theorem",
      "statement": "In a right triangle, the square of the hypotenuse equals the sum of squares of the other two sides",
      "formula": "a² + b² = c²",
      "proof_steps": [
        "Consider a right triangle with sides a, b, and hypotenuse c",
        "Draw a square with side (a + b)",
        "The area can be calculated in two ways",
        "This leads to the proof of a² + b² = c²"
      ],
      "applications": ["Distance calculation", "Navigation", "Engineering"],
      "background": "white"
    },
    {
      "type": "algorithm",
      "title": "Binary Search Algorithm",
      "complexity": "O(log n)",
      "steps": [
        "1. Set left = 0, right = array.length - 1",
        "2. While left <= right:",
        "3.   Calculate mid = (left + right) / 2",
        "4.   If array[mid] == target, return mid",
        "5.   If array[mid] < target, left = mid + 1",
        "6.   Else right = mid - 1",
        "7. Return -1 (not found)"
      ],
      "advantages": ["Fast search", "Logarithmic complexity"],
      "background": "dark"
    },
    {
      "type": "chemical",
      "title": "Chemical Reaction",
      "reaction": "2H₂ + O₂ → 2H₂O",
      "type_reaction": "Synthesis/Combination",
      "conditions": ["Temperature: 500°C", "Pressure: 1 atm", "Catalyst: Platinum"],
      "products": [
        {"compound": "H₂O", "name": "Water", "state": "Gas (steam)"}
      ],
      "energy_change": "Exothermic (-286 kJ/mol)",
      "background": "white"
    },
    {
      "type": "physics",
      "title": "Newton's Laws of Motion",
      "laws": [
        {"number": "First Law", "statement": "An object at rest stays at rest unless acted upon by force", "formula": "F = 0 → a = 0"},
        {"number": "Second Law", "statement": "Force equals mass times acceleration", "formula": "F = ma"},
        {"number": "Third Law", "statement": "For every action, there is an equal and opposite reaction", "formula": "F₁ = -F₂"}
      ],
      "applications": ["Vehicle design", "Spacecraft", "Sports physics"],
      "background": "light"
    },
    {
      "type": "swot",
      "title": "SWOT Analysis",
      "strengths": ["Strong brand", "Loyal customers", "Quality products"],
      "weaknesses": ["High costs", "Limited market", "Slow innovation"],
      "opportunities": ["New markets", "Digital transformation", "Partnerships"],
      "threats": ["Competition", "Economic downturn", "Regulation changes"],
      "background": "white"
    },
    {
      "type": "methodology",
      "title": "Research Methodology",
      "approach": "Mixed Methods Research",
      "phases": [
        {"phase": "Planning", "activities": ["Literature review", "Hypothesis formation"]},
        {"phase": "Data Collection", "activities": ["Surveys", "Interviews", "Observations"]},
        {"phase": "Analysis", "activities": ["Statistical analysis", "Qualitative coding"]},
        {"phase": "Reporting", "activities": ["Results interpretation", "Conclusions"]}
      ],
      "tools": ["SPSS", "NVivo", "Excel"],
      "background": "gradient"
    },
    {
      "type": "experiment",
      "title": "Laboratory Experiment",
      "objective": "Determine the effect of pH on enzyme activity",
      "materials": ["Enzyme solution", "Buffer solutions", "pH meter", "Spectrophotometer"],
      "procedure": [
        "Prepare buffer solutions at pH 4, 6, 8, 10",
        "Add enzyme to each solution",
        "Measure reaction rate using spectrophotometer",
        "Record data at 30-second intervals"
      ],
      "variables": {
        "independent": "pH level",
        "dependent": "Enzyme activity rate",
        "controlled": ["Temperature", "Enzyme concentration", "Time"]
      },
      "background": "white"
    }
  ]
}

SLIDE TYPES AVAILABLE:
- "title": Opening slide with main title and subtitle
- "content": Standard bullet points and text content
- "formula": Mathematical formulas with variable explanations
- "comparison": Side-by-side comparison (before/after, options)
- "statistics": Key numbers and metrics with descriptions
- "timeline": Chronological events or milestones
- "process": Step-by-step workflows or procedures
- "quote": Inspirational quotes with context
- "pros_cons": Advantages and disadvantages analysis
- "team": Team member introductions
- "agenda": Meeting or presentation schedule
- "financial": Financial metrics with trends and changes
- "scientific": Research results with hypothesis and methodology
- "data_table": Tabular data with headers and rows
- "flowchart": Process flowcharts with decision points
- "diagram": Interactive diagrams using DiagramService
- "conclusion": Final takeaways and next steps
- "matrix": Decision matrices with criteria and scoring
- "hierarchy": Organizational charts and hierarchical structures
- "roadmap": Project timelines with phases and milestones
- "equation_set": Systems of mathematical equations with solutions
- "theorem": Mathematical theorems with proofs and applications
- "algorithm": Computer algorithms with complexity and steps
- "chemical": Chemical reactions with equations and conditions
- "physics": Physics laws and principles with formulas
- "swot": SWOT analysis with strengths, weaknesses, opportunities, threats
- "methodology": Research methodologies with phases and tools
- "experiment": Scientific experiments with procedures and variables

Generate AS MANY SLIDES AS NEEDED to thoroughly cover the topic. For complex topics, create 10-15+ slides. For simple topics, 5-8 slides are fine. Make content detailed and professional.
Topic: $topic''',
        model: selectedModel,
      )) {
        fullResponse += chunk;
      }

      print('AI Response: $fullResponse');
      
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

      final jsonData = json.decode(cleanResponse);
      print('Parsed JSON: $jsonData');
      
      if (jsonData is Map<String, dynamic> && 
          jsonData.containsKey('title') && 
          jsonData.containsKey('slides')) {
        return jsonData;
      } else {
        throw Exception('Invalid presentation structure from AI');
      }
      
    } catch (error) {
      print('Error generating presentation data: $error');
      return null;
    }
  }

  static Widget buildPresentationWidget(Map<String, dynamic> presentationData, BuildContext context) {
    final String title = presentationData['title'] ?? 'Presentation';
    final List<dynamic> slides = presentationData['slides'] ?? [];
    final GlobalKey presentationKey = GlobalKey();

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
                    Icons.picture_as_pdf_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => savePresentationAsPDF(presentationData, context),
                  tooltip: 'Save PDF',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          // Direct presentation preview
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: RepaintBoundary(
              key: presentationKey,
              child: PageView.builder(
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildSlidePreview(slides[index], context, true),
                  );
                },
              ),
            ),
          ),
          // Slide count info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '${slides.length} slides • Swipe to preview',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSlidePreview(Map<String, dynamic> slide, BuildContext context, bool isPreview) {
    final String type = slide['type'] ?? 'content';
    final String slideTitle = slide['title'] ?? '';
    final String background = slide['background'] ?? 'white';
    
    Color backgroundColor = _getBackgroundColor(background, context);
    Color textColor = _getTextColor(background, context);
    
    double fontSize = isPreview ? 10 : 24;
    double titleSize = isPreview ? 12 : 32;
    double padding = isPreview ? 8 : 24;

    Widget content;
    
    switch (type) {
      case 'title':
        final String subtitle = slide['subtitle'] ?? '';
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slideTitle,
                style: TextStyle(
                  fontSize: titleSize * 1.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: padding),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: fontSize * 1.2,
                    color: textColor.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
        break;
        
      case 'comparison':
        final String leftTitle = slide['left_title'] ?? 'Before';
        final String rightTitle = slide['right_title'] ?? 'After';
        final List<dynamic> leftContent = slide['left_content'] ?? [];
        final List<dynamic> rightContent = slide['right_content'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leftTitle,
                            style: TextStyle(
                              fontSize: fontSize * 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          SizedBox(height: padding / 2),
                          ...leftContent.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: padding / 4),
                            child: Text(
                              item.toString(),
                              style: TextStyle(fontSize: fontSize, color: textColor),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: padding / 2),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rightTitle,
                            style: TextStyle(
                              fontSize: fontSize * 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          SizedBox(height: padding / 2),
                          ...rightContent.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: padding / 4),
                            child: Text(
                              item.toString(),
                              style: TextStyle(fontSize: fontSize, color: textColor),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
        
      case 'formula':
        final String formula = slide['formula'] ?? '';
        final String explanation = slide['explanation'] ?? '';
        final List<dynamic> variables = slide['variables'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            // Formula display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                formula,
                style: TextStyle(
                  fontSize: titleSize * 1.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontFamily: 'Courier',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: padding),
            // Explanation
            Text(
              explanation,
              style: TextStyle(
                fontSize: fontSize * 1.1,
                color: textColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: padding),
            // Variables
            if (variables.isNotEmpty) ...[
              Text(
                'Variables:',
                style: TextStyle(
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: padding / 2),
              ...variables.map((variable) => Padding(
                padding: EdgeInsets.only(bottom: padding / 4),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          variable['symbol'] ?? '',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      '= ${variable['meaning'] ?? ''}',
                      style: TextStyle(fontSize: fontSize, color: textColor),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        );
        break;
        
      case 'statistics':
        final List<dynamic> stats = slide['stats'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: GridView.count(
                crossAxisCount: isPreview ? 1 : 2,
                childAspectRatio: isPreview ? 4 : 2,
                children: stats.map((stat) => Container(
                  margin: EdgeInsets.all(padding / 4),
                  padding: EdgeInsets.all(padding / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat['value'] ?? '0',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        stat['label'] ?? '',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (!isPreview) ...[
                        SizedBox(height: padding / 4),
                        Text(
                          stat['description'] ?? '',
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: textColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        );
        break;
        
      case 'timeline':
        final List<dynamic> events = slide['events'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: padding / 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: isPreview ? 40 : 80,
                          child: Text(
                            event['date'] ?? '',
                            style: TextStyle(
                              fontSize: fontSize * 0.9,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        Container(
                          width: 3,
                          height: isPreview ? 30 : 40,
                          color: Colors.blue.shade300,
                          margin: EdgeInsets.symmetric(horizontal: padding / 2),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'] ?? '',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                event['description'] ?? '',
                                style: TextStyle(
                                  fontSize: fontSize * 0.9,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
        break;
        
      case 'process':
        final List<dynamic> steps = slide['steps'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: padding / 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: isPreview ? 12 : 20,
                          backgroundColor: Colors.green.shade600,
                          child: Text(
                            step['number'] ?? '${index + 1}',
                            style: TextStyle(
                              fontSize: fontSize * 0.9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: padding / 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title'] ?? '',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                step['description'] ?? '',
                                style: TextStyle(
                                  fontSize: fontSize * 0.9,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
        break;
        
      case 'quote':
        final String quote = slide['quote'] ?? '';
        final String author = slide['author'] ?? '';
        final String quoteContext = slide['context'] ?? '';
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slideTitle,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: padding * 2),
              Icon(
                Icons.format_quote,
                size: isPreview ? 30 : 60,
                color: textColor.withOpacity(0.3),
              ),
              SizedBox(height: padding),
              Text(
                '"$quote"',
                style: TextStyle(
                  fontSize: titleSize * 0.8,
                  fontStyle: FontStyle.italic,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: padding),
              Text(
                '- $author',
                style: TextStyle(
                  fontSize: fontSize * 1.2,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (!isPreview && quoteContext.isNotEmpty) ...[
                SizedBox(height: padding),
                Text(
                  quoteContext,
                  style: TextStyle(
                    fontSize: fontSize * 0.9,
                    color: textColor.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
        break;
        
      case 'pros_cons':
        final List<dynamic> pros = slide['pros'] ?? [];
        final List<dynamic> cons = slide['cons'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade700, size: fontSize * 1.5),
                              SizedBox(width: padding / 4),
                              Text(
                                'Pros',
                                style: TextStyle(
                                  fontSize: fontSize * 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: padding / 2),
                          ...pros.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: padding / 4),
                            child: Text(
                              '• $item',
                              style: TextStyle(fontSize: fontSize, color: textColor),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: padding / 2),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red.shade700, size: fontSize * 1.5),
                              SizedBox(width: padding / 4),
                              Text(
                                'Cons',
                                style: TextStyle(
                                  fontSize: fontSize * 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: padding / 2),
                          ...cons.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: padding / 4),
                            child: Text(
                              '• $item',
                              style: TextStyle(fontSize: fontSize, color: textColor),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        break;
        
      case 'team':
        final List<dynamic> members = slide['members'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: GridView.count(
                crossAxisCount: isPreview ? 1 : 2,
                childAspectRatio: isPreview ? 4 : 1.5,
                children: members.map((member) => Container(
                  margin: EdgeInsets.all(padding / 4),
                  padding: EdgeInsets.all(padding / 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isPreview ? 15 : 25,
                        backgroundColor: Colors.blue.shade600,
                        child: Text(
                          (member['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: padding / 4),
                      Text(
                        member['name'] ?? '',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        member['role'] ?? '',
                        style: TextStyle(
                          fontSize: fontSize * 0.9,
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isPreview) ...[
                        SizedBox(height: padding / 4),
                        Text(
                          member['description'] ?? '',
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: textColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        );
        break;
        
      case 'agenda':
        final List<dynamic> items = slide['items'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: padding / 2),
                    padding: EdgeInsets.all(padding / 2),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.grey.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: isPreview ? 50 : 80,
                          child: Text(
                            item['time'] ?? '',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: padding / 2),
                        Expanded(
                          child: Text(
                            item['topic'] ?? '',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
        break;
        
      case 'financial':
        final List<dynamic> metrics = slide['metrics'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: GridView.count(
                crossAxisCount: isPreview ? 1 : 2,
                childAspectRatio: isPreview ? 4 : 2,
                children: metrics.map((metric) {
                  final trend = metric['trend'] ?? 'neutral';
                  final trendColor = trend == 'up' ? Colors.green : trend == 'down' ? Colors.red : Colors.grey;
                  final trendIcon = trend == 'up' ? Icons.trending_up : trend == 'down' ? Icons.trending_down : Icons.trending_flat;
                  
                  return Container(
                    margin: EdgeInsets.all(padding / 4),
                    padding: EdgeInsets.all(padding / 2),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: trendColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              metric['value'] ?? '0',
                              style: TextStyle(
                                fontSize: titleSize * 0.8,
                                fontWeight: FontWeight.bold,
                                color: trendColor,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(trendIcon, color: trendColor, size: fontSize * 1.2),
                          ],
                        ),
                        Text(
                          metric['label'] ?? '',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          metric['change'] ?? '',
                          style: TextStyle(
                            fontSize: fontSize * 0.9,
                            color: trendColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
        break;
        
      case 'scientific':
        final String hypothesis = slide['hypothesis'] ?? '';
        final String methodology = slide['methodology'] ?? '';
        final List<dynamic> results = slide['results'] ?? [];
        final String conclusion = slide['conclusion'] ?? '';
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScienceSection('Hypothesis:', hypothesis, Colors.blue, fontSize, textColor, padding),
                    _buildScienceSection('Methodology:', methodology, Colors.orange, fontSize, textColor, padding),
                    if (results.isNotEmpty) ...[
                      Text(
                        'Results:',
                        style: TextStyle(
                          fontSize: fontSize * 1.1,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(height: padding / 4),
                      ...results.map((result) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 4, left: padding / 2),
                        child: Text(
                          '• $result',
                          style: TextStyle(fontSize: fontSize * 0.9, color: textColor),
                        ),
                      )).toList(),
                      SizedBox(height: padding / 2),
                    ],
                    _buildScienceSection('Conclusion:', conclusion, Colors.purple, fontSize, textColor, padding),
                  ],
                ),
              ),
            ),
          ],
        );
        break;
        
      case 'data_table':
        final List<dynamic> headers = slide['headers'] ?? [];
        final List<dynamic> rows = slide['rows'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.blue.withOpacity(0.1)),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: headers.map((header) => DataColumn(
                      label: Text(
                        header.toString(),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )).toList(),
                    rows: rows.map((row) => DataRow(
                      cells: (row as List).map((cell) => DataCell(
                        Text(
                          cell.toString(),
                          style: TextStyle(fontSize: fontSize * 0.9, color: textColor),
                        ),
                      )).toList(),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
        break;
        
      case 'diagram':
        final String diagramType = slide['diagram_type'] ?? 'flowchart';
        final Map<String, dynamic> diagramData = slide['diagram_data'] ?? {};
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(padding / 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DiagramService.buildChart(diagramType, diagramData, context),
              ),
            ),
          ],
        );
        break;
        
      case 'flowchart':
        final List<dynamic> steps = slide['steps'] ?? [];
        final List<dynamic> connections = slide['connections'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: padding,
                  runSpacing: padding,
                  children: steps.map((step) {
                    final stepType = step['type'] ?? 'process';
                    Color stepColor = Colors.blue;
                    IconData stepIcon = Icons.circle;
                    
                    switch (stepType) {
                      case 'start':
                        stepColor = Colors.green;
                        stepIcon = Icons.play_circle;
                        break;
                      case 'end':
                        stepColor = Colors.red;
                        stepIcon = Icons.stop_circle;
                        break;
                      case 'decision':
                        stepColor = Colors.orange;
                        stepIcon = Icons.help_outline;
                        break;
                      default:
                        stepColor = Colors.blue;
                        stepIcon = Icons.circle;
                    }
                    
                    return Container(
                      width: isPreview ? 80 : 120,
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        color: stepColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: stepColor),
                      ),
                      child: Column(
                        children: [
                          Icon(stepIcon, color: stepColor, size: fontSize * 1.5),
                          SizedBox(height: padding / 4),
                          Text(
                            step['text'] ?? '',
                            style: TextStyle(
                              fontSize: fontSize * 0.8,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
        break;
        
      case 'matrix':
        final List<dynamic> criteria = slide['criteria'] ?? [];
        final List<dynamic> options = slide['options'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            if (criteria.isNotEmpty && options.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: textColor.withOpacity(0.3)),
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(padding / 2),
                            child: Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: textColor)),
                          ),
                          ...criteria.map((criterion) => Padding(
                            padding: EdgeInsets.all(padding / 2),
                            child: Text(criterion.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize * 0.9, color: textColor)),
                          )).toList(),
                        ],
                      ),
                      ...options.map((option) {
                        final scores = option['scores'] as List<dynamic>? ?? [];
                        return TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(padding / 2),
                              child: Text(option['name']?.toString() ?? '', style: TextStyle(fontSize: fontSize, color: textColor)),
                            ),
                            ...scores.map((score) => Padding(
                              padding: EdgeInsets.all(padding / 2),
                              child: Text(score.toString(), style: TextStyle(fontSize: fontSize, color: textColor)),
                            )).toList(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        );
        break;

      case 'hierarchy':
        final List<dynamic> levels = slide['levels'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: levels.map((level) {
                    final items = level['items'] as List<dynamic>? ?? [];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: padding / 2),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: textColor),
                            ),
                            child: Center(
                              child: Text(
                                level['level'].toString(),
                                style: TextStyle(fontSize: fontSize * 0.8, fontWeight: FontWeight.bold, color: textColor),
                              ),
                            ),
                          ),
                          SizedBox(width: padding),
                          Expanded(
                            child: Wrap(
                              spacing: padding / 2,
                              children: items.map((item) => Chip(
                                label: Text(item.toString(), style: TextStyle(fontSize: fontSize * 0.8, color: textColor)),
                                backgroundColor: backgroundColor.withOpacity(0.1),
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
        break;

      case 'equation_set':
        final List<dynamic> equations = slide['equations'] ?? [];
        final String method = slide['method']?.toString() ?? '';
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            if (method.isNotEmpty)
              Container(
                padding: EdgeInsets.all(padding / 2),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Method: $method',
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: equations.map((eq) => Container(
                    margin: EdgeInsets.only(bottom: padding),
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: textColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eq['equation']?.toString() ?? '',
                          style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'monospace'),
                        ),
                        if (eq['description'] != null)
                          Padding(
                            padding: EdgeInsets.only(top: padding / 2),
                            child: Text(
                              eq['description'].toString(),
                              style: TextStyle(fontSize: fontSize * 0.9, color: textColor.withOpacity(0.8)),
                            ),
                          ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        );
        break;

      case 'theorem':
        final String statement = slide['statement']?.toString() ?? '';
        final String formula = slide['formula']?.toString() ?? '';
        final List<dynamic> proofSteps = slide['proof_steps'] ?? [];
        final List<dynamic> applications = slide['applications'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            if (statement.isNotEmpty)
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statement,
                  style: TextStyle(fontSize: fontSize, fontStyle: FontStyle.italic, color: textColor),
                ),
              ),
            if (formula.isNotEmpty) ...[
              SizedBox(height: padding),
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formula,
                  style: TextStyle(fontSize: fontSize * 1.3, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'monospace'),
                ),
              ),
            ],
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (proofSteps.isNotEmpty) ...[
                      Text(
                        'Proof Steps:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...proofSteps.map((step) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${step.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                    if (applications.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Applications:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...applications.map((app) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${app.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 'algorithm':
        final String complexity = slide['complexity']?.toString() ?? '';
        final List<dynamic> steps = slide['steps'] ?? [];
        final List<dynamic> advantages = slide['advantages'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (complexity.isNotEmpty) ...[
              SizedBox(height: padding / 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Complexity: $complexity',
                  style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.w500, color: textColor),
                ),
              ),
            ],
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (steps.isNotEmpty) ...[
                      Text(
                        'Algorithm Steps:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      Container(
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: steps.map((step) => Padding(
                            padding: EdgeInsets.only(bottom: padding / 3),
                            child: Text(step.toString(), style: TextStyle(fontSize: fontSize * 0.9, color: textColor, fontFamily: 'monospace')),
                          )).toList(),
                        ),
                      ),
                    ],
                    if (advantages.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Advantages:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...advantages.map((adv) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${adv.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 'chemical':
        final String reaction = slide['reaction']?.toString() ?? '';
        final String reactionType = slide['type_reaction']?.toString() ?? '';
        final List<dynamic> conditions = slide['conditions'] ?? [];
        final String energyChange = slide['energy_change']?.toString() ?? '';
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            if (reaction.isNotEmpty)
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reaction,
                  style: TextStyle(fontSize: fontSize * 1.3, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'monospace'),
                ),
              ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reactionType.isNotEmpty)
                      _buildScienceSection('Reaction Type:', reactionType, Colors.green, fontSize, textColor, padding),
                    if (conditions.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Reaction Conditions:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...conditions.map((condition) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${condition.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                    if (energyChange.isNotEmpty) ...[
                      SizedBox(height: padding),
                      _buildScienceSection('Energy Change:', energyChange, Colors.red, fontSize, textColor, padding),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 'physics':
        final List<dynamic> laws = slide['laws'] ?? [];
        final List<dynamic> applications = slide['applications'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...laws.map((law) => Container(
                      margin: EdgeInsets.only(bottom: padding),
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: textColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            law['number']?.toString() ?? '',
                            style: TextStyle(fontSize: fontSize * 1.1, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          SizedBox(height: padding / 2),
                          Text(
                            law['statement']?.toString() ?? '',
                            style: TextStyle(fontSize: fontSize, color: textColor),
                          ),
                          if (law['formula'] != null) ...[
                            SizedBox(height: padding / 2),
                            Container(
                              padding: EdgeInsets.all(padding / 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                law['formula'].toString(),
                                style: TextStyle(fontSize: fontSize * 1.1, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )).toList(),
                    if (applications.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Applications:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...applications.map((app) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${app.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 'swot':
        final List<dynamic> strengths = slide['strengths'] ?? [];
        final List<dynamic> weaknesses = slide['weaknesses'] ?? [];
        final List<dynamic> opportunities = slide['opportunities'] ?? [];
        final List<dynamic> threats = slide['threats'] ?? [];
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: padding,
                mainAxisSpacing: padding,
                children: [
                  _buildSWOTQuadrant('Strengths', strengths, Colors.green, fontSize, textColor, padding),
                  _buildSWOTQuadrant('Weaknesses', weaknesses, Colors.red, fontSize, textColor, padding),
                  _buildSWOTQuadrant('Opportunities', opportunities, Colors.blue, fontSize, textColor, padding),
                  _buildSWOTQuadrant('Threats', threats, Colors.orange, fontSize, textColor, padding),
                ],
              ),
            ),
          ],
        );
        break;

      case 'experiment':
        final String objective = slide['objective']?.toString() ?? '';
        final List<dynamic> materials = slide['materials'] ?? [];
        final List<dynamic> procedure = slide['procedure'] ?? [];
        final Map<String, dynamic> variables = slide['variables'] as Map<String, dynamic>? ?? {};
        
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (objective.isNotEmpty)
                      _buildScienceSection('Objective:', objective, Colors.blue, fontSize, textColor, padding),
                    if (materials.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Materials:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...materials.map((material) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('• ${material.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                    if (procedure.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Procedure:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...procedure.asMap().entries.map((entry) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('${entry.key + 1}. ${entry.value.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                    if (variables.isNotEmpty) ...[
                      SizedBox(height: padding),
                      Text(
                        'Variables:',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      SizedBox(height: padding / 2),
                      ...variables.entries.map((entry) => Padding(
                        padding: EdgeInsets.only(bottom: padding / 2),
                        child: Text('${entry.key}: ${entry.value.toString()}', style: TextStyle(fontSize: fontSize * 0.9, color: textColor)),
                      )).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
        break;
        
      default: // content and conclusion
        final List<dynamic> contentList = slide['content'] ?? [];
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slideTitle,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            SizedBox(height: padding),
            ...contentList.map((item) => Padding(
              padding: EdgeInsets.only(bottom: padding / 2),
              child: Text(
                item.toString(),
                style: TextStyle(fontSize: fontSize, color: textColor),
              ),
            )).toList(),
          ],
        );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(padding),
      child: content,
    );
  }

  static Widget _buildSWOTQuadrant(String title, List<dynamic> items, Color color, double fontSize, Color textColor, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: padding / 2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) => Padding(
                  padding: EdgeInsets.only(bottom: padding / 3),
                  child: Text(
                    '• ${item.toString()}',
                    style: TextStyle(fontSize: fontSize * 0.8, color: textColor),
                  ),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildScienceSection(String title, String content, Color color, double fontSize, Color textColor, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize * 1.1,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: padding / 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding / 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: fontSize * 0.9, color: textColor),
          ),
        ),
        SizedBox(height: padding / 2),
      ],
    );
  }

  static Color _getBackgroundColor(String background, BuildContext context) {
    switch (background) {
      case 'blue': return Colors.blue.shade600;
      case 'dark': return Colors.grey.shade800;
      case 'light': return Colors.grey.shade100;
      case 'gradient': return Colors.purple.shade400;
      default: return Theme.of(context).cardColor;
    }
  }

  static Color _getTextColor(String background, BuildContext context) {
    switch (background) {
      case 'blue':
      case 'dark':
      case 'gradient':
        return Colors.white;
      case 'light':
      case 'white':
        return Colors.black87;
      default:
        return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    }
  }

  static Future<void> savePresentationAsPDF(Map<String, dynamic> presentationData, BuildContext context) async {
    PdfDocument? document;
    try {
      print('🔄 Starting ROBUST PDF generation...');
      DiagramService.showStyledSnackBar(context, 'Creating PDF presentation...');

      final String title = presentationData['title'] ?? 'Presentation';
      final List<dynamic> slides = presentationData['slides'] ?? [];
      print('Title: $title, Slides count: ${slides.length}');

      if (slides.isEmpty) {
        throw Exception('No slides to generate PDF');
      }

      // Create PDF document
      document = PdfDocument();
      print('PDF document created');
      
      int successfulSlides = 0;
      List<String> failedSlides = [];
      
      // Process each slide with individual error handling
      for (int i = 0; i < slides.length; i++) {
        try {
          print('Processing slide ${i + 1}/${slides.length}');
          final slide = slides[i];
          final PdfPage page = document.pages.add();
          final PdfGraphics graphics = page.graphics;
          final Size pageSize = page.getClientSize();
          
          // Clean all text content in the slide before processing
          final Map<String, dynamic> cleanedSlide = _cleanSlideForPDF(slide);
          
          // Draw slide content with cleaned data
          await _drawSlideOnPDF(graphics, cleanedSlide, pageSize, context);
          successfulSlides++;
          print('✅ Slide ${i + 1} processed successfully');
          
        } catch (slideError) {
          print('⚠️ Error in slide ${i + 1}: $slideError');
          failedSlides.add('Slide ${i + 1}: ${slideError.toString()}');
          
          // Add an error page instead of failing completely
          try {
            final errorPage = document.pages.add();
            final errorGraphics = errorPage.graphics;
            
            // Draw background
            errorGraphics.drawRectangle(
              brush: PdfSolidBrush(PdfColor(255, 250, 250)),
              bounds: Rect.fromLTWH(0, 0, 595, 842),
            );
            
            // Draw error header
            errorGraphics.drawString(
              'Slide ${i + 1} - Processing Error',
              PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
              brush: PdfSolidBrush(PdfColor(220, 20, 60)),
              bounds: Rect.fromLTWH(40, 50, 515, 30),
            );
            
            // Draw error message
            final cleanErrorMessage = _cleanTextForPDF('Content contained unsupported characters (error 8289 and others). Please regenerate with simpler text.');
            errorGraphics.drawString(
              cleanErrorMessage,
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              brush: PdfSolidBrush(PdfColor(100, 100, 100)),
              bounds: Rect.fromLTWH(40, 100, 515, 200),
              format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top),
            );
            
            successfulSlides++;
            print('📄 Error page created for slide ${i + 1}');
            
          } catch (errorPageError) {
            print('❌ Could not create error page for slide ${i + 1}: $errorPageError');
            // Continue with next slide
          }
        }
      }

      // Save PDF regardless of some slides failing
      print('💾 Generating PDF bytes...');
      final List<int> bytes = await document.save();
      document.dispose();
      document = null; // Mark as disposed
      print('PDF bytes generated: ${bytes.length} bytes');

      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_presentation_${DateTime.now().millisecondsSinceEpoch}.pdf';
      print('Saving to file: $fileName');
      
      final success = await _savePDFToAhamAIFolder(Uint8List.fromList(bytes), fileName);
      
      if (success) {
        String message;
        Color backgroundColor;
        
        if (failedSlides.isEmpty) {
          message = 'PDF saved successfully: $fileName';
          backgroundColor = Colors.green.shade600;
          print('✅ All slides processed successfully!');
        } else {
          message = 'PDF saved with $successfulSlides/${slides.length} slides (${failedSlides.length} had character issues)';
          backgroundColor = Colors.orange.shade600;
          print('⚠️ PDF saved with some issues: ${failedSlides.join(", ")}');
        }
        
        DiagramService.showStyledSnackBar(
          context, 
          message,
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
        );
      } else {
        throw Exception('Failed to save PDF file to storage');
      }
      
    } catch (error) {
      print('❌ Critical error in PDF generation: $error');
      
      // Ensure document cleanup
      try {
        document?.dispose();
      } catch (disposeError) {
        print('⚠️ Error disposing PDF document: $disposeError');
      }
      
      // Create emergency fallback PDF
      try {
        print('🔧 Creating emergency fallback PDF...');
        final fallbackDocument = PdfDocument();
        final fallbackPage = fallbackDocument.pages.add();
        final fallbackGraphics = fallbackPage.graphics;
        
        // White background
        fallbackGraphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(255, 255, 255)),
          bounds: Rect.fromLTWH(0, 0, 595, 842),
        );
        
        // Title
        fallbackGraphics.drawString(
          'AhamAI Presentation - Error Recovery',
          PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(40, 50, 515, 30),
        );
        
        // Error details
        final cleanErrorDetails = _cleanTextForPDF('PDF generation encountered character encoding errors (8289, 8345, etc.). The presentation content contained special Unicode characters that are not supported by the PDF font system.');
        fallbackGraphics.drawString(
          cleanErrorDetails,
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(PdfColor(100, 100, 100)),
          bounds: Rect.fromLTWH(40, 100, 515, 200),
          format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top),
        );
        
        // Instructions
        fallbackGraphics.drawString(
          'To fix this: Ask the AI to regenerate the presentation with simpler text content without special mathematical symbols or Unicode characters.',
          PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 100, 0)),
          bounds: Rect.fromLTWH(40, 350, 515, 100),
          format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top),
        );
        
        final fallbackBytes = await fallbackDocument.save();
        fallbackDocument.dispose();
        
        final fallbackFileName = 'AhamAI_ERROR_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final fallbackSaved = await _savePDFToAhamAIFolder(Uint8List.fromList(fallbackBytes), fallbackFileName);
        
        if (fallbackSaved) {
          DiagramService.showStyledSnackBar(
            context, 
            'Error PDF saved: $fallbackFileName - Check content and regenerate',
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 5),
          );
        } else {
          throw Exception('Complete PDF system failure');
        }
        
      } catch (fallbackError) {
        print('❌ Emergency fallback also failed: $fallbackError');
        DiagramService.showStyledSnackBar(
          context, 
          'PDF generation completely failed - Character error 8289. Please regenerate presentation with simple text only.',
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        );
      }
    }
  }
  
  // Clean slide data to remove problematic characters before PDF processing
  static Map<String, dynamic> _cleanSlideForPDF(Map<String, dynamic> slide) {
    final Map<String, dynamic> cleaned = {};
    
    slide.forEach((key, value) {
      if (value is String) {
        cleaned[key] = _cleanTextForPDF(value);
      } else if (value is List) {
        cleaned[key] = value.map((item) {
          if (item is String) {
            return _cleanTextForPDF(item);
          } else if (item is Map<String, dynamic>) {
            return _cleanSlideForPDF(item);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        cleaned[key] = _cleanSlideForPDF(value);
      } else {
        cleaned[key] = value;
      }
    });
    
    return cleaned;
  }

  static Future<void> _drawSlideOnPDF(PdfGraphics graphics, Map<String, dynamic> slide, Size pageSize, BuildContext context) async {
    final String type = slide['type'] ?? 'content';
    final String slideTitle = slide['title'] ?? '';
    final String background = slide['background'] ?? 'white';
    
    // Background
    Color backgroundColor = _getBackgroundColor(background, context);
    graphics.drawRectangle(
      pen: PdfPen(PdfColor.fromCMYK(0, 0, 0, 0)),
      brush: PdfSolidBrush(PdfColor(
        backgroundColor.red,
        backgroundColor.green,
        backgroundColor.blue,
      )),
      bounds: Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );

    // Text color
    Color textColor = _getTextColor(background, context);
    PdfColor pdfTextColor = PdfColor(textColor.red, textColor.green, textColor.blue);

    double yPosition = 60;
    
    // Title (with font fallback for special characters)
    if (slideTitle.isNotEmpty) {
      final cleanTitle = _cleanTextForPDF(slideTitle);
      graphics.drawString(
        cleanTitle,
        PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(pdfTextColor),
        bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
      );
      yPosition += 60;
    }

    // Content based on type
    switch (type) {
      case 'title':
        final String subtitle = slide['subtitle'] ?? '';
        if (subtitle.isNotEmpty) {
          graphics.drawString(
            subtitle,
            PdfStandardFont(PdfFontFamily.helvetica, 16),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition + 20, pageSize.width - 80, 200),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
        break;
        
      case 'comparison':
        final String leftTitle = slide['left_title'] ?? 'Before';
        final String rightTitle = slide['right_title'] ?? 'After';
        final List<dynamic> leftContent = slide['left_content'] ?? [];
        final List<dynamic> rightContent = slide['right_content'] ?? [];
        
        // Left column
        graphics.drawString(
          leftTitle,
          PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(200, 0, 0)),
          bounds: Rect.fromLTWH(40, yPosition, (pageSize.width / 2) - 60, 30),
        );
        
        double leftY = yPosition + 40;
        for (final item in leftContent) {
          graphics.drawString(
            item.toString(),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, leftY, (pageSize.width / 2) - 60, 20),
          );
          leftY += 25;
        }
        
        // Right column
        graphics.drawString(
          rightTitle,
          PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 150, 0)),
          bounds: Rect.fromLTWH((pageSize.width / 2) + 20, yPosition, (pageSize.width / 2) - 60, 30),
        );
        
        double rightY = yPosition + 40;
        for (final item in rightContent) {
          graphics.drawString(
            item.toString(),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH((pageSize.width / 2) + 20, rightY, (pageSize.width / 2) - 60, 20),
          );
          rightY += 25;
        }
        break;
        
      case 'statistics':
        final List<dynamic> stats = slide['stats'] ?? [];
        int columnCount = 0;
        for (final stat in stats) {
          double xPos = 40 + (columnCount % 2) * (pageSize.width / 2);
          double yPos = yPosition + (columnCount ~/ 2) * 120;
          
          // Value
          graphics.drawString(
            stat['value'] ?? '0',
            PdfStandardFont(PdfFontFamily.helvetica, 32, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
            bounds: Rect.fromLTWH(xPos, yPos, (pageSize.width / 2) - 60, 40),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Label
          graphics.drawString(
            stat['label'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(xPos, yPos + 40, (pageSize.width / 2) - 60, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Description
          graphics.drawString(
            stat['description'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 10),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(xPos, yPos + 65, (pageSize.width / 2) - 60, 30),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          columnCount++;
        }
        break;
        
      case 'timeline':
        final List<dynamic> events = slide['events'] ?? [];
        for (int i = 0; i < events.length; i++) {
          final event = events[i];
          double eventY = yPosition + (i * 60);
          
          // Date
          graphics.drawString(
            event['date'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
            bounds: Rect.fromLTWH(40, eventY, 100, 20),
          );
          
          // Timeline line
          graphics.drawLine(
            PdfPen(PdfColor(0, 100, 200), width: 3),
            Offset(150, eventY + 10),
            Offset(170, eventY + 10),
          );
          
          // Title and description
          graphics.drawString(
            event['title'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(180, eventY, pageSize.width - 220, 20),
          );
          
          graphics.drawString(
            event['description'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(180, eventY + 25, pageSize.width - 220, 30),
          );
        }
        break;
        
      case 'process':
        final List<dynamic> steps = slide['steps'] ?? [];
        for (int i = 0; i < steps.length; i++) {
          final step = steps[i];
          double stepY = yPosition + (i * 80);
          
          // Step number circle
          graphics.drawEllipse(
            Rect.fromLTWH(40, stepY, 30, 30),
            pen: PdfPen(PdfColor(0, 150, 0)),
            brush: PdfSolidBrush(PdfColor(0, 150, 0)),
          );
          
          // Step number
          graphics.drawString(
            step['number'] ?? '${i + 1}',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: Rect.fromLTWH(40, stepY + 8, 30, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Step content
          graphics.drawString(
            step['title'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(85, stepY, pageSize.width - 125, 20),
          );
          
          graphics.drawString(
            step['description'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(85, stepY + 25, pageSize.width - 125, 40),
          );
        }
        break;
        
      case 'quote':
        final String quote = slide['quote'] ?? '';
        final String author = slide['author'] ?? '';
        final String quoteContext = slide['context'] ?? '';
        
        // Quote marks
        graphics.drawString(
          '"',
          PdfStandardFont(PdfFontFamily.helvetica, 48),
          brush: PdfSolidBrush(PdfColor(
            (pdfTextColor.r * 0.5).round(),
            (pdfTextColor.g * 0.5).round(), 
            (pdfTextColor.b * 0.5).round(),
          )),
          bounds: Rect.fromLTWH(40, yPosition, 40, 60),
        );
        
        // Quote text
        graphics.drawString(
          '"$quote"',
          PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.italic),
          brush: PdfSolidBrush(pdfTextColor),
          bounds: Rect.fromLTWH(40, yPosition + 80, pageSize.width - 80, 150),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        
        // Author
        graphics.drawString(
          '- $author',
          PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(pdfTextColor),
          bounds: Rect.fromLTWH(40, yPosition + 250, pageSize.width - 80, 30),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        
        // Context
        if (quoteContext.isNotEmpty) {
          graphics.drawString(
            quoteContext,
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition + 290, pageSize.width - 80, 60),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
        }
        break;
        
      case 'pros_cons':
        final List<dynamic> pros = slide['pros'] ?? [];
        final List<dynamic> cons = slide['cons'] ?? [];
        
        // Pros header
        graphics.drawString(
          'Pros',
          PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 150, 0)),
          bounds: Rect.fromLTWH(40, yPosition, (pageSize.width / 2) - 60, 25),
        );
        
        // Cons header
        graphics.drawString(
          'Cons',
          PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(200, 0, 0)),
          bounds: Rect.fromLTWH((pageSize.width / 2) + 20, yPosition, (pageSize.width / 2) - 60, 25),
        );
        
        // Pros content
        double prosY = yPosition + 35;
        for (final pro in pros) {
          graphics.drawString(
            '• $pro',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, prosY, (pageSize.width / 2) - 60, 25),
          );
          prosY += 30;
        }
        
        // Cons content
        double consY = yPosition + 35;
        for (final con in cons) {
          graphics.drawString(
            '• $con',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH((pageSize.width / 2) + 20, consY, (pageSize.width / 2) - 60, 25),
          );
          consY += 30;
        }
        break;
        
      case 'team':
        final List<dynamic> members = slide['members'] ?? [];
        int memberCount = 0;
        for (final member in members) {
          double xPos = 40 + (memberCount % 2) * (pageSize.width / 2);
          double yPos = yPosition + (memberCount ~/ 2) * 120;
          
          // Member circle (placeholder for photo)
          graphics.drawEllipse(
            Rect.fromLTWH(xPos + 60, yPos, 50, 50),
            pen: PdfPen(PdfColor(0, 100, 200)),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
          );
          
          // Initial
          graphics.drawString(
            (member['name'] ?? 'U')[0].toUpperCase(),
            PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(255, 255, 255)),
            bounds: Rect.fromLTWH(xPos + 60, yPos + 12, 50, 30),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Name and role
          graphics.drawString(
            member['name'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(xPos, yPos + 60, (pageSize.width / 2) - 60, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          graphics.drawString(
            member['role'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
            bounds: Rect.fromLTWH(xPos, yPos + 85, (pageSize.width / 2) - 60, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          memberCount++;
        }
        break;
        
      case 'agenda':
        final List<dynamic> items = slide['items'] ?? [];
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          double itemY = yPosition + (i * 40);
          
          // Time
          graphics.drawString(
            item['time'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
            bounds: Rect.fromLTWH(40, itemY, 100, 20),
          );
          
          // Topic
          graphics.drawString(
            item['topic'] ?? '',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(160, itemY, pageSize.width - 200, 20),
          );
        }
        break;
        
      case 'formula':
        final String formula = slide['formula'] ?? '';
        final String explanation = slide['explanation'] ?? '';
        final List<dynamic> variables = slide['variables'] ?? [];
        
        // Formula box
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(0, 100, 200)),
          brush: PdfSolidBrush(PdfColor(230, 240, 255)),
          bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 80),
        );
        
        // Formula text
        graphics.drawString(
          _cleanTextForPDF(formula),
          PdfStandardFont(PdfFontFamily.courier, 20, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 100, 200)),
          bounds: Rect.fromLTWH(40, yPosition + 20, pageSize.width - 80, 40),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        
        yPosition += 100;
        
        // Explanation
        if (explanation.isNotEmpty) {
          graphics.drawString(
            _cleanTextForPDF(explanation),
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.italic),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 30),
          );
          yPosition += 40;
        }
        
        // Variables
        for (final variable in variables) {
          final symbol = variable['symbol'] ?? '';
          final meaning = variable['meaning'] ?? '';
          graphics.drawString(
            '$symbol = ${_cleanTextForPDF(meaning)}',
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20),
          );
          yPosition += 25;
        }
        break;
        
      case 'financial':
        final List<dynamic> metrics = slide['metrics'] ?? [];
        int columnCount = 0;
        for (final metric in metrics) {
          double xPos = 40 + (columnCount % 2) * (pageSize.width / 2);
          double yPos = yPosition + (columnCount ~/ 2) * 120;
          
          final trend = metric['trend'] ?? 'neutral';
          final trendSymbol = trend == 'up' ? '↑' : trend == 'down' ? '↓' : '→';
          
          // Metric box
          final boxColor = trend == 'up' ? PdfColor(0, 150, 0) : trend == 'down' ? PdfColor(200, 0, 0) : PdfColor(100, 100, 100);
          final lightBoxColor = trend == 'up' ? PdfColor(200, 255, 200) : trend == 'down' ? PdfColor(255, 200, 200) : PdfColor(230, 230, 230);
          graphics.drawRectangle(
            pen: PdfPen(boxColor),
            brush: PdfSolidBrush(lightBoxColor),
            bounds: Rect.fromLTWH(xPos, yPos, (pageSize.width / 2) - 60, 100),
          );
          
          // Value with trend
          graphics.drawString(
            '${_cleanTextForPDF(metric['value'] ?? '0')} $trendSymbol',
            PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(boxColor),
            bounds: Rect.fromLTWH(xPos + 10, yPos + 10, (pageSize.width / 2) - 80, 30),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Label
          graphics.drawString(
            _cleanTextForPDF(metric['label'] ?? ''),
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(xPos + 10, yPos + 45, (pageSize.width / 2) - 80, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          // Change
          graphics.drawString(
            _cleanTextForPDF(metric['change'] ?? ''),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(boxColor),
            bounds: Rect.fromLTWH(xPos + 10, yPos + 70, (pageSize.width / 2) - 80, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          columnCount++;
        }
        break;
        
      case 'scientific':
        final String hypothesis = slide['hypothesis'] ?? '';
        final String methodology = slide['methodology'] ?? '';
        final List<dynamic> results = slide['results'] ?? [];
        final String conclusion = slide['conclusion'] ?? '';
        
        // Hypothesis
        if (hypothesis.isNotEmpty) {
          graphics.drawString(
            'Hypothesis:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(0, 100, 200)),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 20),
          );
          yPosition += 25;
          
          graphics.drawString(
            _cleanTextForPDF(hypothesis),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
          );
          yPosition += 50;
        }
        
        // Methodology
        if (methodology.isNotEmpty) {
          graphics.drawString(
            'Methodology:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(200, 100, 0)),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 20),
          );
          yPosition += 25;
          
          graphics.drawString(
            _cleanTextForPDF(methodology),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
          );
          yPosition += 50;
        }
        
        // Results
        if (results.isNotEmpty) {
          graphics.drawString(
            'Results:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(0, 150, 0)),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 20),
          );
          yPosition += 25;
          
          for (final result in results) {
            graphics.drawString(
              '• ${_cleanTextForPDF(result.toString())}',
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              brush: PdfSolidBrush(pdfTextColor),
              bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 20),
            );
            yPosition += 25;
          }
          yPosition += 10;
        }
        
        // Conclusion
        if (conclusion.isNotEmpty) {
          graphics.drawString(
            'Conclusion:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(PdfColor(150, 0, 150)),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 20),
          );
          yPosition += 25;
          
          graphics.drawString(
            _cleanTextForPDF(conclusion),
            PdfStandardFont(PdfFontFamily.helvetica, 12),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
          );
        }
        break;
        
      case 'data_table':
        final List<dynamic> headers = slide['headers'] ?? [];
        final List<dynamic> rows = slide['rows'] ?? [];
        
        if (headers.isNotEmpty && rows.isNotEmpty) {
          final double columnWidth = (pageSize.width - 80) / headers.length;
          final double rowHeight = 30;
          
          // Draw table headers
          for (int i = 0; i < headers.length; i++) {
            final headerRect = Rect.fromLTWH(40 + (i * columnWidth), yPosition, columnWidth, rowHeight);
            graphics.drawRectangle(
              pen: PdfPen(PdfColor(0, 0, 0)),
              brush: PdfSolidBrush(PdfColor(200, 200, 255)),
              bounds: headerRect,
            );
            
            graphics.drawString(
              _cleanTextForPDF(headers[i].toString()),
              PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
              brush: PdfSolidBrush(PdfColor(0, 0, 0)),
              bounds: headerRect,
              format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
            );
          }
          yPosition += rowHeight;
          
          // Draw table rows
          for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
            final row = rows[rowIndex] as List;
            for (int colIndex = 0; colIndex < row.length && colIndex < headers.length; colIndex++) {
              final cellRect = Rect.fromLTWH(40 + (colIndex * columnWidth), yPosition, columnWidth, rowHeight);
              graphics.drawRectangle(
                pen: PdfPen(PdfColor(0, 0, 0)),
                brush: PdfSolidBrush(rowIndex % 2 == 0 ? PdfColor(245, 245, 245) : PdfColor(255, 255, 255)),
                bounds: cellRect,
              );
              
              graphics.drawString(
                _cleanTextForPDF(row[colIndex].toString()),
                PdfStandardFont(PdfFontFamily.helvetica, 10),
                brush: PdfSolidBrush(pdfTextColor),
                bounds: cellRect,
                format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
              );
            }
            yPosition += rowHeight;
          }
        }
        break;
        
      case 'diagram':
        final String diagramType = slide['diagram_type'] ?? 'flowchart';
        final Map<String, dynamic> diagramData = slide['diagram_data'] ?? {};
        
        // Draw diagram placeholder in PDF (actual diagram rendering would need special handling)
        graphics.drawString(
          _cleanTextForPDF('Diagram: $diagramType'),
          PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(40, yPosition, 515, 30),
        );
        yPosition += 40;
        
        // Draw diagram description or key elements
        final description = slide['description']?.toString() ?? 'Interactive diagram content (see presentation view)';
        graphics.drawString(
          _cleanTextForPDF(description),
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(PdfColor(80, 80, 80)),
          bounds: Rect.fromLTWH(40, yPosition, 515, 100),
          format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top),
        );
        yPosition += 120;
        
        // Draw a simple placeholder box for the diagram
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(150, 150, 150)),
          bounds: Rect.fromLTWH(40, yPosition, 515, 200),
        );
        graphics.drawString(
          _cleanTextForPDF('[$diagramType Diagram]'),
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          brush: PdfSolidBrush(PdfColor(120, 120, 120)),
          bounds: Rect.fromLTWH(40, yPosition + 90, 515, 30),
          format: PdfStringFormat(alignment: PdfTextAlignment.center, lineAlignment: PdfVerticalAlignment.middle),
        );
        break;
        
      case 'flowchart':
        final List<dynamic> steps = slide['steps'] ?? [];
        
        double flowY = yPosition;
        for (int i = 0; i < steps.length; i++) {
          final step = steps[i];
          final stepType = step['type'] ?? 'process';
          final stepText = _cleanTextForPDF(step['text'] ?? '');
          
          // Choose color based on step type
          PdfColor stepColor;
          switch (stepType) {
            case 'start':
              stepColor = PdfColor(0, 150, 0);
              break;
            case 'end':
              stepColor = PdfColor(200, 0, 0);
              break;
            case 'decision':
              stepColor = PdfColor(200, 150, 0);
              break;
            default:
              stepColor = PdfColor(0, 100, 200);
          }
          
          // Draw step box
          final lightStepColor = PdfColor(
            (stepColor.r * 0.3 + 255 * 0.7).round(),
            (stepColor.g * 0.3 + 255 * 0.7).round(),
            (stepColor.b * 0.3 + 255 * 0.7).round(),
          );
          graphics.drawRectangle(
            pen: PdfPen(stepColor),
            brush: PdfSolidBrush(lightStepColor),
            bounds: Rect.fromLTWH(40, flowY, pageSize.width - 80, 40),
          );
          
          // Draw step text
          graphics.drawString(
            stepText,
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            brush: PdfSolidBrush(stepColor),
            bounds: Rect.fromLTWH(50, flowY + 10, pageSize.width - 100, 20),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          
          flowY += 50;
          
          // Draw arrow to next step (except for last step)
          if (i < steps.length - 1) {
            graphics.drawLine(
              PdfPen(PdfColor(100, 100, 100), width: 2),
              Offset(pageSize.width / 2, flowY - 10),
              Offset(pageSize.width / 2, flowY),
            );
            
            // Draw arrow head
            graphics.drawLine(
              PdfPen(PdfColor(100, 100, 100), width: 2),
              Offset(pageSize.width / 2 - 5, flowY - 5),
              Offset(pageSize.width / 2, flowY),
            );
            graphics.drawLine(
              PdfPen(PdfColor(100, 100, 100), width: 2),
              Offset(pageSize.width / 2 + 5, flowY - 5),
              Offset(pageSize.width / 2, flowY),
            );
          }
        }
        break;

      case 'matrix':
        final List<dynamic> criteria = slide['criteria'] ?? [];
        final List<dynamic> options = slide['options'] ?? [];
        
        if (criteria.isNotEmpty && options.isNotEmpty) {
          // Draw table headers
          double tableX = 40;
          double tableY = yPosition;
          double cellWidth = (pageSize.width - 80) / (criteria.length + 1);
          double cellHeight = 25;
          
          // Header row
          _drawTextSafely(graphics, 'Options', 
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(tableX, tableY, cellWidth, cellHeight));
            
          for (int i = 0; i < criteria.length; i++) {
            _drawTextSafely(graphics, _cleanTextForPDF(criteria[i].toString()),
              PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(tableX + (i + 1) * cellWidth, tableY, cellWidth, cellHeight));
          }
          tableY += cellHeight;
          
          // Data rows
          for (final option in options) {
            final scores = option['scores'] as List<dynamic>? ?? [];
            _drawTextSafely(graphics, _cleanTextForPDF(option['name']?.toString() ?? ''),
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(tableX, tableY, cellWidth, cellHeight));
              
            for (int i = 0; i < scores.length && i < criteria.length; i++) {
              _drawTextSafely(graphics, scores[i].toString(),
                PdfStandardFont(PdfFontFamily.helvetica, 12),
                PdfSolidBrush(pdfTextColor),
                Rect.fromLTWH(tableX + (i + 1) * cellWidth, tableY, cellWidth, cellHeight));
            }
            tableY += cellHeight;
          }
        }
        break;

      case 'equation_set':
        final List<dynamic> equations = slide['equations'] ?? [];
        final String method = slide['method']?.toString() ?? '';
        
        if (method.isNotEmpty) {
          _drawTextSafely(graphics, 'Method: ${_cleanTextForPDF(method)}',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(0, 100, 200)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 35;
        }
        
        for (final eq in equations) {
          final equation = _processFormulaText(eq['equation']?.toString() ?? '');
          final description = eq['description']?.toString() ?? '';
          
          // Draw equation in larger font
          _drawTextSafely(graphics, equation,
            PdfStandardFont(PdfFontFamily.courier, 16, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 30));
          yPosition += 35;
          
          if (description.isNotEmpty) {
            _drawTextSafely(graphics, _cleanTextForPDF(description),
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              PdfSolidBrush(PdfColor(100, 100, 100)),
              Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20));
            yPosition += 25;
          }
          yPosition += 10;
        }
        break;

      case 'theorem':
        final String statement = slide['statement']?.toString() ?? '';
        final String formula = slide['formula']?.toString() ?? '';
        final List<dynamic> proofSteps = slide['proof_steps'] ?? [];
        final List<dynamic> applications = slide['applications'] ?? [];
        
        if (statement.isNotEmpty) {
          _drawTextSafely(graphics, 'Statement: ${_cleanTextForPDF(statement)}',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.italic),
            PdfSolidBrush(PdfColor(0, 0, 150)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 60),
            format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top));
          yPosition += 70;
        }
        
        if (formula.isNotEmpty) {
          _drawTextSafely(graphics, _processFormulaText(formula),
            PdfStandardFont(PdfFontFamily.courier, 18, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(0, 150, 0)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40));
          yPosition += 50;
        }
        
        if (proofSteps.isNotEmpty) {
          _drawTextSafely(graphics, 'Proof Steps:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 30;
          
          for (final step in proofSteps) {
            _drawTextSafely(graphics, '• ${_cleanTextForPDF(step.toString())}',
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20));
            yPosition += 25;
          }
        }
        break;

      case 'algorithm':
        final String complexity = slide['complexity']?.toString() ?? '';
        final List<dynamic> steps = slide['steps'] ?? [];
        final List<dynamic> advantages = slide['advantages'] ?? [];
        
        if (complexity.isNotEmpty) {
          _drawTextSafely(graphics, 'Complexity: ${_cleanTextForPDF(complexity)}',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(200, 100, 0)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 35;
        }
        
        if (steps.isNotEmpty) {
          _drawTextSafely(graphics, 'Algorithm Steps:',
            PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 30;
          
          for (final step in steps) {
            _drawTextSafely(graphics, _cleanTextForPDF(step.toString()),
              PdfStandardFont(PdfFontFamily.courier, 11),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20));
            yPosition += 25;
          }
        }
        break;

      case 'chemical':
        final String reaction = slide['reaction']?.toString() ?? '';
        final String reactionType = slide['type_reaction']?.toString() ?? '';
        final List<dynamic> conditions = slide['conditions'] ?? [];
        final String energyChange = slide['energy_change']?.toString() ?? '';
        
        if (reaction.isNotEmpty) {
          _drawTextSafely(graphics, _processFormulaText(reaction),
            PdfStandardFont(PdfFontFamily.courier, 18, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(0, 100, 200)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40));
          yPosition += 50;
        }
        
        if (reactionType.isNotEmpty) {
          _drawTextSafely(graphics, 'Reaction Type: ${_cleanTextForPDF(reactionType)}',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(0, 150, 0)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 30;
        }
        
        if (conditions.isNotEmpty) {
          _drawTextSafely(graphics, 'Conditions:',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 25;
          
          for (final condition in conditions) {
            _drawTextSafely(graphics, '• ${_cleanTextForPDF(condition.toString())}',
              PdfStandardFont(PdfFontFamily.helvetica, 11),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20));
            yPosition += 22;
          }
        }
        break;

      case 'physics':
        final List<dynamic> laws = slide['laws'] ?? [];
        final List<dynamic> applications = slide['applications'] ?? [];
        
        for (final law in laws) {
          final number = law['number']?.toString() ?? '';
          final statement = law['statement']?.toString() ?? '';
          final formula = law['formula']?.toString() ?? '';
          
          if (number.isNotEmpty) {
            _drawTextSafely(graphics, number,
              PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
              PdfSolidBrush(PdfColor(0, 100, 200)),
              Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
            yPosition += 30;
          }
          
          if (statement.isNotEmpty) {
            _drawTextSafely(graphics, _cleanTextForPDF(statement),
              PdfStandardFont(PdfFontFamily.helvetica, 12),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
              format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top));
            yPosition += 45;
          }
          
          if (formula.isNotEmpty) {
            _drawTextSafely(graphics, _processFormulaText(formula),
              PdfStandardFont(PdfFontFamily.courier, 14, style: PdfFontStyle.bold),
              PdfSolidBrush(PdfColor(0, 150, 0)),
              Rect.fromLTWH(60, yPosition, pageSize.width - 120, 25));
            yPosition += 35;
          }
          yPosition += 10;
        }
        break;

      case 'swot':
        final List<dynamic> strengths = slide['strengths'] ?? [];
        final List<dynamic> weaknesses = slide['weaknesses'] ?? [];
        final List<dynamic> opportunities = slide['opportunities'] ?? [];
        final List<dynamic> threats = slide['threats'] ?? [];
        
        double quadrantWidth = (pageSize.width - 120) / 2;
        double quadrantHeight = 150;
        
        // Draw SWOT quadrants
        _drawSWOTQuadrantPDF(graphics, 'Strengths', strengths, 40, yPosition, quadrantWidth, quadrantHeight, PdfColor(0, 150, 0), pdfTextColor);
        _drawSWOTQuadrantPDF(graphics, 'Weaknesses', weaknesses, 60 + quadrantWidth, yPosition, quadrantWidth, quadrantHeight, PdfColor(200, 0, 0), pdfTextColor);
        _drawSWOTQuadrantPDF(graphics, 'Opportunities', opportunities, 40, yPosition + quadrantHeight + 20, quadrantWidth, quadrantHeight, PdfColor(0, 100, 200), pdfTextColor);
        _drawSWOTQuadrantPDF(graphics, 'Threats', threats, 60 + quadrantWidth, yPosition + quadrantHeight + 20, quadrantWidth, quadrantHeight, PdfColor(200, 100, 0), pdfTextColor);
        break;

      case 'experiment':
        final String objective = slide['objective']?.toString() ?? '';
        final List<dynamic> materials = slide['materials'] ?? [];
        final List<dynamic> procedure = slide['procedure'] ?? [];
        final Map<String, dynamic> variables = slide['variables'] as Map<String, dynamic>? ?? {};
        
        if (objective.isNotEmpty) {
          _drawTextSafely(graphics, 'Objective: ${_cleanTextForPDF(objective)}',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            PdfSolidBrush(PdfColor(0, 100, 200)),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 40),
            format: PdfStringFormat(lineAlignment: PdfVerticalAlignment.top));
          yPosition += 50;
        }
        
        if (materials.isNotEmpty) {
          _drawTextSafely(graphics, 'Materials:',
            PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
            PdfSolidBrush(pdfTextColor),
            Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25));
          yPosition += 25;
          
          for (final material in materials) {
            _drawTextSafely(graphics, '• ${_cleanTextForPDF(material.toString())}',
              PdfStandardFont(PdfFontFamily.helvetica, 11),
              PdfSolidBrush(pdfTextColor),
              Rect.fromLTWH(60, yPosition, pageSize.width - 100, 20));
            yPosition += 22;
          }
          yPosition += 10;
        }
        break;
        
      default: // content, image, conclusion
        final List<dynamic> contentList = slide['content'] ?? [];
        for (final item in contentList) {
          final cleanText = _cleanTextForPDF(item.toString());
          graphics.drawString(
            cleanText,
            PdfStandardFont(PdfFontFamily.helvetica, 14),
            brush: PdfSolidBrush(pdfTextColor),
            bounds: Rect.fromLTWH(40, yPosition, pageSize.width - 80, 25),
          );
          yPosition += 30;
        }
    }
  }

  static Future<bool> _savePDFToAhamAIFolder(Uint8List bytes, String fileName) async {
    try {
      print('Attempting to save to external storage...');
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory!.parent.parent.parent.parent.path}/Download';
      final ahamAIPath = '$downloadsPath/AhamAI';
      
      final ahamAIDirectory = Directory(ahamAIPath);
      if (!await ahamAIDirectory.exists()) {
        print('Creating directory: $ahamAIPath');
        await ahamAIDirectory.create(recursive: true);
      }
      
      final file = File('$ahamAIPath/$fileName');
      await file.writeAsBytes(bytes);
      print('✅ Successfully saved to: ${file.path}');
      return true;
    } catch (error) {
      print('External storage failed: $error, trying app documents...');
      try {
        final directory = await getApplicationDocumentsDirectory();
        final ahamAIPath = '${directory.path}/AhamAI';
        
        final ahamAIDirectory = Directory(ahamAIPath);
        if (!await ahamAIDirectory.exists()) {
          print('Creating app documents directory: $ahamAIPath');
          await ahamAIDirectory.create(recursive: true);
        }
        
        final file = File('$ahamAIPath/$fileName');
        await file.writeAsBytes(bytes);
        print('✅ Successfully saved to app documents: ${file.path}');
        return true;
      } catch (appError) {
        print('❌ Both storage methods failed: $appError');
        return false;
      }
    }
  }

  // Clean text for PDF rendering to avoid font issues
  static String _cleanTextForPDF(String text) {
    if (text.isEmpty) return '';
    
    try {
      // ULTRA-ROBUST approach: Process each character with comprehensive error handling
      StringBuffer buffer = StringBuffer();
      
      for (int i = 0; i < text.length; i++) {
        try {
          int charCode = text.codeUnitAt(i);
          
          // Keep basic ASCII characters and essential whitespace
          if ((charCode >= 32 && charCode <= 126) || charCode == 10 || charCode == 13 || charCode == 9) {
            buffer.write(text[i]);
            continue;
          }
          
          // Handle problematic characters with comprehensive mapping
          String replacement = _getCharacterReplacement(charCode);
          buffer.write(replacement);
          
        } catch (e) {
          // If any single character causes issues, skip it entirely
          print('Warning: Skipping problematic character at position $i');
          continue;
        }
      }
      
      String result = buffer.toString();
      
      // Clean up multiple spaces and ensure valid result
      result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Ensure we never return empty strings for non-empty input
      if (result.isEmpty && text.isNotEmpty) {
        result = 'Content processed for PDF compatibility';
      }
      
      return result;
      
    } catch (e) {
      print('Critical error in _cleanTextForPDF: $e');
      // Last resort: return a safe fallback
      return text.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  
  // ULTRA-ROBUST font-safe text processing for formulas and scientific content
  static String _processFormulaText(String text) {
    try {
      // Special handling for mathematical and scientific notation
      return text
          // Mathematical operators
          .replaceAll('×', 'x')
          .replaceAll('÷', '/')
          .replaceAll('∞', 'infinity')
          .replaceAll('≈', '~=')
          .replaceAll('≠', '!=')
          .replaceAll('≤', '<=')
          .replaceAll('≥', '>=')
          .replaceAll('√', 'sqrt')
          .replaceAll('∑', 'sum')
          .replaceAll('∏', 'product')
          .replaceAll('∫', 'integral')
          // Chemical notation
          .replaceAll('₁', '1')
          .replaceAll('₂', '2')
          .replaceAll('₃', '3')
          .replaceAll('₄', '4')
          .replaceAll('₅', '5')
          .replaceAll('₆', '6')
          .replaceAll('₇', '7')
          .replaceAll('₈', '8')
          .replaceAll('₉', '9')
          .replaceAll('₀', '0')
          // Superscripts
          .replaceAll('¹', '1')
          .replaceAll('²', '2')
          .replaceAll('³', '3')
          .replaceAll('⁴', '4')
          .replaceAll('⁵', '5')
          .replaceAll('⁶', '6')
          .replaceAll('⁷', '7')
          .replaceAll('⁸', '8')
          .replaceAll('⁹', '9')
          .replaceAll('⁰', '0')
          // Greek letters commonly used in formulas
          .replaceAll('α', 'alpha')
          .replaceAll('β', 'beta')
          .replaceAll('γ', 'gamma')
          .replaceAll('δ', 'delta')
          .replaceAll('θ', 'theta')
          .replaceAll('λ', 'lambda')
          .replaceAll('μ', 'mu')
          .replaceAll('π', 'pi')
          .replaceAll('σ', 'sigma')
          .replaceAll('Ω', 'Omega')
          // Arrows and other symbols
          .replaceAll('→', '->')
          .replaceAll('←', '<-')
          .replaceAll('↔', '<->')
          .replaceAll('°', ' degrees')
          // Apply general cleaning
          ;
    } catch (e) {
      print('Error processing formula text: $e');
      return text.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), ' ');
    }
  }

  // Enhanced font-safe drawing with multiple fallback strategies
  static void _drawTextSafely(PdfGraphics graphics, String text, PdfStandardFont font, PdfSolidBrush brush, Rect bounds, {PdfStringFormat? format}) {
    try {
      // First attempt: Clean the text thoroughly
      String cleanText = _cleanTextForPDF(text);
      
      if (cleanText.trim().isEmpty && text.trim().isNotEmpty) {
        cleanText = 'Content processed for PDF compatibility';
      }
      
      try {
        graphics.drawString(cleanText, font, brush: brush, bounds: bounds, format: format);
      } catch (fontError) {
        print('Font error with cleaned text, trying ultra-safe mode: $fontError');
        
        // Ultra-safe fallback: Only basic ASCII
        String ultraSafeText = cleanText.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        
        if (ultraSafeText.isEmpty) {
          ultraSafeText = '[Content unavailable - special characters]';
        }
        
        try {
          graphics.drawString(ultraSafeText, font, brush: brush, bounds: bounds, format: format);
        } catch (ultraError) {
          print('Even ultra-safe text failed, using absolute fallback: $ultraError');
          // Absolute last resort
          graphics.drawString('[Error: Text rendering failed]', font, brush: brush, bounds: bounds, format: format);
        }
      }
    } catch (e) {
      print('Complete text drawing failure: $e');
      // Emergency rectangle to show something was attempted
      try {
        graphics.drawRectangle(
          pen: PdfPen(PdfColor(200, 200, 200)),
          bounds: bounds,
        );
      } catch (_) {
        // If even drawing a rectangle fails, just continue
      }
    }
  }

  // Comprehensive character replacement mapping
  static String _getCharacterReplacement(int charCode) {
    // Use a map for better performance and maintainability
    const Map<int, String> characterMap = {
      // Smart quotes and apostrophes
      8216: "'", 8217: "'", 8218: ",", 8220: '"', 8221: '"', 8222: '"',
      
      // Dashes and punctuation
      8211: "-", 8212: "--", 8230: "...", 8226: "-", 8259: "-", 8282: ":",
      
      // INVISIBLE OPERATORS - CRITICAL FOR 8289 ERROR
      8289: "", // Function application (U+2061) - THIS IS THE PROBLEMATIC ONE!
      8288: "", // Word joiner (U+2060)
      8290: "", // Invisible times (U+2062)
      8291: "", // Invisible separator (U+2063)
      8292: "", // Invisible plus (U+2064)
      
      // Zero-width and formatting characters
      8203: "", 8204: "", 8205: "", 8206: "", 8207: "", 65279: "",
      173: "-", 160: " ",
      
      // Mathematical symbols
      8734: "infinity", 8776: "approx", 8800: "!=", 8804: "<=", 8805: ">=",
      177: "+/-", 215: "x", 247: "/", 8730: "sqrt", 8721: "sum",
      8719: "product", 8747: "integral", 8706: "partial", 8711: "nabla",
      8709: "empty_set", 8712: "in", 8713: "not_in", 8745: "intersection", 8746: "union",
      
      // Greek letters (lowercase)
      945: "alpha", 946: "beta", 947: "gamma", 948: "delta", 949: "epsilon",
      950: "zeta", 951: "eta", 952: "theta", 953: "iota", 954: "kappa",
      955: "lambda", 956: "mu", 957: "nu", 958: "xi", 960: "pi",
      961: "rho", 963: "sigma", 964: "tau", 965: "upsilon", 966: "phi",
      967: "chi", 968: "psi", 969: "omega",
      
      // Greek letters (uppercase)
      913: "Alpha", 914: "Beta", 915: "Gamma", 916: "Delta", 917: "Epsilon",
      918: "Zeta", 919: "Eta", 920: "Theta", 921: "Iota", 922: "Kappa",
      923: "Lambda", 924: "Mu", 925: "Nu", 926: "Xi", 928: "Pi",
      929: "Rho", 931: "Sigma", 932: "Tau", 933: "Upsilon", 934: "Phi",
      935: "Chi", 936: "Psi", 937: "Omega",
      
      // Superscripts
      8304: "0", 185: "1", 178: "2", 179: "3", 8308: "4", 8309: "5",
      8310: "6", 8311: "7", 8312: "8", 8313: "9",
      
      // Subscripts
      8320: "0", 8321: "1", 8322: "2", 8323: "3", 8324: "4", 8325: "5",
      8326: "6", 8327: "7", 8328: "8", 8329: "9",
      
      // Subscript letters
      8336: "a", 8337: "e", 8338: "o", 8339: "x", 8340: "e",
      8341: "h", 8342: "k", 8343: "l", 8344: "m", 8345: "n", // THE PROBLEMATIC 8345!
      8346: "p", 8347: "s", 8348: "t",
      
      // Currency symbols
      8364: "EUR", 163: "GBP", 165: "JPY", 162: "cents",
      
      // Arrows
      8592: "<-", 8594: "->", 8593: "^", 8595: "v", 8596: "<->",
      8597: "<->", 8656: "<=", 8658: "=>", 8660: "<=>",
      
      // Special symbols
      169: "(C)", 174: "(R)", 8482: "(TM)", 167: "section", 182: "paragraph",
      8224: "dagger", 8225: "double_dagger", 176: " degrees",
      
      // Bullets and shapes
      9679: "-", 9675: "-", 9642: "-", 9643: "-", 9670: "-",
      8250: ">", 8249: "<", 8629: "enter", 8617: "tab", 8618: "shift",
      9251: " ", 9166: "return",
      
      // Fractions
      188: "1/4", 189: "1/2", 190: "3/4", 8531: "1/3", 8532: "2/3",
      8533: "1/5", 8534: "2/5", 8535: "3/5", 8536: "4/5", 8537: "1/6",
      8538: "5/6", 8539: "1/8", 8540: "3/8", 8541: "5/8", 8542: "7/8",
    };
    
    // Look up character in our comprehensive map
    if (characterMap.containsKey(charCode)) {
      return characterMap[charCode]!;
    }
    
    // For any other non-ASCII character, replace with space
    if (charCode > 127) {
      return " ";
    }
    
    // For ASCII control characters, return empty string
    return "";
  }

  // Helper function to draw SWOT quadrants in PDF
  static void _drawSWOTQuadrantPDF(PdfGraphics graphics, String title, List<dynamic> items, double x, double y, double width, double height, PdfColor headerColor, PdfColor textColor) {
    try {
      // Draw border
      graphics.drawRectangle(
        pen: PdfPen(headerColor),
        bounds: Rect.fromLTWH(x, y, width, height),
      );
      
      // Draw header
      _drawTextSafely(graphics, title,
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        PdfSolidBrush(headerColor),
        Rect.fromLTWH(x + 5, y + 5, width - 10, 20));
      
      // Draw items
      double itemY = y + 25;
      for (final item in items) {
        if (itemY + 15 < y + height) {
          _drawTextSafely(graphics, '• ${_cleanTextForPDF(item.toString())}',
            PdfStandardFont(PdfFontFamily.helvetica, 10),
            PdfSolidBrush(textColor),
            Rect.fromLTWH(x + 5, itemY, width - 10, 15));
          itemY += 17;
        }
      }
    } catch (e) {
      print('Error drawing SWOT quadrant: $e');
    }
  }
}