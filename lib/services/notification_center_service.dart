import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool read;
  final String type; // e.g. reminder, taken, info
  final String? metadataTag;

  const NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.read = false,
    this.metadataTag,
  });

  NotificationEntry copyWith({
    bool? read,
  }) {
    return NotificationEntry(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      read: read ?? this.read,
      metadataTag: metadataTag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'type': type,
      'metadataTag': metadataTag,
    };
  }

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool? ?? false,
      type: json['type'] as String? ?? 'info',
      metadataTag: json['metadataTag'] as String?,
    );
  }
}

class NotificationCenterService {
  static const String _storageKey = 'notification_center_entries';

  static Future<List<NotificationEntry>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> raw = json.decode(jsonString) as List<dynamic>;
    return raw
        .map((dynamic item) => NotificationEntry.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addNotification(NotificationEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getNotifications();

    // Avoid duplicates by metadata tag
    if (entry.metadataTag != null &&
        current.any((element) => element.metadataTag == entry.metadataTag)) {
      return;
    }

    current.insert(0, entry);
    final encoded = json.encode(current.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getNotifications();
    final updated = current.map((entry) => entry.copyWith(read: true)).toList();
    final encoded = json.encode(updated.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  static Future<int> getUnreadCount() async {
    final current = await getNotifications();
    return current.where((entry) => !entry.read).length;
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getNotifications();
    final updated = current
        .map(
          (entry) => entry.id == id ? entry.copyWith(read: true) : entry,
        )
        .toList();
    final encoded = json.encode(updated.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

