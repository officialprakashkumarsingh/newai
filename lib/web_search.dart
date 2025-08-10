import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class SearchResult {
  final String title;
  final String url;
  final String snippet; // Added snippet field to store description
  final String? faviconUrl;

  SearchResult({required this.title, required this.url, required this.snippet, this.faviconUrl});

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'snippet': snippet,
    'faviconUrl': faviconUrl,
  };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    title: json['title'],
    url: json['url'],
    snippet: json['snippet'] ?? '',
    faviconUrl: json['faviconUrl'],
  );
}

class WebSearchResponse {
  final String promptContent;
  final List<SearchResult> results;

  WebSearchResponse({required this.promptContent, required this.results});
}

class WebSearchService {
  static Future<WebSearchResponse?> search(String query) async {
    final uri = Uri.parse('${ApiConfig.braveSearchUrl}?q=${Uri.encodeComponent(query)}&count=20');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip',
          'X-Subscription-Token': ApiConfig.braveSearchApiKey,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic>? resultsJson = decodedResponse['web']?['results'];

        if (resultsJson == null || resultsJson.isEmpty) {
          return null;
        }

        final searchResults = resultsJson.map((r) {
          return SearchResult(
            title: r['title'] ?? 'Untitled',
            url: r['url'] ?? '',
            snippet: r['description'] ?? 'No description available.', // Store actual description
            faviconUrl: r['profile']?['img'],
          );
        }).toList();
        
        final StringBuffer formattedResults = StringBuffer();
        formattedResults.writeln("Here are the top web search results for '$query':");
        
        for (var i = 0; i < searchResults.length; i++) {
          final result = searchResults[i];
          formattedResults.writeln('\n${i + 1}. Title: ${result.title}');
          formattedResults.writeln('   URL: ${result.url}');
          formattedResults.writeln('   Snippet: ${result.snippet}');
        }
        
        return WebSearchResponse(
          promptContent: formattedResults.toString(),
          results: searchResults
        );
      } else {
        print('Brave Search API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during web search: $e');
      return null;
    }
  }
}