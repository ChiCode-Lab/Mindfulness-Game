import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'check_zen_habit') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastMeditatedStr = prefs.getString('last_meditated_date');
        
        bool needsNudge = true;
        
        if (lastMeditatedStr != null) {
          final lastDate = DateTime.tryParse(lastMeditatedStr);
          if (lastDate != null) {
            final now = DateTime.now();
            final diff = now.difference(lastDate).inHours;
            
            // If meditated in the last 12 hours, they probably don't need a nudge right now
            if (diff < 12) {
              needsNudge = false;
            }
          }
        }
        
        if (needsNudge) {
          final notifService = NotificationService();
          await notifService.init();
          await notifService.triggerContextualNudge();
        }
      } catch (e) {
        // Exception in background task
      }
    }
    return Future.value(true);
  });
}

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  Future<void> init() async {
    if (!kIsWeb) {
      await Workmanager().initialize(
        callbackDispatcher,
      );
    }
  }

  void registerDynamicNudge() {
    if (!kIsWeb) {
      Workmanager().registerPeriodicTask(
        'zen_nudge_task',
        'check_zen_habit',
        frequency: const Duration(hours: 6), // Check every 6 hours
        initialDelay: const Duration(hours: 2), // Start checking in 2 hours
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );
    }
  }
}
