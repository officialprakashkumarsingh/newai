class ImageApi {
  static Future<String?> generateImage(String prompt, {String? model}) async {
    // Stub implementation - return null for now
    await Future.delayed(const Duration(seconds: 2));
    return null;
  }

  static Future<List<String>> fetchModels() async {
    try {
      // Try to fetch from API - if fails, return default models
      // This would call the actual API endpoint for image models
      // For now, return the known image generation models
      return ['dall-e-3', 'dall-e-2'];
    } catch (e) {
      // Fallback to default models if API fails
      return ['dall-e-3', 'dall-e-2'];
    }
  }
}