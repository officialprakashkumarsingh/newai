import 'api.dart' as RealApi;

/// Image API wrapper that uses the real API implementation
class ImageApi {
  /// Generate image using the real API
  static Future<String?> generateImage(String prompt, {String? model}) async {
    try {
      return await RealApi.ImageApi.generateImage(prompt, model: model);
    } catch (e) {
      print('ImageApi.generateImage error: $e');
      return null;
    }
  }

  /// Fetch available image models from the real API
  static Future<List<String>> fetchModels() async {
    try {
      final models = await RealApi.ImageApi.fetchModels();
      // Filter to only include working models based on testing
      final workingModels = models.where((model) => 
        ['flux', 'turbo', 'uncen', 'gemini2.0'].contains(model)
      ).toList();
      return workingModels.isNotEmpty ? workingModels : ['flux', 'turbo']; // Fallback to working models
    } catch (e) {
      print('ImageApi.fetchModels error: $e');
      return ['flux', 'turbo']; // Fallback to known working models
    }
  }
}