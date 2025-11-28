import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../Model/medicine.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    _navigatorKey = navKey;
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && _navigatorKey?.currentState != null) {
          _navigatorKey!.currentState!.pushNamed(
            '/alarm',
            arguments: details.payload,
          );
        }
      },
    );
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // --- Helper to show simple confirmation notification ---
  static Future<void> showConfirmationNotification(
      String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'med_confirmation_channel',
      'Medicine Status',
      channelDescription: 'Confirmations for taken/skipped meds',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
    );
  }

  // --- NEW: SNOOZE FUNCTION ---
  static Future<void> scheduleSnoozeNotification(String payload,
      {int minutes = 5}) async {
    try {
      // 1. Calculate time (Current time + 5 minutes)
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = now.add(Duration(minutes: minutes));

      // 2. Configure Notification Details
      // We use a specific channel for snoozes to ensure it rings loudly
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'med_snooze_channel', // Channel ID
        'Snooze Alarms', // Channel Name
        channelDescription: 'Channel for Medicine Alarms (Snoozed)',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(
            'tone1'), // Default sound for snooze
        fullScreenIntent: true, // CRITICAL: Opens the AlarmScreen
        autoCancel: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
            sound: 'tone1.wav',
            interruptionLevel: InterruptionLevel.timeSensitive),
      );

      // 3. Schedule
      await _notificationsPlugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        'Snooze: Medicine Time!',
        'It is time to take your medicine (Snoozed)',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload:
            payload, // Pass the same data back so the screen populates correctly
      );
      print("Snooze scheduled for 5 minutes from now.");
    } catch (e) {
      print("Error scheduling snooze: $e");
    }
  }

  static Future<void> scheduleMedicineReminder(Medicine medicine,
      [String? ringtone]) async {
    try {
      String cleanedTime = medicine.time.replaceAll(RegExp(r'\s+'), ' ').trim();
      final timeParts = cleanedTime.split(" ");
      final hm = timeParts[0].split(":");
      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);
      final amPm = timeParts[1].toUpperCase();

      if (amPm == "PM" && hour != 12) hour += 12;
      if (amPm == "AM" && hour == 12) hour = 0;

      String soundFileName = "tone1";
      if (ringtone != null) {
        String normalized = ringtone.toLowerCase().trim();
        if (normalized.contains("tone 1"))
          soundFileName = "tone1";
        else if (normalized.contains("tone 2"))
          soundFileName = "tone2";
        else if (normalized.contains("tone 3"))
          soundFileName = "tone3";
        else if (normalized.contains("tone 4")) soundFileName = "tone4";
      }

      StyleInformation? styleInformation;
      if (medicine.photo != null && medicine.photo!.isNotEmpty) {
        styleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(medicine.photo!),
          largeIcon: FilePathAndroidBitmap(medicine.photo!),
          contentTitle: 'Medicine Time: ${medicine.name}',
          summaryText: '${medicine.dose} - ${medicine.instruction}',
        );
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'med_alarm_$soundFileName',
        'Medicine Alarm ($soundFileName)',
        channelDescription: 'Continuous alarm sound for medicines',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFileName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]),
        styleInformation: styleInformation,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'mark_taken_id',
            'Mark as Taken',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
        category: AndroidNotificationCategory.alarm,
        autoCancel: true,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          sound: '$soundFileName.wav',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      // Payload: Name|Dose|Instruction|PhotoPath
      String payloadData =
          "${medicine.name}|${medicine.dose}|${medicine.instruction}|${medicine.photo ?? ''}";

      await _notificationsPlugin.zonedSchedule(
        medicine.id.hashCode,
        'Medicine Time: ${medicine.name}',
        'Take ${medicine.dose} - ${medicine.instruction}',
        scheduledTime,
        details,
        payload: payloadData,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
