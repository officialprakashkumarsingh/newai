import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart'; // Temporarily disabled
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  // final SpeechToText _speechToText = SpeechToText(); // Temporarily disabled
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isInitialized = false;

  // Voice animation callback
  Function(bool)? onListeningChanged;
  Function(String)? onSpeechResult;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize speech to text - TEMPORARILY DISABLED
    // bool available = await _speechToText.initialize(
    //   onError: (error) => debugPrint('Speech error: $error'),
    //   onStatus: (status) => debugPrint('Speech status: $status'),
    // );

    // if (available) {
      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      debugPrint('🎙️ Voice Controller initialized successfully!');
    // }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.speech,
      Permission.phone,
      Permission.sms,
      Permission.location,
    ].request();
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    
    // TEMPORARILY DISABLED - Speech to text functionality
    // if (_speechToText.isAvailable && !_isListening) {
      _isListening = true;
      onListeningChanged?.call(true);
      
      await _flutterTts.speak("Speech recognition temporarily disabled...");
      
      // Simulate voice input for demonstration
      Future.delayed(const Duration(seconds: 2), () {
        _processVoiceCommand("Voice input simulated");
        stopListening();
      });
      
      // await _speechToText.listen(
      //   onResult: (result) {
      //     if (result.finalResult) {
      //       _processVoiceCommand(result.recognizedWords);
      //       stopListening();
      //     }
      //   },
      //   listenFor: const Duration(seconds: 10),
      //   pauseFor: const Duration(seconds: 2), // Reduced pause time
      //   cancelOnError: true,
      //   partialResults: false,
      // );
    // }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      // await _speechToText.stop(); // Temporarily disabled
      _isListening = false;
      onListeningChanged?.call(false);
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    debugPrint('🎙️ Voice input received: $command');
    
    // Simple mode - just pass the text to the callback, no command execution
    onSpeechResult?.call(command);
  }

  List<String> _parseMultipleTasks(String command) {
    // Split by common separators for multiple tasks
    final separators = [
      ' and then ',
      ' then ',
      ' and also ',
      ' also ',
      ' and ',
      ', ',
    ];
    
    String processedCommand = command.toLowerCase();
    List<String> tasks = [processedCommand];
    
    for (final separator in separators) {
      List<String> newTasks = [];
      for (final task in tasks) {
        newTasks.addAll(task.split(separator));
      }
      tasks = newTasks;
    }
    
    // Clean up tasks and filter out empty ones
    tasks = tasks
        .map((task) => task.trim())
        .where((task) => task.isNotEmpty && task.length > 3)
        .toList();
    
    debugPrint('🎯 Parsed ${tasks.length} tasks: $tasks');
    return tasks;
  }

  Future<void> _executeTask(String command) async {
    final lowerCommand = command.toLowerCase();
    
    // App Opening Commands
    if (lowerCommand.contains('open youtube')) {
      await _openApp('com.google.android.youtube', 'YouTube');
    } 
    else if (lowerCommand.contains('open whatsapp')) {
      await _openApp('com.whatsapp', 'WhatsApp');
    }
    else if (lowerCommand.contains('open camera')) {
      await _openApp('com.android.camera', 'Camera');
    }
    else if (lowerCommand.contains('open settings')) {
      await _openSystemSettings();
    }
    else if (lowerCommand.contains('open google')) {
      await _openApp('com.android.chrome', 'Google Chrome');
    }
    else if (lowerCommand.contains('open spotify')) {
      await _openApp('com.spotify.music', 'Spotify');
    }
    else if (lowerCommand.contains('open instagram')) {
      await _openApp('com.instagram.android', 'Instagram');
    }
    else if (lowerCommand.contains('open gmail')) {
      await _openApp('com.google.android.gm', 'Gmail');
    }
    else if (lowerCommand.contains('open maps')) {
      await _openApp('com.google.android.apps.maps', 'Google Maps');
    }
    else if (lowerCommand.contains('open calculator')) {
      await _openApp('com.google.android.calculator', 'Calculator');
    }
    
    // Search Commands with parallel processing
    else if (lowerCommand.contains('search') && lowerCommand.contains('youtube')) {
      final query = _extractSearchQuery(lowerCommand, 'youtube');
      await _searchOnYouTube(query);
    }
    else if (lowerCommand.contains('search') && lowerCommand.contains('google')) {
      final query = _extractSearchQuery(lowerCommand, 'google');
      await _searchOnGoogle(query);
    }
    else if (lowerCommand.contains('find') && lowerCommand.contains('maps')) {
      final location = _extractSearchQuery(lowerCommand, 'maps');
      await _openMapsLocation(location);
    }
    else if (lowerCommand.contains('play') && lowerCommand.contains('spotify')) {
      final song = _extractSearchQuery(lowerCommand, 'spotify');
      await _playOnSpotify(song);
    }
    
    // System Commands
    else if (lowerCommand.contains('turn on wifi') || lowerCommand.contains('enable wifi')) {
      await _toggleWifi(true);
    }
    else if (lowerCommand.contains('turn off wifi') || lowerCommand.contains('disable wifi')) {
      await _toggleWifi(false);
    }
    else if (lowerCommand.contains('turn on bluetooth') || lowerCommand.contains('enable bluetooth')) {
      await _toggleBluetooth(true);
    }
    else if (lowerCommand.contains('turn off bluetooth') || lowerCommand.contains('disable bluetooth')) {
      await _toggleBluetooth(false);
    }
    else if (lowerCommand.contains('take screenshot')) {
      await _takeScreenshot();
    }
    else if (lowerCommand.contains('increase brightness')) {
      await _adjustBrightness(true);
    }
    else if (lowerCommand.contains('decrease brightness')) {
      await _adjustBrightness(false);
    }
    else if (lowerCommand.contains('increase volume')) {
      await _adjustVolume(true);
    }
    else if (lowerCommand.contains('decrease volume')) {
      await _adjustVolume(false);
    }
    
    // Communication Commands
    else if (lowerCommand.contains('call')) {
      final contact = _extractContactName(lowerCommand);
      await _makeCall(contact);
    }
    else if (lowerCommand.contains('send message to') || lowerCommand.contains('text')) {
      final contact = _extractContactName(lowerCommand);
      await _sendMessage(contact);
    }
    
    // Smart Combinations
    else if (lowerCommand.contains('find') && lowerCommand.contains('call')) {
      await _findAndCall(lowerCommand);
    }
    else if (lowerCommand.contains('share') && lowerCommand.contains('screenshot')) {
      await _takeAndShareScreenshot();
    }
    
    // Default: Chat with AhamAI
    else {
      onSpeechResult?.call(command);
      // Don't speak for default commands when in parallel mode
    }
  }

  String _extractSearchQuery(String command, String platform) {
    final patterns = {
      'youtube': RegExp(r'search (.+) (?:on|in) youtube', caseSensitive: false),
      'google': RegExp(r'search (.+) (?:on|in) google', caseSensitive: false),
      'maps': RegExp(r'find (.+) (?:on|in) maps', caseSensitive: false),
      'spotify': RegExp(r'play (.+) (?:on|in) spotify', caseSensitive: false),
    };
    
    final match = patterns[platform]?.firstMatch(command);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractContactName(String command) {
    final match = RegExp(r'call (.+)', caseSensitive: false).firstMatch(command);
    return match?.group(1)?.trim() ?? '';
  }

  Future<void> _openApp(String packageName, String appName) async {
    try {
      final url = 'package:$packageName';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await _flutterTts.speak("Opening $appName");
      } else {
        await _flutterTts.speak("$appName is not installed");
      }
    } catch (e) {
      await _flutterTts.speak("Couldn't open $appName");
    }
  }

  Future<void> _searchOnYouTube(String query) async {
    if (query.isNotEmpty) {
      final url = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await _flutterTts.speak("Searching for $query on YouTube");
      }
    }
  }

  Future<void> _searchOnGoogle(String query) async {
    if (query.isNotEmpty) {
      final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await _flutterTts.speak("Searching for $query on Google");
      }
    }
  }

  Future<void> _openMapsLocation(String location) async {
    if (location.isNotEmpty) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        await _flutterTts.speak("Finding $location on Maps");
      }
    }
  }

  Future<void> _playOnSpotify(String song) async {
    if (song.isNotEmpty) {
      final url = 'spotify:search:${Uri.encodeComponent(song)}';
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          await _flutterTts.speak("Playing $song on Spotify");
        }
      } catch (e) {
        // Fallback to web Spotify
        final webUrl = 'https://open.spotify.com/search/${Uri.encodeComponent(song)}';
        if (await canLaunchUrl(Uri.parse(webUrl))) {
          await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      await launchUrl(Uri.parse('package:com.android.settings'), mode: LaunchMode.externalApplication);
      await _flutterTts.speak("Opening Settings");
    } catch (e) {
      await _flutterTts.speak("Couldn't open Settings");
    }
  }

  Future<void> _toggleWifi(bool enable) async {
    try {
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('toggleWifi', {'enable': enable});
      await _flutterTts.speak(enable ? "WiFi turned on" : "WiFi turned off");
    } catch (e) {
      await _flutterTts.speak("Couldn't ${enable ? 'enable' : 'disable'} WiFi");
    }
  }

  Future<void> _toggleBluetooth(bool enable) async {
    try {
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('toggleBluetooth', {'enable': enable});
      await _flutterTts.speak(enable ? "Bluetooth turned on" : "Bluetooth turned off");
    } catch (e) {
      await _flutterTts.speak("Couldn't ${enable ? 'enable' : 'disable'} Bluetooth");
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('takeScreenshot');
      await _flutterTts.speak("Screenshot taken");
    } catch (e) {
      await _flutterTts.speak("Couldn't take screenshot");
    }
  }

  Future<void> _makeCall(String contact) async {
    if (contact.isNotEmpty) {
      try {
        final url = 'tel:$contact';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          await _flutterTts.speak("Calling $contact");
        }
      } catch (e) {
        await _flutterTts.speak("Couldn't make call");
      }
    }
  }

  // Advanced parallel functions
  Future<void> _adjustBrightness(bool increase) async {
    try {
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('adjustBrightness', {'increase': increase});
      await _flutterTts.speak(increase ? "Brightness increased" : "Brightness decreased");
    } catch (e) {
      await _flutterTts.speak("Couldn't adjust brightness");
    }
  }

  Future<void> _adjustVolume(bool increase) async {
    try {
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('adjustVolume', {'increase': increase});
      await _flutterTts.speak(increase ? "Volume increased" : "Volume decreased");
    } catch (e) {
      await _flutterTts.speak("Couldn't adjust volume");
    }
  }

  Future<void> _sendMessage(String contact) async {
    if (contact.isNotEmpty) {
      try {
        final url = 'sms:$contact';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
          await _flutterTts.speak("Opening message to $contact");
        }
      } catch (e) {
        await _flutterTts.speak("Couldn't open messaging");
      }
    }
  }

  Future<void> _findAndCall(String command) async {
    // Extract business/place name from command like "find pizza place and call them"
    final businessMatch = RegExp(r'find (.+?) (?:and|then)', caseSensitive: false).firstMatch(command);
    if (businessMatch != null) {
      final business = businessMatch.group(1)?.trim() ?? '';
      
      // First, search on Google Maps
      await _openMapsLocation(business);
      
      // Wait a moment for maps to load, then provide guidance
      await Future.delayed(const Duration(seconds: 2));
      await _flutterTts.speak("Found $business on maps. You can tap the business to see contact details and call.");
    }
  }

  Future<void> _takeAndShareScreenshot() async {
    try {
      // Take screenshot first
      await _takeScreenshot();
      
      // Wait a moment, then open share dialog
      await Future.delayed(const Duration(seconds: 1));
      
      const platform = MethodChannel('com.ahamai.system_control');
      await platform.invokeMethod('shareLastScreenshot');
      await _flutterTts.speak("Screenshot taken and ready to share");
    } catch (e) {
      await _flutterTts.speak("Couldn't take and share screenshot");
    }
  }

  // Smart command combinations for complex parallel tasks
  Future<void> executeComplexCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    // Smart restaurant finder: "Find pizza near me, get directions, and call them"
    if (lowerCommand.contains('find') && lowerCommand.contains('near me') && 
        (lowerCommand.contains('directions') || lowerCommand.contains('call'))) {
      await _smartRestaurantFinder(lowerCommand);
    }
    
    // Social media combo: "Take screenshot and share on Instagram and WhatsApp"
    else if (lowerCommand.contains('screenshot') && lowerCommand.contains('share') && 
             (lowerCommand.contains('instagram') || lowerCommand.contains('whatsapp'))) {
      await _smartSocialShare(lowerCommand);
    }
    
    // Entertainment combo: "Play music on Spotify and open YouTube for videos"
    else if (lowerCommand.contains('play music') && lowerCommand.contains('youtube')) {
      await _smartEntertainmentMode(lowerCommand);
    }
  }

  Future<void> _smartRestaurantFinder(String command) async {
    // Extract restaurant type
    final restaurantMatch = RegExp(r'find (.+?) near me', caseSensitive: false).firstMatch(command);
    final restaurantType = restaurantMatch?.group(1)?.trim() ?? 'restaurant';
    
    // Parallel execution
    final futures = <Future>[];
    
    // 1. Open Maps with search
    futures.add(_openMapsLocation('$restaurantType near me'));
    
    // 2. Also search on Google for options
    futures.add(_searchOnGoogle('$restaurantType near me phone number'));
    
    // 3. Enable location if needed
    if (command.contains('directions')) {
      futures.add(Future.delayed(const Duration(seconds: 1), () async {
        await _flutterTts.speak("Getting directions ready");
      }));
    }
    
    await Future.wait(futures);
    await _flutterTts.speak("Found $restaurantType options with contact details");
  }

  Future<void> _smartSocialShare(String command) async {
    // Take screenshot first
    await _takeScreenshot();
    
    // Parse which platforms to share to
    final platforms = <Future>[];
    
    if (command.contains('instagram')) {
      platforms.add(_openApp('com.instagram.android', 'Instagram'));
    }
    
    if (command.contains('whatsapp')) {
      platforms.add(_openApp('com.whatsapp', 'WhatsApp'));
    }
    
    if (command.contains('twitter') || command.contains('x')) {
      platforms.add(_openApp('com.twitter.android', 'X (Twitter)'));
    }
    
    // Wait for screenshot, then open platforms
    await Future.delayed(const Duration(seconds: 1));
    await Future.wait(platforms);
    await _flutterTts.speak("Screenshot ready to share on social media");
  }

  Future<void> _smartEntertainmentMode(String command) async {
    final futures = <Future>[];
    
    // Parse music request
    if (command.contains('spotify')) {
      final songMatch = RegExp(r'play (.+?) (?:on|and)', caseSensitive: false).firstMatch(command);
      final song = songMatch?.group(1)?.trim() ?? 'music';
      futures.add(_playOnSpotify(song));
    }
    
    // Parse video request  
    if (command.contains('youtube')) {
      final videoMatch = RegExp(r'youtube (?:for )?(.+)', caseSensitive: false).firstMatch(command);
      final video = videoMatch?.group(1)?.trim() ?? 'videos';
      futures.add(_searchOnYouTube(video));
    }
    
    await Future.wait(futures);
    await _flutterTts.speak("Entertainment mode activated!");
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}