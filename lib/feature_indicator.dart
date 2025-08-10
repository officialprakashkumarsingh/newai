import 'package:flutter/material.dart';
import 'image_api.dart';

/// Feature indicator widget that shows above input when a generation feature is active
class FeatureIndicator extends StatelessWidget {
  final String featureType;
  final VoidCallback onClose;
  final Widget? settingsWidget;

  const FeatureIndicator({
    super.key,
    required this.featureType,
    required this.onClose,
    this.settingsWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final featureInfo = _getFeatureInfo(featureType);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.grey.shade800.withOpacity(0.9)
            : Colors.grey.shade100.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Feature icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: featureInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              featureInfo.icon,
              color: featureInfo.color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Feature name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  featureInfo.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  featureInfo.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings widget if provided
          if (settingsWidget != null) ...[
            const SizedBox(width: 8),
            settingsWidget!,
            const SizedBox(width: 8),
          ],
          
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.grey.shade700
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _FeatureInfo _getFeatureInfo(String featureType) {
    switch (featureType) {
      case 'image':
        return _FeatureInfo(
          title: 'Image Generation',
          description: 'Generate images with AI',
          icon: Icons.image_outlined,
          color: Colors.purple,
        );
      case 'presentation':
        return _FeatureInfo(
          title: 'Presentation Generation',
          description: 'Create slide presentations',
          icon: Icons.slideshow_outlined,
          color: Colors.blue,
        );
      case 'diagram':
        return _FeatureInfo(
          title: 'Diagram Generation',
          description: 'Create charts and diagrams',
          icon: Icons.account_tree_outlined,
          color: Colors.green,
        );
      default:
        return _FeatureInfo(
          title: 'Feature Active',
          description: 'Generation mode enabled',
          icon: Icons.auto_fix_high,
          color: Colors.orange,
        );
    }
  }
}

class _FeatureInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _FeatureInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Settings widgets for different features
class ImageGenerationSettings extends StatefulWidget {
  final String selectedModel;
  final ValueChanged<String> onModelChanged;

  const ImageGenerationSettings({
    super.key,
    required this.selectedModel,
    required this.onModelChanged,
  });

  @override
  State<ImageGenerationSettings> createState() => _ImageGenerationSettingsState();
}

class _ImageGenerationSettingsState extends State<ImageGenerationSettings> {
  List<String> _availableModels = ['dall-e-3']; // Default fallback
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchImageModels();
  }

  Future<void> _fetchImageModels() async {
    try {
      // Import the ImageApi
      final models = await ImageApi.fetchModels();
      if (mounted) {
        setState(() {
          _availableModels = models.isNotEmpty ? models : ['dall-e-3'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableModels = ['dall-e-3', 'dall-e-2'];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        value: _availableModels.contains(widget.selectedModel) 
            ? widget.selectedModel 
            : _availableModels.first,
        isDense: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black87,
        ),
        items: _availableModels.map((model) {
          return DropdownMenuItem(
            value: model,
            child: Text(_getModelDisplayName(model)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) widget.onModelChanged(value);
        },
      ),
    );
  }

  String _getModelDisplayName(String model) {
    switch (model) {
      case 'dall-e-3':
        return 'DALL-E 3';
      case 'dall-e-2':
        return 'DALL-E 2';
      default:
        return model.toUpperCase();
    }
  }
}

