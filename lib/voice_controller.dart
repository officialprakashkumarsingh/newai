import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  final SpeechToText _speechToText = SpeechToText();
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

    // Initialize speech to text
    bool available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );

    if (available) {
      // Initialize TTS
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _isInitialized = true;
      debugPrint('🎙️ Voice Controller initialized successfully!');
    }
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
    
    if (_speechToText.isAvailable && !_isListening) {
      _isListening = true;
      onListeningChanged?.call(true);
      
      await _flutterTts.speak("Listening...");
      
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _processVoiceCommand(result.recognizedWords);
            stopListening();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: false,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      onListeningChanged?.call(false);
    }
  }

  Future<void> _processVoiceCommand(String command) async {
    debugPrint('🎙️ Processing command: $command');
    final lowerCommand = command.toLowerCase();

    try {
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
      
      // Search Commands
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
      else if (lowerCommand.contains('turn on bluetooth')) {
        await _toggleBluetooth(true);
      }
      else if (lowerCommand.contains('turn off bluetooth')) {
        await _toggleBluetooth(false);
      }
      else if (lowerCommand.contains('take screenshot')) {
        await _takeScreenshot();
      }
      
      // Call Commands
      else if (lowerCommand.contains('call')) {
        final contact = _extractContactName(lowerCommand);
        await _makeCall(contact);
      }
      
      // Default: Chat with AhamAI
      else {
        onSpeechResult?.call(command);
        await _flutterTts.speak("Processing your request in AhamAI chat");
      }
      
    } catch (e) {
      debugPrint('❌ Error processing voice command: $e');
      await _flutterTts.speak("Sorry, I couldn't process that command");
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
      bool isInstalled = await DeviceApps.isAppInstalled(packageName);
      if (isInstalled) {
        await DeviceApps.openApp(packageName);
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

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}