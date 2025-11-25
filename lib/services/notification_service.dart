import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../Model/medicine.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    // 2. Android Initialization
    // Ensure 'ic_launcher' exists in android/app/src/main/res/mipmap-*/
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Initialization
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
      onDidReceiveNotificationResponse: (details) {
        print("Clicked notification payload: ${details.payload}");
      },
    );
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Request basic notification permission (Android 13+)
      await androidImplementation?.requestNotificationsPermission();

      // Request Exact Alarm permission (Android 12+)
      await androidImplementation?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // --- Main Schedule Logic ---
  static Future<void> scheduleMedicineReminder(Medicine medicine) async {
    try {
      // 1. Parsing Logic for "04:30 PM" (Handles extra spaces)
      String cleanedTime = medicine.time.replaceAll(RegExp(r'\s+'), ' ').trim();

      final timeParts = cleanedTime.split(" ");
      final hm = timeParts[0].split(":");
      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);
      final amPm = timeParts[1].toUpperCase();

      // Convert to 24 Hour format
      if (amPm == "PM" && hour != 12) hour += 12;
      if (amPm == "AM" && hour == 12) hour = 0;

      // 2. Unique ID
      int notificationId = medicine.id.hashCode;

      // 3. Define Notification Details (Pop-up Settings)
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'med_alert_high_priority', // CHANGED ID: Resets settings to allow pop-ups
        'Medicine Pop-ups', // Channel Name
        channelDescription: 'High importance alerts that pop over other apps',

        // --- KEY SETTINGS FOR HEADS-UP NOTIFICATIONS ---
        importance: Importance.max, // Display on top of screen
        priority: Priority.high, // High priority
        fullScreenIntent: true, // Helps wake locked screens
        ticker: 'Time for your medicine',
        visibility:
            NotificationVisibility.public, // Show content on lock screen

        // Sound and Vibration
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true, // iOS Pop up
          presentBanner: true,
          presentSound: true,
        ),
      );

      // 4. Calculate schedule
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      // 5. Schedule
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Medicine Time: ${medicine.name}', // Title
        'Take ${medicine.dose} - ${medicine.instruction}', // Body
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
      );

      print("SUCCESS: Scheduled POP-UP for ${medicine.name} at $hour:$minute");
    } catch (e) {
      print("ERROR Scheduling Notification for ${medicine.name}: $e");
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
