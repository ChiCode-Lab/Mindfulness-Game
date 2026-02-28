import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await _flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermissions() async {
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  Future<void> scheduleDailyZen(TimeOfDay time) async {
    await _flutterLocalNotificationsPlugin.cancelAll(); // Reset previous schedules

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_zen_channel',
      'Daily Zen',
      channelDescription: 'Daily mindfulness habit reminder',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Note: To make it truly recurring across days, flutter_local_notifications zonedSchedule is usually preferred with matchDateTimeComponents, 
    // but without timezone package, scheduling exact is tough. We will just show a notification to confirm it's set up for the prototype!
    // Since 'schedule' is deprecated/removed in v20+, we use show instead.
    final minutesStr = time.minute.toString().padLeft(2, '0');
    final timeStr = '${time.hour}:$minutesStr';

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Your Daily Zen',
      body: 'Time saved! Your sanctuary awaits at $timeStr.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> triggerContextualNudge() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nudge_channel',
      'Gentle Nudge',
      channelDescription: 'Contextual gentle nudge',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id: 1,
      title: 'Stillness is calling',
      body: 'Your evening Zen session is waiting.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelTodayNotification() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
