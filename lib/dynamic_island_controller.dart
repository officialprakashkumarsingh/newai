import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dynamic_island.dart';

class DynamicIslandController extends ChangeNotifier {
  static final DynamicIslandController _instance = DynamicIslandController._internal();
  factory DynamicIslandController() => _instance;
  DynamicIslandController._internal();

  DynamicIslandState _currentState = DynamicIslandState.compact;
  String? _currentContent;
  Timer? _stateTimer;
  Timer? _weatherTimer;
  Timer? _notificationTimer;

  // Live data
  String _weatherData = '24°C';
  String _batteryLevel = '85%';
  bool _isCharging = false;
  int _notificationCount = 0;
  String? _currentMusic;
  bool _isMusicPlaying = false;

  DynamicIslandState get currentState => _currentState;
  String? get currentContent => _currentContent;
  String get weatherData => _weatherData;
  String get batteryLevel => _batteryLevel;
  int get notificationCount => _notificationCount;

  void initialize() {
    _startWeatherUpdates();
    _startBatteryMonitoring();
    _startNotificationMonitoring();
  }

  // Voice Recording State
  void startVoiceRecording() {
    _setState(DynamicIslandState.voice, 'Recording voice...');
  }

  void stopVoiceRecording() {
    _setState(DynamicIslandState.processing, 'Processing voice...');
    
    // Auto return to compact after processing
    _scheduleStateChange(DynamicIslandState.compact, 3000);
  }

  // AI Processing State
  void startAIProcessing() {
    _setState(DynamicIslandState.processing, 'AI is thinking...');
  }

  void stopAIProcessing() {
    _setState(DynamicIslandState.compact);
  }

  // Notification State
  void showNotification(int count, {String? message}) {
    _notificationCount = count;
    _setState(DynamicIslandState.notification, message ?? 'New messages');
    
    // Auto collapse after 4 seconds
    _scheduleStateChange(DynamicIslandState.compact, 4000);
  }

  // Weather State
  void showWeather({String? weatherInfo}) {
    if (weatherInfo != null) {
      _weatherData = weatherInfo;
    }
    _setState(DynamicIslandState.weather, 'Weather update');
    
    // Auto collapse after 3 seconds
    _scheduleStateChange(DynamicIslandState.compact, 3000);
  }

  // Music State
  void showMusicPlaying(String songInfo) {
    _currentMusic = songInfo;
    _isMusicPlaying = true;
    _setState(DynamicIslandState.music, songInfo);
    
    // Auto collapse after 5 seconds
    _scheduleStateChange(DynamicIslandState.compact, 5000);
  }

  void stopMusic() {
    _isMusicPlaying = false;
    _currentMusic = null;
    _setState(DynamicIslandState.compact);
  }

  // Expanded State
  void showExpanded() {
    _setState(DynamicIslandState.expanded, 'Full status');
    
    // Auto collapse after 6 seconds
    _scheduleStateChange(DynamicIslandState.compact, 6000);
  }

  // Manual state control
  void forceCompact() {
    _cancelScheduledStateChange();
    _setState(DynamicIslandState.compact);
  }

  void _setState(DynamicIslandState state, [String? content]) {
    _currentState = state;
    _currentContent = content;
    notifyListeners();
  }

  void _scheduleStateChange(DynamicIslandState state, int delayMs) {
    _cancelScheduledStateChange();
    _stateTimer = Timer(Duration(milliseconds: delayMs), () {
      _setState(state);
    });
  }

  void _cancelScheduledStateChange() {
    _stateTimer?.cancel();
    _stateTimer = null;
  }

  // Live data monitoring
  void _startWeatherUpdates() {
    _updateWeather();
    _weatherTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _updateWeather();
    });
  }

  void _updateWeather() {
    // Simulate weather data updates
    final temps = ['22°C', '24°C', '26°C', '28°C', '23°C', '25°C'];
    final random = math.Random();
    _weatherData = temps[random.nextInt(temps.length)];
    
    // Occasionally show weather updates
    if (random.nextInt(10) == 0 && _currentState == DynamicIslandState.compact) {
      showWeather();
    }
  }

  void _startBatteryMonitoring() {
    _updateBattery();
    Timer.periodic(const Duration(minutes: 5), (_) {
      _updateBattery();
    });
  }

  void _updateBattery() {
    // Simulate battery level changes
    final random = math.Random();
    final level = 60 + random.nextInt(40); // 60-99%
    _batteryLevel = '$level%';
    
    // Show low battery warning
    if (level < 20 && _currentState == DynamicIslandState.compact) {
      _setState(DynamicIslandState.notification, 'Low battery: $level%');
      _scheduleStateChange(DynamicIslandState.compact, 3000);
    }
  }

  void _startNotificationMonitoring() {
    _notificationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _simulateNotifications();
    });
  }

  void _simulateNotifications() {
    final random = math.Random();
    if (random.nextInt(5) == 0 && _currentState == DynamicIslandState.compact) {
      final count = 1 + random.nextInt(5);
      showNotification(count);
    }
  }

  // Contextual state management
  void handleVoiceInteraction() {
    if (_currentState == DynamicIslandState.compact) {
      startVoiceRecording();
    }
  }

  void handleTap() {
    switch (_currentState) {
      case DynamicIslandState.compact:
        showExpanded();
        break;
      case DynamicIslandState.voice:
        stopVoiceRecording();
        break;
      case DynamicIslandState.processing:
        // Do nothing during processing
        break;
      case DynamicIslandState.notification:
        forceCompact();
        break;
      case DynamicIslandState.weather:
        forceCompact();
        break;
      case DynamicIslandState.music:
        forceCompact();
        break;
      case DynamicIslandState.expanded:
        forceCompact();
        break;
    }
  }

  void handleLongPress() {
    // Always show expanded view on long press
    showExpanded();
  }

  // Integration with app state
  void onAppStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background
        break;
      case AppLifecycleState.resumed:
        // App comes to foreground
        if (_currentState != DynamicIslandState.compact) {
          forceCompact();
        }
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    _weatherTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  // Utility methods for external integrations
  bool get isIdle => _currentState == DynamicIslandState.compact;
  bool get isActive => _currentState != DynamicIslandState.compact;
  bool get isVoiceActive => _currentState == DynamicIslandState.voice;
  bool get isProcessing => _currentState == DynamicIslandState.processing;

  // Demo methods for testing
  void demo() {
    Timer(const Duration(seconds: 2), () => startVoiceRecording());
    Timer(const Duration(seconds: 5), () => stopVoiceRecording());
    Timer(const Duration(seconds: 9), () => showNotification(3));
    Timer(const Duration(seconds: 14), () => showWeather(weatherInfo: '26°C'));
    Timer(const Duration(seconds: 18), () => showMusicPlaying('Playing: Kal Ho Naa Ho'));
    Timer(const Duration(seconds: 24), () => showExpanded());
  }
}