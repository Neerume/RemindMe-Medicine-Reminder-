import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_data_service.dart';

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
  // ✅ FIX: Dynamic key generation based on Logged-in User
  static Future<String> _getUserKey() async {
    try {
      // FIX: Changed type to Map<String, String?> to accept nullable values
      final Map<String, String?> userData = await UserDataService.getUserData();

      String? userId = userData['phone']; // unique identifier

      if (userId != null && userId.isNotEmpty) {
        return 'activity_logs_$userId'; // e.g. activity_logs_9800000000
      }
    } catch (e) {
      print("Error getting user ID for logs: $e");
    }
    return 'activity_logs_guest'; // Fallback if no user found
  }

  static Future<void> addLog(NotificationEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getUserKey(); // Get dynamic key

    List<String> logs = prefs.getStringList(key) ?? [];

    // Add to top
    logs.insert(0, jsonEncode(entry.toJson()));

    // Limit log size to prevent storage bloat (optional, keep last 50)
    if (logs.length > 50) {
      logs = logs.sublist(0, 50);
    }

    await prefs.setStringList(key, logs);
    print("✅ SAVED LOG for $key: ${entry.title}");
  }

  static Future<List<NotificationEntry>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getUserKey(); // Get dynamic key

    List<String> logs = prefs.getStringList(key) ?? [];

    print("📂 LOADED ${logs.length} LOGS for $key");

    return logs.map((e) => NotificationEntry.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = await _getUserKey();
    await prefs.remove(key);
  }
}
