import 'package:flutter/material.dart';

// 1. Define the Enum for Type
enum NotificationType { snoozed, taken, skipped }

// 2. Define the Entry Model
class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type; // This fixes the "type not defined" error

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });
}

// 3. Define the Service to manage the list
class ActivityLogService {
  // Using a static list so data persists while the app is running
  static final List<NotificationEntry> _logs = [];

  static List<NotificationEntry> get logs => List.unmodifiable(_logs);

  static void addLog(NotificationEntry entry) {
    _logs.insert(0, entry); // Add to the top of the list
  }
}
