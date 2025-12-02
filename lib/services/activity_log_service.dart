import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Enum
enum NotificationType { taken, skipped, snoozed, scheduled }

// Model
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

class ActivityLogService {
  // ⚠️ DEMO HACK: Fixed key so it ALWAYS saves/loads
  static const String _key = 'demo_emergency_logs';

  static Future<void> addLog(NotificationEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_key) ?? [];

    // Add to top
    logs.insert(0, jsonEncode(entry.toJson()));

    await prefs.setStringList(_key, logs);
    print("✅ FORCE SAVED LOG: ${entry.title}");
  }

  static Future<List<NotificationEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_key) ?? [];

    print("📂 LOADED ${logs.length} LOGS"); // Check console

    return logs.map((e) => NotificationEntry.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
