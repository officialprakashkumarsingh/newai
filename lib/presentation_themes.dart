import 'package:flutter/material.dart';

/// Intelligent Presentation Themes - Adapts themes based on topic and content
/// Provides multiple theme options with smart selection
class PresentationThemes {
  
  /// Theme categories mapped to keywords and content types
  static const Map<String, List<String>> themeKeywords = {
    'tech': ['technology', 'software', 'programming', 'coding', 'app', 'digital', 'ai', 'machine learning', 'data', 'algorithm', 'computer', 'internet', 'web', 'mobile', 'cloud', 'cybersecurity', 'blockchain', 'iot', 'automation'],
    'business': ['business', 'marketing', 'sales', 'finance', 'revenue', 'profit', 'strategy', 'management', 'leadership', 'corporate', 'company', 'startup', 'entrepreneur', 'investment', 'market', 'customer', 'growth', 'analytics'],
    'science': ['science', 'research', 'experiment', 'hypothesis', 'theory', 'physics', 'chemistry', 'biology', 'mathematics', 'formula', 'equation', 'analysis', 'methodology', 'results', 'conclusion', 'laboratory', 'study'],
    'education': ['education', 'learning', 'teaching', 'school', 'university', 'student', 'course', 'curriculum', 'knowledge', 'skills', 'training', 'academic', 'lecture', 'tutorial', 'workshop', 'lesson'],
    'medical': ['medical', 'health', 'healthcare', 'medicine', 'doctor', 'patient', 'treatment', 'diagnosis', 'therapy', 'clinical', 'hospital', 'pharmaceutical', 'wellness', 'disease', 'surgery', 'care'],
    'creative': ['design', 'art', 'creative', 'visual', 'graphic', 'photography', 'video', 'animation', 'brand', 'aesthetic', 'color', 'typography', 'layout', 'inspiration', 'artistic', 'portfolio'],
    'environment': ['environment', 'sustainability', 'green', 'ecology', 'climate', 'renewable', 'conservation', 'nature', 'earth', 'pollution', 'carbon', 'energy', 'eco', 'organic', 'biodiversity'],
    'finance': ['finance', 'financial', 'investment', 'banking', 'money', 'budget', 'cost', 'price', 'economic', 'market', 'trading', 'stock', 'portfolio', 'accounting', 'tax', 'wealth'],
  };
  
  /// Intelligent theme detection based on topic and content
  static String detectTheme(String topic, List<Map<String, dynamic>> slides) {
    final allText = topic.toLowerCase() + ' ' + 
        slides.map((slide) => _extractTextFromSlide(slide).toLowerCase()).join(' ');
    
    Map<String, int> themeScores = {};
    
    // Score each theme based on keyword matches
    for (String theme in themeKeywords.keys) {
      int score = 0;
      for (String keyword in themeKeywords[theme]!) {
        score += _countMatches(allText, keyword);
      }
      themeScores[theme] = score;
    }
    
    // Return theme with highest score, fallback to 'business'
    String bestTheme = themeScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return themeScores[bestTheme]! > 0 ? bestTheme : 'business';
  }
  
  /// Extract text content from a slide for theme detection
  static String _extractTextFromSlide(Map<String, dynamic> slide) {
    List<String> texts = [];
    
    texts.add(slide['title'] ?? '');
    texts.add(slide['subtitle'] ?? '');
    
    if (slide['content'] is List) {
      texts.addAll((slide['content'] as List).map((item) => item.toString()));
    }
    
    // Extract from different slide types
    switch (slide['type']) {
      case 'formula':
        texts.add(slide['explanation'] ?? '');
        break;
      case 'quote':
        texts.add(slide['quote'] ?? '');
        texts.add(slide['author'] ?? '');
        break;
      case 'scientific':
        texts.add(slide['hypothesis'] ?? '');
        texts.add(slide['methodology'] ?? '');
        texts.add(slide['conclusion'] ?? '');
        break;
      case 'financial':
        if (slide['metrics'] is List) {
          for (var metric in slide['metrics']) {
            texts.add(metric['label'] ?? '');
          }
        }
        break;
    }
    
    return texts.join(' ');
  }
  
  /// Count keyword matches in text
  static int _countMatches(String text, String keyword) {
    return RegExp(r'\b' + RegExp.escape(keyword) + r'\b').allMatches(text).length;
  }
  
  /// Get theme configuration for a detected theme
  static PresentationThemeData getThemeData(String themeName, BuildContext context) {
    switch (themeName) {
      case 'tech':
        return PresentationThemeData(
          name: 'Technology',
          primaryColor: const Color(0xFF1976D2), // Blue
          secondaryColor: const Color(0xFF42A5F5),
          backgroundColor: const Color(0xFFF8F9FA),
          textColor: const Color(0xFF212121),
          accentColor: const Color(0xFF4CAF50), // Green accent
          gradientColors: [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.slide,
          iconSet: 'tech',
        );
        
      case 'business':
        return PresentationThemeData(
          name: 'Business',
          primaryColor: const Color(0xFF37474F), // Blue Grey
          secondaryColor: const Color(0xFF546E7A),
          backgroundColor: const Color(0xFFFAFAFA),
          textColor: const Color(0xFF263238),
          accentColor: const Color(0xFFFF9800), // Orange accent
          gradientColors: [const Color(0xFF37474F), const Color(0xFF546E7A)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.fade,
          iconSet: 'business',
        );
        
      case 'science':
        return PresentationThemeData(
          name: 'Science',
          primaryColor: const Color(0xFF673AB7), // Deep Purple
          secondaryColor: const Color(0xFF9575CD),
          backgroundColor: const Color(0xFFF3E5F5),
          textColor: const Color(0xFF4A148C),
          accentColor: const Color(0xFF00BCD4), // Cyan accent
          gradientColors: [const Color(0xFF673AB7), const Color(0xFF9575CD)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.scale,
          iconSet: 'science',
        );
        
      case 'education':
        return PresentationThemeData(
          name: 'Education',
          primaryColor: const Color(0xFF388E3C), // Green
          secondaryColor: const Color(0xFF66BB6A),
          backgroundColor: const Color(0xFFF1F8E9),
          textColor: const Color(0xFF1B5E20),
          accentColor: const Color(0xFFFFC107), // Amber accent
          gradientColors: [const Color(0xFF388E3C), const Color(0xFF66BB6A)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.slide,
          iconSet: 'education',
        );
        
      case 'medical':
        return PresentationThemeData(
          name: 'Medical',
          primaryColor: const Color(0xFFD32F2F), // Red
          secondaryColor: const Color(0xFFEF5350),
          backgroundColor: const Color(0xFFFFF5F5),
          textColor: const Color(0xFFB71C1C),
          accentColor: const Color(0xFF2196F3), // Blue accent
          gradientColors: [const Color(0xFFD32F2F), const Color(0xFFEF5350)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.fade,
          iconSet: 'medical',
        );
        
      case 'creative':
        return PresentationThemeData(
          name: 'Creative',
          primaryColor: const Color(0xFFE91E63), // Pink
          secondaryColor: const Color(0xFFF06292),
          backgroundColor: const Color(0xFFFCE4EC),
          textColor: const Color(0xFF880E4F),
          accentColor: const Color(0xFF9C27B0), // Purple accent
          gradientColors: [const Color(0xFFE91E63), const Color(0xFFF06292), const Color(0xFF9C27B0)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.rotation,
          iconSet: 'creative',
        );
        
      case 'environment':
        return PresentationThemeData(
          name: 'Environment',
          primaryColor: const Color(0xFF2E7D32), // Dark Green
          secondaryColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFFE8F5E8),
          textColor: const Color(0xFF1B5E20),
          accentColor: const Color(0xFF8BC34A), // Light Green accent
          gradientColors: [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.slide,
          iconSet: 'environment',
        );
        
      case 'finance':
        return PresentationThemeData(
          name: 'Finance',
          primaryColor: const Color(0xFF1565C0), // Blue
          secondaryColor: const Color(0xFF42A5F5),
          backgroundColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF0D47A1),
          accentColor: const Color(0xFF4CAF50), // Green accent
          gradientColors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
          fontFamily: 'Roboto',
          slideTransition: PresentationTransition.slide,
          iconSet: 'finance',
        );
        
      default:
        return getThemeData('business', context); // Fallback to business theme
    }
  }
  
  /// Get all available themes
  static List<PresentationThemeData> getAllThemes(BuildContext context) {
    return themeKeywords.keys
        .map((themeName) => getThemeData(themeName, context))
        .toList();
  }
  
  /// Get icon for theme
  static IconData getThemeIcon(String themeName) {
    switch (themeName) {
      case 'tech': return Icons.computer;
      case 'business': return Icons.business;
      case 'science': return Icons.science;
      case 'education': return Icons.school;
      case 'medical': return Icons.medical_services;
      case 'creative': return Icons.palette;
      case 'environment': return Icons.eco;
      case 'finance': return Icons.account_balance;
      default: return Icons.slideshow;
    }
  }
}

/// Presentation theme data structure
class PresentationThemeData {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final List<Color> gradientColors;
  final String fontFamily;
  final PresentationTransition slideTransition;
  final String iconSet;
  
  const PresentationThemeData({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.gradientColors,
    required this.fontFamily,
    required this.slideTransition,
    required this.iconSet,
  });
  
  /// Create a gradient decoration for slides
  BoxDecoration createGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
  
  /// Create a themed text style
  TextStyle createTextStyle(double fontSize, {FontWeight? fontWeight, Color? color}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textColor,
      fontFamily: fontFamily,
    );
  }
  
  /// Create a themed card decoration
  BoxDecoration createCardDecoration() {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primaryColor.withOpacity(0.3)),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// Slide transition types
enum PresentationTransition {
  slide,
  fade,
  scale,
  rotation,
  none,
}

/// Theme-specific slide animations
class PresentationAnimations {
  
  /// Get animation widget based on theme transition
  static Widget wrapWithAnimation(
    Widget child, 
    SlideTransition transition, 
    Animation<double> animation,
  ) {
    switch (transition) {
      case PresentationTransition.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
        
      case PresentationTransition.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
        
      case PresentationTransition.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );
        
      case PresentationTransition.rotation:
        return RotationTransition(
          turns: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
        
      case PresentationTransition.none:
      default:
        return child;
    }
  }
}