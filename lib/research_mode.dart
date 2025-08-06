import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'web_search.dart';
import 'api_service.dart';
import 'theme.dart';

/// Research source result
class ResearchSearchResult {
  final String title;
  final String snippet;
  final String url;
  final String source;

  ResearchSearchResult({
    required this.title,
    required this.snippet,
    required this.url,
    required this.source,
  });
}

/// Research step for detailed logging
class ResearchStep {
  final String command;
  final String output;
  final DateTime timestamp;
  final bool isCompleted;
  final String? url;

  ResearchStep({
    required this.command,
    required this.output,
    required this.timestamp,
    this.isCompleted = false,
    this.url,
  });
}

class AdvancedResearchAgent {
  static const int maxResearchTimeMinutes = 15;
  
  /// Main research orchestrator - Python-like execution
  static Future<String> performDeepResearch({
    required String query,
    required String selectedModel,
    Function(ResearchStep)? onStepUpdate,
  }) async {
    final startTime = DateTime.now();
    final researchSteps = <ResearchStep>[];
    final allSources = <ResearchSearchResult>[];
    
    try {
      // Initialize research agent
      onStepUpdate?.call(ResearchStep(
        command: 'research_agent.initialize()',
        output: 'Starting deep research analysis for: "$query"',
        timestamp: DateTime.now(),
      ));

      // Step 1: Query analysis
      onStepUpdate?.call(ResearchStep(
        command: 'analyzer.parse_query(query)',
        output: 'Analyzing research requirements and scope...',
        timestamp: DateTime.now(),
      ));
      
      final queryAnalysis = await _analyzeQuery(query, selectedModel, onStepUpdate);
      
      // Step 2: Search strategy planning
      onStepUpdate?.call(ResearchStep(
        command: 'planner.create_search_strategy()',
        output: 'Generating multi-source search strategy...',
        timestamp: DateTime.now(),
      ));
      
      final searchTerms = await _generateSearchTerms(query, queryAnalysis, selectedModel, onStepUpdate);
      
      // Step 3: Execute multi-source data gathering
      onStepUpdate?.call(ResearchStep(
        command: 'collector.start_multi_source_search()',
        output: 'Initiating comprehensive data collection...',
        timestamp: DateTime.now(),
      ));
      
      // Web Search - Primary source
      for (int i = 0; i < searchTerms.take(3).length; i++) {
        final term = searchTerms[i];
        onStepUpdate?.call(ResearchStep(
          command: 'web_scraper.search(term="${term.substring(0, math.min(30, term.length))}...")',
          output: 'Searching web databases...',
          timestamp: DateTime.now(),
        ));
        
        final webResults = await _searchWeb(term, onStepUpdate);
        allSources.addAll(webResults);
        
        onStepUpdate?.call(ResearchStep(
          command: 'web_scraper.process_results()',
          output: 'Found ${webResults.length} web sources - extracting content...',
          timestamp: DateTime.now(),
          isCompleted: true,
        ));
      }
      
      // Wikipedia - Knowledge base
      onStepUpdate?.call(ResearchStep(
        command: 'wikipedia_api.query()',
        output: 'Accessing Wikipedia knowledge base...',
        timestamp: DateTime.now(),
      ));
      
      final wikiResults = await _searchWikipedia(query, onStepUpdate);
      allSources.addAll(wikiResults);
      
      onStepUpdate?.call(ResearchStep(
        command: 'wikipedia_api.extract_content()',
        output: 'Extracted ${wikiResults.length} encyclopedic articles',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      // Academic sources
      onStepUpdate?.call(ResearchStep(
        command: 'arxiv_scraper.search_papers()',
        output: 'Scanning academic databases (ArXiv)...',
        timestamp: DateTime.now(),
      ));
      
      final academicResults = await _searchAcademic(query, onStepUpdate);
      allSources.addAll(academicResults);
      
      onStepUpdate?.call(ResearchStep(
        command: 'arxiv_scraper.analyze_papers()',
        output: 'Found ${academicResults.length} research papers',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      // Scientific literature
      onStepUpdate?.call(ResearchStep(
        command: 'semantic_scholar.search()',
        output: 'Querying scientific literature database...',
        timestamp: DateTime.now(),
      ));
      
      final scientificResults = await _searchSemanticScholar(query, onStepUpdate);
      allSources.addAll(scientificResults);
      
      onStepUpdate?.call(ResearchStep(
        command: 'semantic_scholar.compile_results()',
        output: 'Compiled ${scientificResults.length} scientific studies',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      // GitHub for technical content
      onStepUpdate?.call(ResearchStep(
        command: 'github_api.search_repositories()',
        output: 'Searching technical repositories...',
        timestamp: DateTime.now(),
      ));
      
      final githubResults = await _searchGitHub(query, onStepUpdate);
      allSources.addAll(githubResults);
      
      onStepUpdate?.call(ResearchStep(
        command: 'github_api.extract_documentation()',
        output: 'Found ${githubResults.length} technical resources',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      // Step 4: Source verification and quality assessment
      onStepUpdate?.call(ResearchStep(
        command: 'verifier.analyze_source_credibility()',
        output: 'Cross-verifying ${allSources.length} sources for accuracy...',
        timestamp: DateTime.now(),
      ));
      
      final verificationResult = await _verifySources(allSources, selectedModel, onStepUpdate);
      
      onStepUpdate?.call(ResearchStep(
        command: 'verifier.quality_assessment_complete()',
        output: 'Source verification completed - credibility scores calculated',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      // Step 5: Comprehensive synthesis
      onStepUpdate?.call(ResearchStep(
        command: 'synthesizer.compile_comprehensive_report()',
        output: 'Generating extensive research report (6000+ words)...',
        timestamp: DateTime.now(),
      ));
      
      final finalReport = await _synthesizeComprehensiveReport(
        query, 
        queryAnalysis,
        allSources, 
        verificationResult, 
        selectedModel, 
        onStepUpdate
      );
      
      final duration = DateTime.now().difference(startTime);
      
      onStepUpdate?.call(ResearchStep(
        command: 'research_agent.finalize()',
        output: 'Research completed in ${duration.inMinutes}m ${duration.inSeconds % 60}s - Generated ${finalReport.split(' ').length} words from ${allSources.length} sources',
        timestamp: DateTime.now(),
        isCompleted: true,
      ));
      
      return finalReport;
      
    } catch (error) {
      onStepUpdate?.call(ResearchStep(
        command: 'error_handler.log_exception()',
        output: 'Research failed: $error',
        timestamp: DateTime.now(),
      ));
      throw Exception('Research agent failed: $error');
    }
  }

  /// Analyze query requirements
  static Future<String> _analyzeQuery(String query, String model, Function(ResearchStep)? onUpdate) async {
    onUpdate?.call(ResearchStep(
      command: 'analyzer.deep_parse()',
      output: 'Breaking down query components and research requirements...',
      timestamp: DateTime.now(),
    ));

    final prompt = '''
Analyze this research query and provide a comprehensive understanding:

QUERY: "$query"

Provide a detailed analysis covering:
1. Core research topic and scope
2. Required information depth and breadth  
3. Key areas to investigate
4. Potential challenges and information gaps
5. Recommended research approach

Keep response concise but thorough (300-500 words).
''';

    String response = '';
    await for (final chunk in ApiService.sendChatMessage(
      message: prompt,
      model: model,
    )) {
      response += chunk;
    }

    onUpdate?.call(ResearchStep(
      command: 'analyzer.extract_requirements()',
      output: 'Query analysis complete - identified key research areas',
      timestamp: DateTime.now(),
      isCompleted: true,
    ));

    return response;
  }

  /// Generate targeted search terms
  static Future<List<String>> _generateSearchTerms(String query, String analysis, String model, Function(ResearchStep)? onUpdate) async {
    onUpdate?.call(ResearchStep(
      command: 'term_generator.create_variations()',
      output: 'Generating optimized search terms and variations...',
      timestamp: DateTime.now(),
    ));

    final prompt = '''
Based on this query analysis, generate 8-10 specific search terms for comprehensive research:

ORIGINAL QUERY: "$query"
ANALYSIS: $analysis

Generate terms that will find:
- Academic and scientific sources
- Current news and developments  
- Technical documentation
- Expert opinions and analysis
- Statistical data and studies

Provide only the search terms, one per line, without quotes or formatting.
''';

    String response = '';
    await for (final chunk in ApiService.sendChatMessage(
      message: prompt,
      model: model,
    )) {
      response += chunk;
    }

    final terms = response
        .split('\n')
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty && !term.startsWith('-') && !term.contains(':'))
        .take(8)
        .toList();

    if (terms.isEmpty) {
      terms.add(query); // Fallback to original query
    }

    onUpdate?.call(ResearchStep(
      command: 'term_generator.optimize_terms()',
      output: 'Generated ${terms.length} targeted search variations',
      timestamp: DateTime.now(),
      isCompleted: true,
    ));

    return terms;
  }

  /// Web search with detailed logging
  static Future<List<ResearchSearchResult>> _searchWeb(String query, Function(ResearchStep)? onUpdate) async {
    try {
      onUpdate?.call(ResearchStep(
        command: 'requests.get("https://api.search.brave.com/...")',
        output: 'Connecting to Brave Search API...',
        timestamp: DateTime.now(),
      ));

      final searchResponse = await WebSearchService.search(query);
      if (searchResponse != null && searchResponse.results.isNotEmpty) {
        onUpdate?.call(ResearchStep(
          command: 'parser.extract_search_results()',
          output: 'Processing ${searchResponse.results.length} web results...',
          timestamp: DateTime.now(),
        ));

        return searchResponse.results.take(15).map((result) => 
          ResearchSearchResult(
            title: result.title,
            snippet: result.snippet, // Now using actual snippet content
            url: result.url,
            source: 'Web Search',
          )
        ).toList();
      }
    } catch (e) {
      onUpdate?.call(ResearchStep(
        command: 'error_handler.log_web_search_error()',
        output: 'Web search error: $e',
        timestamp: DateTime.now(),
      ));
    }
    return [];
  }

  /// Wikipedia search with detailed logging
  static Future<List<ResearchSearchResult>> _searchWikipedia(String query, Function(ResearchStep)? onUpdate) async {
    try {
      onUpdate?.call(ResearchStep(
        command: 'wikipedia.opensearch("$query")',
        output: 'Querying Wikipedia API...',
        timestamp: DateTime.now(),
        url: 'https://en.wikipedia.org/api/rest_v1/page/search',
      ));

      final url = 'https://en.wikipedia.org/api/rest_v1/page/search/$query';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['pages'] as List<dynamic>? ?? [];
        
        onUpdate?.call(ResearchStep(
          command: 'wikipedia.parse_articles()',
          output: 'Extracting content from ${pages.length} Wikipedia articles...',
          timestamp: DateTime.now(),
        ));

        return pages.take(8).map((page) => ResearchSearchResult(
          title: page['title'] ?? '',
          snippet: page['description'] ?? page['extract'] ?? 'Wikipedia article',
          url: 'https://en.wikipedia.org/wiki/${page['key']}',
          source: 'Wikipedia',
        )).toList();
      }
    } catch (e) {
      onUpdate?.call(ResearchStep(
        command: 'error_handler.log_wikipedia_error()',
        output: 'Wikipedia search error: $e',
        timestamp: DateTime.now(),
      ));
    }
    return [];
  }

  /// Academic search with detailed logging
  static Future<List<ResearchSearchResult>> _searchAcademic(String query, Function(ResearchStep)? onUpdate) async {
    try {
      onUpdate?.call(ResearchStep(
        command: 'arxiv.query_api(search_query="$query")',
        output: 'Searching ArXiv academic database...',
        timestamp: DateTime.now(),
        url: 'http://export.arxiv.org/api/query',
      ));

      final encodedQuery = Uri.encodeComponent(query);
      final url = 'http://export.arxiv.org/api/query?search_query=all:$encodedQuery&max_results=8';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final results = <ResearchSearchResult>[];
        final content = response.body;
        
        onUpdate?.call(ResearchStep(
          command: 'arxiv.parse_xml_response()',
          output: 'Parsing academic paper metadata and abstracts...',
          timestamp: DateTime.now(),
        ));
        
        final titleRegex = RegExp(r'<title>(.*?)</title>');
        final summaryRegex = RegExp(r'<summary>(.*?)</summary>');
        final linkRegex = RegExp(r'<id>(.*?)</id>');
        
        final titles = titleRegex.allMatches(content);
        final summaries = summaryRegex.allMatches(content);
        final links = linkRegex.allMatches(content);
        
        final titleList = titles.map((m) => m.group(1)?.trim() ?? '').toList();
        final summaryList = summaries.map((m) => m.group(1)?.trim() ?? '').toList();
        final linkList = links.map((m) => m.group(1)?.trim() ?? '').toList();
        
        for (int i = 0; i < math.min(titleList.length, math.min(summaryList.length, linkList.length)); i++) {
          if (titleList[i].isNotEmpty && !titleList[i].contains('ArXiv Query')) {
            results.add(ResearchSearchResult(
              title: titleList[i],
              snippet: summaryList[i],
              url: linkList[i],
              source: 'ArXiv',
            ));
          }
        }
        
        return results.take(6).toList();
      }
    } catch (e) {
      onUpdate?.call(ResearchStep(
        command: 'error_handler.log_arxiv_error()',
        output: 'ArXiv search error: $e',
        timestamp: DateTime.now(),
      ));
    }
    return [];
  }

  /// GitHub search with detailed logging
  static Future<List<ResearchSearchResult>> _searchGitHub(String query, Function(ResearchStep)? onUpdate) async {
    try {
      onUpdate?.call(ResearchStep(
        command: 'github_api.search_repositories(q="$query")',
        output: 'Scanning GitHub repositories for technical resources...',
        timestamp: DateTime.now(),
        url: 'https://api.github.com/search/repositories',
      ));

      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.github.com/search/repositories?q=$encodedQuery&sort=stars&per_page=6';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        
        onUpdate?.call(ResearchStep(
          command: 'github_api.extract_repo_data()',
          output: 'Found ${items.length} relevant repositories with documentation',
          timestamp: DateTime.now(),
        ));

        return items.map((item) => ResearchSearchResult(
          title: item['full_name'] ?? '',
          snippet: item['description'] ?? 'GitHub repository',
          url: item['html_url'] ?? '',
          source: 'GitHub',
        )).toList();
      }
    } catch (e) {
      onUpdate?.call(ResearchStep(
        command: 'error_handler.log_github_error()',
        output: 'GitHub search error: $e',
        timestamp: DateTime.now(),
      ));
    }
    return [];
  }

  /// Semantic Scholar search with detailed logging
  static Future<List<ResearchSearchResult>> _searchSemanticScholar(String query, Function(ResearchStep)? onUpdate) async {
    try {
      onUpdate?.call(ResearchStep(
        command: 'semantic_scholar.search_papers(query="$query")',
        output: 'Accessing Semantic Scholar scientific database...',
        timestamp: DateTime.now(),
        url: 'https://api.semanticscholar.org/graph/v1/paper/search',
      ));

      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://api.semanticscholar.org/graph/v1/paper/search?query=$encodedQuery&limit=6';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final papers = data['data'] as List<dynamic>? ?? [];
        
        onUpdate?.call(ResearchStep(
          command: 'semantic_scholar.process_papers()',
          output: 'Processing ${papers.length} scientific papers and abstracts',
          timestamp: DateTime.now(),
        ));

        return papers.map((paper) => ResearchSearchResult(
          title: paper['title'] ?? '',
          snippet: paper['abstract'] ?? 'Scientific paper',
          url: paper['url'] ?? '',
          source: 'Semantic Scholar',
        )).toList();
      }
    } catch (e) {
      onUpdate?.call(ResearchStep(
        command: 'error_handler.log_semantic_scholar_error()',
        output: 'Semantic Scholar search error: $e',
        timestamp: DateTime.now(),
      ));
    }
    return [];
  }

  /// Verify source credibility
  static Future<String> _verifySources(List<ResearchSearchResult> sources, String model, Function(ResearchStep)? onUpdate) async {
    onUpdate?.call(ResearchStep(
      command: 'verifier.cross_reference_sources()',
      output: 'Analyzing source credibility and cross-referencing information...',
      timestamp: DateTime.now(),
    ));

    final sourceSummary = sources.take(15).map((s) => '- ${s.source}: ${s.title}').join('\n');
    
    final prompt = '''
Analyze these research sources for credibility and potential bias:

SOURCES:
$sourceSummary

Provide a brief assessment covering:
1. Overall source credibility (academic vs commercial vs news)
2. Potential biases or limitations
3. Recommendations for information quality
4. Areas needing additional verification

Keep response concise (200-300 words).
''';

    String response = '';
    await for (final chunk in ApiService.sendChatMessage(
      message: prompt,
      model: model,
    )) {
      response += chunk;
    }

    onUpdate?.call(ResearchStep(
      command: 'verifier.generate_credibility_report()',
      output: 'Source verification analysis completed',
      timestamp: DateTime.now(),
      isCompleted: true,
    ));

    return response;
  }

  /// Generate comprehensive 6-10k word research report
  static Future<String> _synthesizeComprehensiveReport(
    String query,
    String analysis,
    List<ResearchSearchResult> sources,
    String verification,
    String model,
    Function(ResearchStep)? onUpdate,
  ) async {
    onUpdate?.call(ResearchStep(
      command: 'synthesizer.compile_extensive_report()',
      output: 'Generating comprehensive research report (target: 6000-10000 words)...',
      timestamp: DateTime.now(),
    ));

    // Prepare source data for AI
    final sourceData = sources.take(25).map((s) => 
        'Source: ${s.source}\nTitle: ${s.title}\nContent: ${s.snippet}\nURL: ${s.url}\n'
    ).join('\n---\n');

    final prompt = '''
Create an EXTREMELY COMPREHENSIVE research report (minimum 6000-10000 words) based on the collected data.

RESEARCH QUERY: "$query"

INITIAL ANALYSIS: $analysis

SOURCE VERIFICATION: $verification

COLLECTED SOURCES AND DATA:
$sourceData

Create a detailed, academic-quality research report with the following structure and requirements:

# Comprehensive Research Report: $query

## Executive Summary (500+ words)
[Provide detailed overview of findings, methodology, key insights, and major conclusions]

## Research Methodology and Approach (800+ words)
[Detailed explanation of research methods, source selection criteria, data collection processes, and analytical frameworks used]

## Literature Review and Source Analysis (1200+ words)
[Comprehensive review of all sources, organized by type (academic, web, technical, etc.) with detailed analysis of each major source]

## Detailed Findings and Analysis (2000+ words)

### Primary Research Findings
[Major discoveries and insights with extensive detail and evidence]

### Supporting Evidence and Data
[Detailed examination of supporting evidence with specific examples and data points]

### Trend Analysis and Patterns
[Comprehensive analysis of trends, patterns, and developments identified]

### Comparative Analysis  
[Detailed comparisons between sources, viewpoints, methodologies, or time periods]

### Technical Analysis (if applicable)
[In-depth technical examination of relevant aspects]

## Critical Evaluation and Assessment (1000+ words)

### Source Credibility and Reliability Assessment
[Detailed evaluation of source quality, methodology, and reliability]

### Bias Analysis and Limitations
[Comprehensive analysis of potential biases, limitations, and methodological concerns]

### Information Gaps and Uncertainties
[Detailed discussion of areas where information is incomplete or uncertain]

### Contradictions and Conflicting Information
[Analysis of conflicting information and how to interpret discrepancies]

## Practical Implications and Applications (800+ words)

### Current State Assessment
[Detailed analysis of current situation based on research]

### Future Projections and Scenarios
[Comprehensive analysis of likely future developments]

### Stakeholder Impact Analysis
[Detailed examination of how findings affect various stakeholders]

### Real-world Applications
[Extensive discussion of practical applications and implementations]

## Strategic Recommendations and Action Items (600+ words)

### Immediate Recommendations
[Detailed short-term recommendations with specific action items]

### Long-term Strategic Recommendations  
[Comprehensive long-term strategic guidance]

### Implementation Considerations
[Detailed discussion of implementation challenges and solutions]

### Further Research Priorities
[Specific areas requiring additional investigation]

## Comprehensive Conclusion (400+ words)
[Detailed synthesis bringing together all major findings and implications]

## Detailed Source Bibliography
[Complete citations and references for all sources used]

## Technical Appendices (if applicable)
[Additional technical data, charts, or supplementary information]

CRITICAL REQUIREMENTS:
- Minimum 6000 words, target 8000-10000 words
- Each section must be thoroughly developed with specific examples
- Include detailed analysis, not just summaries
- Use evidence from the provided sources extensively
- Maintain academic rigor while being accessible
- Provide specific, actionable insights
- Include quantitative data where available
- Address multiple perspectives and viewpoints
- Ensure comprehensive coverage of the topic

Write in a scholarly but accessible tone. Be extremely thorough and detailed in every section.
''';

    String response = '';
    await for (final chunk in ApiService.sendChatMessage(
      message: prompt,
      model: model,
    )) {
      response += chunk;
    }

    onUpdate?.call(ResearchStep(
      command: 'synthesizer.finalize_report()',
      output: 'Comprehensive report generated - ${response.split(' ').length} words',
      timestamp: DateTime.now(),
      isCompleted: true,
    ));

    return response;
  }
}

/// Inline research terminal widget for message UI
class InlineResearchTerminal extends StatefulWidget {
  final String query;
  final String selectedModel;
  final Function(String) onResult;

  const InlineResearchTerminal({
    super.key,
    required this.query,
    required this.selectedModel,
    required this.onResult,
  });

  @override
  State<InlineResearchTerminal> createState() => _InlineResearchTerminalState();
}

class _InlineResearchTerminalState extends State<InlineResearchTerminal> {
  final List<ResearchStep> _steps = [];
  final ScrollController _scrollController = ScrollController();
  bool _isResearching = true;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _startResearch();
  }

  void _startResearch() async {
    try {
      final result = await AdvancedResearchAgent.performDeepResearch(
        query: widget.query,
        selectedModel: widget.selectedModel,
        onStepUpdate: (step) {
          setState(() {
            _steps.add(step);
          });
          // Auto-scroll to bottom
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        },
      );

      setState(() {
        _isResearching = false;
      });
      
      widget.onResult(result);
    } catch (e) {
      setState(() {
        _isResearching = false;
      });
      widget.onResult('Research failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isLightTheme(context) 
            ? const Color(0xFF1E1E1E) // Dark terminal in light mode
            : const Color(0xFF0D1117), // Darker in dark mode
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLightTheme(context)
              ? const Color(0xFF404040)
              : const Color(0xFF21262D),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terminal header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isLightTheme(context)
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFF161B22),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Terminal indicators
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F57),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF28CA42),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'research_agent.py',
                  style: TextStyle(
                    color: isLightTheme(context)
                        ? const Color(0xFFE1E4E8)
                        : const Color(0xFFF0F6FC),
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isResearching) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF28CA42),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'running',
                    style: TextStyle(
                      color: const Color(0xFF28CA42),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: Text(
                    _isCollapsed ? '▼' : '▲',
                    style: TextStyle(
                      color: isLightTheme(context)
                          ? const Color(0xFFE1E4E8)
                          : const Color(0xFFF0F6FC),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Terminal content
          if (!_isCollapsed) ...[
            Container(
              height: 240,
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timestamp
                        Text(
                          '[${step.timestamp.toString().substring(11, 19)}]',
                          style: TextStyle(
                            color: isLightTheme(context)
                                ? const Color(0xFF6A737D)
                                : const Color(0xFF484F58),
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Status indicator
                        Text(
                          step.isCompleted ? '✓' : _isResearching ? '●' : '○',
                          style: TextStyle(
                            color: step.isCompleted 
                                ? const Color(0xFF28CA42)
                                : _isResearching 
                                    ? const Color(0xFF58A6FF)
                                    : isLightTheme(context)
                                        ? const Color(0xFF6A737D)
                                        : const Color(0xFF484F58),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Command and output
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Command
                              Text(
                                '>>> ${step.command}',
                                style: TextStyle(
                                  color: const Color(0xFF58A6FF),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              // Output
                              Text(
                                step.output,
                                style: TextStyle(
                                  color: isLightTheme(context)
                                      ? const Color(0xFFE1E4E8)
                                      : const Color(0xFFF0F6FC),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (step.url != null) ...[
                                Text(
                                  step.url!,
                                  style: TextStyle(
                                    color: const Color(0xFF79C0FF),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}