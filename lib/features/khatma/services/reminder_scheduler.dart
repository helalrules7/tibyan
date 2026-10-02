import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';

/// A reminder with its text, ready to schedule.
typedef ReminderNotice = ({
  PlannedReminder plan,
  String title,
  String body,
  String payload,
});

/// Schedules the khatma reminders on the device.
abstract interface class ReminderScheduler {
  /// Replaces every scheduled khatma reminder with [notices].
  Future<void> replace(List<ReminderNotice> notices, {required String channel});

  /// Asks for permission to notify; false when refused.
  Future<bool> requestPermission();

  /// The payload of the reminder that opened the app, if one did.
  Future<String?> launchPayload();

  /// Called with a reminder's payload when it is tapped while the app runs.
  set onTap(void Function(String payload)? handler);
}

/// Does nothing: tests, and platforms without notifications.
class NoReminders implements ReminderScheduler {
  final replaced = <List<ReminderNotice>>[];

  @override
  Future<void> replace(
    List<ReminderNotice> notices, {
    required String channel,
  }) async => replaced.add(notices);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> launchPayload() async => null;

  @override
  set onTap(void Function(String payload)? handler) {}
}

/// flutter_local_notifications: one notification per day, scheduled ahead
/// for [reminderDaysAhead] days (iOS keeps at most 64 pending), inexact so
/// no exact-alarm permission is needed on Android.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  void Function(String payload)? _onTap;

  @override
  set onTap(void Function(String payload)? handler) => _onTap = handler;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // Unknown zone name: UTC offsets still follow the device's clock
      // closely enough for a daily reminder.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null) _onTap?.call(p);
      },
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true) ??
        false;
  }

  @override
  Future<String?> launchPayload() async {
    await _init();
    final d = await _plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true
        ? d?.notificationResponse?.payload
        : null;
  }

  @override
  Future<void> replace(
    List<ReminderNotice> notices, {
    required String channel,
  }) async {
    await _init();
    for (var i = 0; i < reminderDaysAhead; i++) {
      await _plugin.cancel(id: reminderIdBase + i);
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'app.tibyan.khatma',
        channel,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final n in notices) {
      await _plugin.zonedSchedule(
        id: n.plan.id,
        scheduledDate: tz.TZDateTime.from(n.plan.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: n.payload,
      );
    }
  }
}
