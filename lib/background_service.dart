import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:convert';

class BackgroundService {
  static const String _channelName = 'com.ahamai.background';
  static const MethodChannel _methodChannel = MethodChannel(_channelName);
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  static String? _currentChatId;
  static String? _currentProcessType; // 'chat', 'image', 'presentation'
  
  static Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Initialize Workmanager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    
    // Set up method channel for native communication
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }
  
  static Future<void> startBackgroundProcess({
    required String chatId,
    required String processType,
    required Map<String, dynamic> processData,
  }) async {
    _currentChatId = chatId;
    _currentProcessType = processType;
    
    // Show ongoing notification
    await _showOngoingNotification(processType);
    
    // Register background task
    await Workmanager().registerOneOffTask(
      'ahamai_process_$chatId',
      'processTask',
      inputData: {
        'chatId': chatId,
        'processType': processType,
        'processData': processData,
      },
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    // Notify native side
    await _methodChannel.invokeMethod('startBackgroundProcess', {
      'chatId': chatId,
      'processType': processType,
    });
  }
  
  static Future<void> stopBackgroundProcess() async {
    await Workmanager().cancelByUniqueName('ahamai_process_${_currentChatId}');
    await _notificationsPlugin.cancel(1001); // Cancel ongoing notification
    
    _currentChatId = null;
    _currentProcessType = null;
  }
  
  static Future<void> processCompleted({
    required String chatId,
    required String processType,
    required String result,
  }) async {
    // Cancel ongoing notification
    await _notificationsPlugin.cancel(1001);
    
    // Show completion notification
    await _showCompletionNotification(processType, result);
    
    // Clean up
    _currentChatId = null;
    _currentProcessType = null;
  }
  
  static Future<void> _showOngoingNotification(String processType) async {
    String title = 'AhamAI Processing';
    String content = '';
    
    switch (processType) {
      case 'chat':
        content = 'Generating response...';
        break;
      case 'image':
        content = 'Creating image...';
        break;
      case 'presentation':
        content = 'Building presentation...';
        break;
      default:
        content = 'Processing your request...';
    }
    
    const androidDetails = AndroidNotificationDetails(
      'ahamai_ongoing',
      'AhamAI Ongoing Tasks',
      channelDescription: 'Shows ongoing AI processing tasks',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      indeterminate: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      1001, // Ongoing notification ID
      title,
      content,
      notificationDetails,
    );
  }
  
  static Future<void> _showCompletionNotification(String processType, String result) async {
    String title = 'AhamAI Complete!';
    String content = '';
    
    switch (processType) {
      case 'chat':
        content = 'Response ready - tap to view';
        break;
      case 'image':
        content = 'Image generated - tap to view';
        break;
      case 'presentation':
        content = 'Presentation ready - tap to view';
        break;
      default:
        content = 'Task completed - tap to view';
    }
    
    const androidDetails = AndroidNotificationDetails(
      'ahamai_complete',
      'AhamAI Completed Tasks',
      channelDescription: 'Shows when AI tasks are completed',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      autoCancel: true,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      1002, // Completion notification ID
      title,
      content,
      notificationDetails,
      payload: jsonEncode({
        'chatId': _currentChatId,
        'processType': processType,
        'action': 'open_chat',
      }),
    );
  }
  
  static Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      
      // Send to main app via method channel
      await _methodChannel.invokeMethod('notificationTapped', {
        'chatId': payload['chatId'],
        'processType': payload['processType'],
        'action': payload['action'],
      });
    }
  }
  
  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'processCompleted':
        await processCompleted(
          chatId: call.arguments['chatId'],
          processType: call.arguments['processType'],
          result: call.arguments['result'] ?? '',
        );
        break;
    }
  }
}

// Workmanager callback dispatcher (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs in the background
    // For now, we'll let the main app handle the actual processing
    // and just maintain the notification state
    return Future.value(true);
  });
}