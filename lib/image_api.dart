import 'api.dart' as RealApi;

/// Image API wrapper that uses the real API implementation
class ImageApi {
  /// Generate image using the real API
  static Future<String?> generateImage(String prompt, {String? model}) async {
    print('🔧 ImageApi.generateImage called:');
    print('   Prompt: $prompt');
    print('   Model: $model');
    
    try {
      print('📡 Calling RealApi.generateImage...');
      final result = await RealApi.generateImage(prompt, model: model);
      print('📸 RealApi response:');
      print('   Result: ${result != null ? '${result.substring(0, 50)}...' : 'null'}');
      print('   Type: ${result?.runtimeType}');
      print('   Is null: ${result == null}');
      print('   Length: ${result?.length}');
      return result;
    } catch (e, stackTrace) {
      print('❌ ImageApi.generateImage error: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch available image models from the real API
  static Future<List<String>> fetchModels() async {
    try {
      final models = await RealApi.fetchModels();
      return models;
    } catch (e) {
      print('ImageApi.fetchModels error: $e');
      return []; // Return empty list if API fails, let UI handle fallback
    }
  }
}