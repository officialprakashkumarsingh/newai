import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'api_service.dart';

class PresentationGenerator {
  static Future<List<String>> generateSlides(String topic) async {
    final prompt = """
    Create a professional presentation about "$topic" with the following requirements:
    1.  **Structure:** Create slides in this exact order:
        *   Title slide with the topic name
        *   Overview/Introduction slide
        *   Multiple content slides covering key aspects
        *   Conclusion or summary slide  
        *   The final slide MUST be a 'Thank You' or 'Q&A' slide.
    3.  **Content Quantity:** Generate between 8 and 12 slides in total.
    4.  **Output Format:** Provide ONLY the content with '---' as separator. Format each slide as:
       TITLE
       • Point 1
       • Point 2
       • Point 3
    """;

    try {
      final slides = <String>[];
      
      await for (final chunk in ApiService.sendChatMessage(
        message: prompt,
        model: 'gpt-4o', // Use a good model for presentations
        systemPrompt: 'You are a professional presentation creator. Create clear, concise, and engaging slide content.',
      )) {
        slides.add(chunk);
      }
      
      final rawText = slides.join('');
      if (rawText.isEmpty) return [];
      
      return rawText.split(RegExp(r'\n---\n*'));
    } catch (e) {
      print("Error generating presentation slides: $e");
      return [];
    }
  }
}

class PresentationViewScreen extends StatelessWidget {
  final List<String> slides;
  final String topic;

  const PresentationViewScreen({
    super.key,
    required this.slides,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterDeckApp(
      configuration: FlutterDeckConfiguration(
        // Define a global background for the light and dark themes separately.
        background: const FlutterDeckBackgroundConfiguration(
          light: FlutterDeckBackground.solid(Color(0xFFF5F5DC)), // Cream color
          dark: FlutterDeckBackground.solid(Color(0xFF000000)), // Black AMOLED
        ),
        // Set defaults for the footer.
        footer: const FlutterDeckFooterConfiguration(showSlideNumbers: true, showSocialHandle: false),
        // Set defaults for the header.
        header: const FlutterDeckHeaderConfiguration(showHeader: false),
        // Override the default marker configuration.
        marker: const FlutterDeckMarkerConfiguration(color: Color(0xFFFF8C00), strokeWidth: 6.0), // Dim orange
        // Show progress indicator with specifc gradient and background color.
        progressIndicator: const FlutterDeckProgressIndicator.solid(
          color: Color(0xFFFF8C00), // Dim orange
          backgroundColor: Color(0x88000000),
        ),
        slideSize: FlutterDeckSlideSize.fromAspectRatio(
          aspectRatio: const FlutterDeckAspectRatio.ratio16x9(),
          resolution: const FlutterDeckResolution.fhd(),
        ),
        transition: const FlutterDeckTransition.slide(),
      ),
      lightTheme: FlutterDeckThemeData.light().copyWith(
        textTheme: const FlutterDeckTextTheme(
          display: TextStyle(
            color: Color(0xFF000000), // Black text on cream
            fontSize: 56,
            fontWeight: FontWeight.w900,
          ),
          title: TextStyle(
            color: Color(0xFFFF8C00), // Dim orange for titles
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
          subtitle: TextStyle(
            color: Color(0xFF333333), // Dark gray for subtitles
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
          header: TextStyle(
            color: Color(0xFFFF8C00), // Dim orange for headers
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      darkTheme: FlutterDeckThemeData.dark().copyWith(
        textTheme: const FlutterDeckTextTheme(
          display: TextStyle(
            color: Color(0xFFFFFFFF), // White text on black
            fontSize: 56,
            fontWeight: FontWeight.w900,
          ),
          title: TextStyle(
            color: Color(0xFFFF8C00), // Dim orange for titles
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
          subtitle: TextStyle(
            color: Color(0xFFCCCCCC), // Light gray for subtitles
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
          header: TextStyle(
            color: Color(0xFFFF8C00), // Dim orange for headers
            fontSize: 32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      slides: _generateFlutterDeckSlides(),
      speakerInfo: const FlutterDeckSpeakerInfo(
        name: 'AhamAI',
        description: 'AI-Generated Presentation',
        socialHandle: '',
        imagePath: 'assets/images/avatar.png',
      ),
    );
  }

  List<FlutterDeckSlideWidget> _generateFlutterDeckSlides() {
    final List<FlutterDeckSlideWidget> deckSlides = [];

    for (int i = 0; i < slides.length; i++) {
      final slideContent = slides[i].trim();
      final lines = slideContent.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.isEmpty) continue;

      final title = lines.first;
      final content = lines.skip(1).toList();

      if (i == 0) {
        // Title slide
        deckSlides.add(
          FlutterDeckSlide.title(
            title: title,
            subtitle: content.isNotEmpty ? content.join(' ') : '',
          ),
        );
      } else if (i == slides.length - 1) {
        // Last slide - Thank you
        deckSlides.add(
          FlutterDeckSlide.title(
            title: title,
            subtitle: content.isNotEmpty ? content.join(' ') : 'Generated by AhamAI',
          ),
        );
      } else {
        // Content slide
        deckSlides.add(
          FlutterDeckSlide.split(
            leftBuilder: (context) => FlutterDeckBulletList(
              items: [title],
            ),
            rightBuilder: (context) => FlutterDeckBulletList(
              items: content.map((line) => line.replaceFirst('•', '').trim()).toList(),
            ),
          ),
        );
      }
    }

    return deckSlides;
  }
}