import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/reminders.dart';
import 'reminder_image_stub.dart' if (dart.library.io) 'reminder_image_io.dart';

abstract class ReminderGateway {
  bool get supported;
  Future<void> initialize(void Function(String) onTap);
  Future<bool> permission({bool request = false});
  Future<void> refreshTimezone();
  Future<void> schedule(PlannedReminder reminder);
  Future<void> cancel(int id);
  Future<void> show(int id, ReminderCopy copy);
}

class AndroidReminderGateway implements ReminderGateway {
  final plugin = FlutterLocalNotificationsPlugin();
  String imagePath = '';
  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  Future<void> initialize(void Function(String) onTap) async {
    tzdata.initializeTimeZones();
    if (!supported) return;
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_plant'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap(response.payload ?? 'home'),
    );
    await refreshTimezone();
    imagePath = await prepareReminderImage();
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      onTap(launch?.notificationResponse?.payload ?? 'home');
    }
  }

  @override
  Future<void> refreshTimezone() async {
    if (!supported) return;
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  }

  @override
  Future<bool> permission({bool request = false}) async {
    if (!supported) return false;
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!;
    return (request
            ? await android.requestNotificationsPermission()
            : await android.areNotificationsEnabled()) ??
        false;
  }

  NotificationDetails details(ReminderCopy copy) => NotificationDetails(
    android: AndroidNotificationDetails(
      'garden_nudges_v1',
      'Garden nudges',
      channelDescription: 'Expense check-ins, savings, splits and budget care',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      visibility: NotificationVisibility.private,
      styleInformation: BigPictureStyleInformation(
        FilePathAndroidBitmap(imagePath),
        contentTitle: copy.title,
        summaryText: copy.body,
      ),
    ),
  );
  @override
  Future<void> schedule(PlannedReminder reminder) => plugin.zonedSchedule(
    id: reminder.id,
    title: reminder.copy.title,
    body: reminder.copy.body,
    scheduledDate: reminder.date,
    notificationDetails: details(reminder.copy),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: reminder.repeat == ReminderRepeat.monthly
        ? DateTimeComponents.dayOfMonthAndTime
        : DateTimeComponents.dayOfWeekAndTime,
    payload: reminder.copy.destination,
  );
  @override
  Future<void> cancel(int id) => plugin.cancel(id: id);
  @override
  Future<void> show(int id, ReminderCopy copy) => plugin.show(
    id: id,
    title: copy.title,
    body: copy.body,
    notificationDetails: details(copy),
    payload: copy.destination,
  );
}
