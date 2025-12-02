import 'dart:async'; // Required for Timer
import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';
import '../services/activity_log_service.dart';

class RefillAlertService {
  // ✅ FIX 1: Stronger Debounce Lock
  // This prevents the same medicine from being logged twice within 5 seconds.
  static final Set<String> _recentlyChecked = {};

  /// Check if medicine needs refill based on pillCount and dose
  static bool needsRefill(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return true;

import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';

class RefillAlertService {
  /// Check if medicine needs refill (Logic: Stock <= 5 or less than 7 days supply)
  static bool needsRefill(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;

      // Critical check: direct count
      if (pillCount <= 5) return true;

      // Extract dose amount
      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount =
          doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return false;

      final daysRemaining = (pillCount / doseAmount).floor();
      return daysRemaining <= 7;
    } catch (e) {
      // Calculate days remaining
      final daysRemaining = (pillCount / doseAmount).floor();

      // Alert if 7 days or less remaining
      return daysRemaining <= 7;
    } catch (e) {
      print('Error checking refill: $e');
      return false;
    }
  }

  // ✅ FIXED METHOD: Fixes Duplicates & Shows Actual Time
  static Future<void> checkStockAfterTaken(Medicine medicine) async {
    // 1. Check if we recently logged this medicine (Block duplicates)
    if (_recentlyChecked.contains(medicine.id)) {
      return;
    }

    // 2. Lock this medicine ID immediately
    _recentlyChecked.add(medicine.id);

    // 3. Unlock it after 5 seconds (Prevents double-taps or duplicate triggers)
    Timer(const Duration(seconds: 5), () {
      _recentlyChecked.remove(medicine.id);
    });

    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;

      // If stock is critically low (e.g. less than 5 pills)
      if (needsRefill(medicine) && pillCount <= 5) {
        // Trigger System Notification (Lock Screen Banner)
        await NotificationService.showRefillAlert(medicine.name, medicine.id);

        // ✅ FIX 2: Generate Actual Time String (e.g., "20:52")
        final DateTime now = DateTime.now();
        final String formattedTime =
            "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

        // Add Log to Dashboard
        await ActivityLogService.addLog(NotificationEntry(
          // We use the ID to help uniqueness, but the lock above is the main protection
          id: "refill_${medicine.id}_${now.millisecondsSinceEpoch}",
          title: "Medicine Finished",
          message:
              "Your ${medicine.name} is finished! Please refill immediately.",
          time: formattedTime, // ✅ Replaced "Now" with actual time
          type: NotificationType.skipped, // Using Red Icon
        ));
      }
    } catch (e) {
      // Error handling
    }
  }

  /// Get refill urgency level
  static String getRefillUrgency(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return 'critical';
  /// Get refill urgency level text
  static String getRefillUrgency(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;

      if (pillCount == 0) return 'Empty';
      if (pillCount <= 3) return 'Critical';

      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount =
          doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return 'none';

      final daysRemaining = (pillCount / doseAmount).floor();

      if (daysRemaining <= 0) return 'critical';
      if (daysRemaining <= 3) return 'urgent';
      if (daysRemaining <= 7) return 'warning';
      return 'none';
    } catch (e) {
      return 'none';
      if (doseAmount == 0) return 'None';

      final daysRemaining = (pillCount / doseAmount).floor();

      if (daysRemaining <= 2) return 'Very Urgent';
      if (daysRemaining <= 7) return 'Warning';
      return 'None';
    } catch (e) {
      return 'None';
    }
  }

  /// Get days remaining for medicine
  static int getDaysRemaining(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return 0;

      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount =
          doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return 0;

      return (pillCount / doseAmount).floor();
    } catch (e) {
      return 0;
    }
  }

  /// Check all medicines and show refill alerts
  /// Manual check function (can be called on app start)
  static Future<void> checkAndShowRefillAlerts() async {
    try {
      final medicineService = MedicineService();
      final medicines = await medicineService.getMedicines();

      for (var medicine in medicines) {
        if (needsRefill(medicine)) {
          final daysRemaining = getDaysRemaining(medicine);
          final urgency = getRefillUrgency(medicine);

          String title;
          String body;

          if (daysRemaining <= 0) {
            title = '⚠️ Refill Needed Now';
            body =
                '${medicine.name} is out of stock. Please refill immediately.';
          } else if (urgency == 'urgent') {
            title = '🔴 Urgent: Refill Needed';
            body =
                '${medicine.name} will run out in $daysRemaining day${daysRemaining == 1 ? '' : 's'}. Please refill soon.';
          } else {
            title = '🟡 Refill Reminder';
            body =
                '${medicine.name} will run out in $daysRemaining day${daysRemaining == 1 ? '' : 's'}. Consider refilling.';
          }

          await NotificationService.showConfirmationNotification(title, body);
        }
      }
    } catch (e) {
      // Error checking refill alerts
    }
  }

  static Future<List<Medicine>> getMedicinesNeedingRefill() async {
    try {
      final medicineService = MedicineService();
      final medicines = await medicineService.getMedicines();
      return medicines.where((med) => needsRefill(med)).toList();
    } catch (e) {
      return [];
          final pillCount = int.tryParse(medicine.pillCount) ?? 0;

          String title = 'Refill Reminder';
          String body = '';

          if (pillCount == 0) {
            title = '⚠️ Stock Empty';
            body = '${medicine.name} is out of stock!';
          } else if (pillCount <= 3) {
            title = '🔴 Critical Stock';
            body = '${medicine.name} has only $pillCount pills left.';
          } else {
            body =
                '${medicine.name} will run out in approx $daysRemaining days.';
          }

          // Show notification
          await NotificationService.showRefillNotification(title, body);
        }
      }
    } catch (e) {
      print('Error checking refill alerts: $e');
    }
  }
}
