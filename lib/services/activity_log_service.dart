import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Required for privacy

// 1. Shared Enum
enum NotificationType { taken, skipped, snoozed, scheduled }

// 2. Shared Model
class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time,
        'type': type.index,
      };

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      time: json['time'],
      type: NotificationType.values[json['type']],
    );
  }
}

// 3. Service with USER PRIVACY FIX
class ActivityLogService {
  // ✅ FIX: Generate a unique key based on the logged-in User ID
  static String? _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // If no user is logged in, return null
    return 'activity_logs_${user.uid}'; // e.g. "activity_logs_abc123"
  }

  // Save a log (Specific to the current user)
  static Future<void> addLog(NotificationEntry entry) async {
    final key = _getUserKey();
    if (key == null) return; // Safety check

    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(key) ?? [];

    // Add new log to the start
    logs.insert(0, jsonEncode(entry.toJson()));

    // Limit to 50 items to save space
    if (logs.length > 50) logs = logs.sublist(0, 50);

    await prefs.setStringList(key, logs);
  }

  // Get logs (Only for the current user)
  static Future<List<NotificationEntry>> getLogs() async {
    final key = _getUserKey();
    if (key == null) return []; // Return empty list if no user logged in

    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(key) ?? [];
    return logs.map((e) => NotificationEntry.fromJson(jsonDecode(e))).toList();
  }

  // Clear logs (Only for the current user)
  static Future<void> clearLogs() async {
    final key = _getUserKey();
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
