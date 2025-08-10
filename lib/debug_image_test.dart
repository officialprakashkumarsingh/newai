import 'image_api.dart';
import 'api.dart' as RealApi;

/// Debug class to test image generation
class DebugImageTest {
  
  /// Test image generation with debug output
  static Future<void> testImageGeneration() async {
    print('🔍 Starting image generation debug test...');
    
    try {
      // Test 1: Check available models
      print('📋 Fetching available models...');
      final models = await ImageApi.fetchModels();
      print('✅ Available models: $models');
      
      if (models.isEmpty) {
        print('❌ No models available, testing with real API...');
        final realModels = await RealApi.ImageApi.fetchModels();
        print('🔧 Real API models: $realModels');
      }
      
      // Test 2: Try generating image with first available model
      final testModel = models.isNotEmpty ? models.first : 'uncen';
      print('🎨 Testing image generation with model: $testModel');
      
      final imageUrl = await ImageApi.generateImage(
        'a simple test image',
        model: testModel,
      );
      
      print('📸 Image generation result:');
      print('   URL: $imageUrl');
      print('   Type: ${imageUrl?.runtimeType}');
      print('   Length: ${imageUrl?.length}');
      print('   Is null: ${imageUrl == null}');
      print('   Is empty: ${imageUrl?.isEmpty}');
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        print('✅ Image generation successful!');
        if (imageUrl.startsWith('data:')) {
          print('📊 Response type: Base64 data URL');
          print('📏 Data URL length: ${imageUrl.length}');
        } else if (imageUrl.startsWith('http')) {
          print('📊 Response type: HTTP URL');
          print('🔗 URL: $imageUrl');
        } else {
          print('📊 Response type: Unknown format');
        }
      } else {
        print('❌ Image generation failed - null or empty result');
      }
      
    } catch (e, stackTrace) {
      print('❌ Image generation test failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
    
    print('🏁 Image generation debug test completed.');
  }
  
  /// Test real API directly
  static Future<void> testRealAPI() async {
    print('🔍 Testing real API directly...');
    
    try {
      final imageUrl = await RealApi.ImageApi.generateImage(
        'a cute puppy',
        model: 'uncen',
      );
      
      print('📸 Real API result: $imageUrl');
      
    } catch (e) {
      print('❌ Real API test failed: $e');
    }
  }
}