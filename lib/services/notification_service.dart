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
          if (details.payload!.startsWith("http") ||
              details.payload!.contains("invite")) {
            _navigatorKey!.currentState!.pushNamed(
              '/inviteScreen',
              arguments: details.payload,
            );
          } else {
            _navigatorKey!.currentState!.pushNamed(
              '/alarm',
              arguments: details.payload,
            );
          }
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

  // --- CONFIRMATION NOTIFICATION ---
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // --- NEW: REFILL ALERT NOTIFICATION (ADDED THIS) ---
  static Future<void> showRefillNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'med_refill_channel', // Unique Channel ID
      'Refill Alerts', // Channel Name
      channelDescription: 'Alerts when medicine stock is low',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      color: Colors.red, // Show red color for urgency
      enableVibration: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    // Using a random ID ensures multiple alerts can stack
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.show(
      notificationId,
      title,
      body,
      details,
    );
  }

  // --- SNOOZE FUNCTION ---
  static Future<void> scheduleSnoozeNotification(String payload,
      {int minutes = 5}) async {
    try {
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      final tz.TZDateTime scheduledDate = now.add(Duration(minutes: minutes));

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'med_snooze_channel',
        'Snooze Alarms',
        channelDescription: 'Channel for Medicine Alarms (Snoozed)',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('tone1'),
        fullScreenIntent: true,
        autoCancel: false,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
            sound: 'tone1.wav',
            interruptionLevel: InterruptionLevel.timeSensitive),
      );

      await _notificationsPlugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Snooze: Medicine Time!',
        'It is time to take your medicine (Snoozed)',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      print("Error scheduling snooze: $e");
    }
  }

  // --- MAIN ALARM FUNCTION ---
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
        'med_alarm_channel_v2_$soundFileName',
        'Medicine Alarm V2 ($soundFileName)',
        channelDescription: 'Continuous alarm sound for medicines',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(soundFileName),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]),
        styleInformation: styleInformation,
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'view_id',
            'Open',
            showsUserInterface: true,
          ),
        ],
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

      String payloadData =
          "${medicine.name}|${medicine.dose}|${medicine.instruction}|${medicine.photo ?? ''}|${medicine.id ?? ''}";

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

  static Future<void> showInviteNotification(
      String title, String message, String inviteLink) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'invite_channel',
      'Invite Notifications',
      channelDescription: 'Notifications for invite links',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      details,
      payload: inviteLink,
    );
  }
}
