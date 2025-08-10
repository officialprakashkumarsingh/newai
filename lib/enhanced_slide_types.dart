import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation_themes.dart';

/// Enhanced Slide Types - Additional slide types for better presentations
class EnhancedSlideTypes {
  
  /// Build a code slide with syntax highlighting
  static Widget buildCodeSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final String code = slide['code'] ?? '';
    final String language = slide['language'] ?? 'dart';
    final String explanation = slide['explanation'] ?? '';
    
    double fontSize = isPreview ? 8 : 14;
    double titleSize = isPreview ? 12 : 24;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        // Code block
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // VS Code dark theme
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: padding / 2),
                  
                  // Code content
                  SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: fontSize,
                      color: const Color(0xFF4FC3F7), // Light blue for code
                      height: 1.4,
                    ),
                  ),
                  
                  // Copy button
                  if (!isPreview) ...[
                    SizedBox(height: padding / 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Code copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        // Explanation
        if (explanation.isNotEmpty) ...[
          SizedBox(height: padding),
          Text(
            explanation,
            style: theme.createTextStyle(fontSize * 1.1),
          ),
        ],
      ],
    );
  }
  
  /// Build an image slide with caption
  static Widget buildImageSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final String imageUrl = slide['image_url'] ?? '';
    final String caption = slide['caption'] ?? '';
    final String description = slide['description'] ?? '';
    
    double titleSize = isPreview ? 12 : 24;
    double fontSize = isPreview ? 10 : 16;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        // Image container
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(theme, isPreview),
                    ),
                  )
                : _buildImagePlaceholder(theme, isPreview),
          ),
        ),
        
        // Caption and description
        if (caption.isNotEmpty || description.isNotEmpty) ...[
          SizedBox(height: padding),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty) ...[
                  Text(
                    caption,
                    style: theme.createTextStyle(fontSize * 1.2, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: padding / 2),
                ],
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: theme.createTextStyle(fontSize),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  /// Build image placeholder
  static Widget _buildImagePlaceholder(PresentationThemeData theme, bool isPreview) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: isPreview ? 30 : 60,
            color: theme.primaryColor.withOpacity(0.5),
          ),
          SizedBox(height: isPreview ? 4 : 8),
          Text(
            'Image Placeholder',
            style: theme.createTextStyle(isPreview ? 8 : 14, color: theme.primaryColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
  
  /// Build a split content slide (two columns)
  static Widget buildSplitSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final Map<String, dynamic> leftSection = slide['left_section'] ?? {};
    final Map<String, dynamic> rightSection = slide['right_section'] ?? {};
    
    double titleSize = isPreview ? 12 : 24;
    double fontSize = isPreview ? 10 : 16;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        Expanded(
          child: Row(
            children: [
              // Left section
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: _buildSectionContent(leftSection, theme, fontSize, isPreview),
                ),
              ),
              
              SizedBox(width: padding),
              
              // Right section
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: theme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.secondaryColor.withOpacity(0.3)),
                  ),
                  child: _buildSectionContent(rightSection, theme, fontSize, isPreview),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build section content for split slides
  static Widget _buildSectionContent(Map<String, dynamic> section, PresentationThemeData theme, double fontSize, bool isPreview) {
    final String title = section['title'] ?? '';
    final List<dynamic> content = section['content'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: theme.createTextStyle(fontSize * 1.3, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: fontSize),
        ],
        
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((item) => Padding(
                padding: EdgeInsets.only(bottom: fontSize / 2),
                child: Text(
                  item.toString(),
                  style: theme.createTextStyle(fontSize),
                ),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Build a video slide placeholder
  static Widget buildVideoSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final String videoUrl = slide['video_url'] ?? '';
    final String description = slide['description'] ?? '';
    final int duration = slide['duration'] ?? 0;
    
    double titleSize = isPreview ? 12 : 24;
    double fontSize = isPreview ? 10 : 16;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        // Video placeholder
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: isPreview ? 30 : 60,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: padding),
                Text(
                  'Video Content',
                  style: theme.createTextStyle(fontSize * 1.2, color: Colors.white),
                ),
                if (duration > 0) ...[
                  SizedBox(height: padding / 2),
                  Text(
                    '${duration ~/ 60}:${(duration % 60).toString().padLeft(2, '0')}',
                    style: theme.createTextStyle(fontSize, color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Description
        if (description.isNotEmpty) ...[
          SizedBox(height: padding),
          Expanded(
            flex: 1,
            child: Text(
              description,
              style: theme.createTextStyle(fontSize),
            ),
          ),
        ],
      ],
    );
  }
  
  /// Build an interactive slide with clickable elements
  static Widget buildInteractiveSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final List<dynamic> elements = slide['elements'] ?? [];
    
    double titleSize = isPreview ? 12 : 24;
    double fontSize = isPreview ? 10 : 16;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPreview ? 2 : 3,
              crossAxisSpacing: padding,
              mainAxisSpacing: padding,
              childAspectRatio: 1.5,
            ),
            itemCount: elements.length,
            itemBuilder: (context, index) {
              final element = elements[index];
              return _buildInteractiveElement(element, theme, fontSize, isPreview, context);
            },
          ),
        ),
      ],
    );
  }
  
  /// Build individual interactive element
  static Widget _buildInteractiveElement(Map<String, dynamic> element, PresentationThemeData theme, double fontSize, bool isPreview, BuildContext context) {
    final String title = element['title'] ?? '';
    final String type = element['type'] ?? 'button';
    final String action = element['action'] ?? '';
    
    return Container(
      decoration: theme.createCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isPreview ? null : () => _handleInteractiveAction(action, context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getInteractiveIcon(type),
                  size: isPreview ? 20 : 40,
                  color: theme.primaryColor,
                ),
                SizedBox(height: fontSize / 2),
                Text(
                  title,
                  style: theme.createTextStyle(fontSize, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get icon for interactive element type
  static IconData _getInteractiveIcon(String type) {
    switch (type) {
      case 'link': return Icons.link;
      case 'download': return Icons.download;
      case 'video': return Icons.play_circle;
      case 'quiz': return Icons.quiz;
      case 'feedback': return Icons.feedback;
      case 'share': return Icons.share;
      default: return Icons.touch_app;
    }
  }
  
  /// Handle interactive element actions
  static void _handleInteractiveAction(String action, BuildContext context) {
    if (action.startsWith('http')) {
      // Launch URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Would open: $action')),
      );
    } else {
      // Other actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Interactive action: $action')),
      );
    }
  }
  
  /// Build a mind map slide
  static Widget buildMindMapSlide(Map<String, dynamic> slide, BuildContext context, bool isPreview, PresentationThemeData theme) {
    final String slideTitle = slide['title'] ?? '';
    final String centralTopic = slide['central_topic'] ?? '';
    final List<dynamic> branches = slide['branches'] ?? [];
    
    double titleSize = isPreview ? 12 : 24;
    double fontSize = isPreview ? 8 : 14;
    double padding = isPreview ? 8 : 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (slideTitle.isNotEmpty) ...[
          Text(
            slideTitle,
            style: theme.createTextStyle(titleSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: padding),
        ],
        
        Expanded(
          child: Stack(
            children: [
              // Central topic
              Center(
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    centralTopic,
                    style: theme.createTextStyle(
                      fontSize * 1.2, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Branches
              ...branches.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> branch = entry.value;
                return _buildMindMapBranch(branch, index, branches.length, theme, fontSize, isPreview);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build mind map branch
  static Widget _buildMindMapBranch(Map<String, dynamic> branch, int index, int total, PresentationThemeData theme, double fontSize, bool isPreview) {
    final String title = branch['title'] ?? '';
    final double angle = (2 * 3.14159 * index) / total;
    final double radius = isPreview ? 60 : 120;
    
    return Positioned(
      left: 200 + radius * (1.5 * cos(angle)) - 40,
      top: 100 + radius * sin(angle) - 20,
      child: Container(
        width: 80,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.secondaryColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor),
        ),
        child: Center(
          child: Text(
            title,
            style: theme.createTextStyle(fontSize * 0.9, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}