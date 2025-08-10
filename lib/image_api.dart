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
      return models.isNotEmpty ? models : ['flux-1-turbo']; // Fallback to known working model
    } catch (e) {
      print('ImageApi.fetchModels error: $e');
      return ['flux-1-turbo']; // Fallback model
    }
  }
}