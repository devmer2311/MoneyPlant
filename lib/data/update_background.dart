import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:workmanager/workmanager.dart';

import 'update_service.dart';

const updateTask = 'money_plant.daily_update';
const updateNotificationId = 2100;
bool get backgroundUpdatesSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

@pragma('vm:entry-point')
void updateDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task != updateTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final storage = LocalUpdateStorage();
      if (await storage.read('enabled') == 'false') return true;
      final info = await PackageInfo.fromPlatform();
      await UpdateService(storage).notifyIfNew(info.version, (release) async {
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_stat_plant'),
          ),
        );
        final android = plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (await android?.areNotificationsEnabled() != true) return false;
        await plugin.show(
          id: updateNotificationId,
          title: 'New version v${release.version} is ready 🌱',
          body: 'Tap to see what’s ready and update Money Plant.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'app_updates_v1',
              'App updates',
              channelDescription: 'New Money Plant releases',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          payload: 'app-update',
        );
        return true;
      });
    } catch (_) {
      // Best effort: offline, API and OS failures never interrupt the user.
    }
    return true;
  });
}

Future<void> scheduleUpdateChecks(bool enabled) async {
  if (!backgroundUpdatesSupported) return;
  await Workmanager().initialize(updateDispatcher);
  if (!enabled) {
    await Workmanager().cancelByUniqueName(updateTask);
    await FlutterLocalNotificationsPlugin().cancel(id: updateNotificationId);
    return;
  }
  await Workmanager().registerPeriodicTask(
    updateTask,
    updateTask,
    frequency: const Duration(days: 1),
    initialDelay: const Duration(days: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
