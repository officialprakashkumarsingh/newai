import 'package:flutter/material.dart';
import 'presentation_shimmer.dart';

/// Shimmer effects for different feature loading states
class FeatureShimmer {
  
  /// Image generation shimmer
  static Widget buildImageGenerationShimmer(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          PresentationShimmer(
            child: Container(
              width: 150,
              height: 16,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Image placeholder shimmer
          PresentationShimmer(
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: highlightColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: highlightColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Status text shimmer
          PresentationShimmer(
            child: Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Diagram generation shimmer
  static Widget buildDiagramGenerationShimmer(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title shimmer
          PresentationShimmer(
            child: Container(
              width: 160,
              height: 16,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Diagram placeholder shimmer with chart-like structure
          PresentationShimmer(
            child: Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: highlightColor),
              ),
              child: Column(
                children: [
                  // Chart header
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Chart bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) => Container(
                        width: 30,
                        height: 80 + (index * 20).toDouble(),
                        decoration: BoxDecoration(
                          color: highlightColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      )),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Chart labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) => Container(
                      width: 25,
                      height: 10,
                      decoration: BoxDecoration(
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Status text shimmer
          PresentationShimmer(
            child: Container(
              width: 200,
              height: 12,
              decoration: BoxDecoration(
                color: highlightColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Generic loading shimmer for any feature
  static Widget buildGenericFeatureShimmer(BuildContext context, {
    String? title,
    double height = 150,
    Widget? customContent,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color baseColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final Color highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            PresentationShimmer(
              child: Container(
                width: title.length * 8.0,
                height: 16,
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          PresentationShimmer(
            child: customContent ?? Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: highlightColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status text shimmer for feature loading
class FeatureStatusShimmer extends StatelessWidget {
  final String feature;
  
  const FeatureStatusShimmer({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white70 : Colors.grey.shade700;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        'Generating $feature with AI...',
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}