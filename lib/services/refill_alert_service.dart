import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';

class RefillAlertService {
  /// Check if medicine needs refill based on pillCount and dose
  static bool needsRefill(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return true;

      // Extract dose amount from dose string (e.g., "1 tablet" -> 1, "2 tablets" -> 2)
      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount = doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return false;

      // Calculate days remaining
      final daysRemaining = (pillCount / doseAmount).floor();

      // Alert if 7 days or less remaining
      return daysRemaining <= 7 && pillCount > 0;
    } catch (e) {
      print('Error checking refill: $e');
      return false;
    }
  }

  /// Get refill urgency level
  static String getRefillUrgency(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return 'critical';

      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount = doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return 'none';

      final daysRemaining = (pillCount / doseAmount).floor();

      if (daysRemaining <= 0) return 'critical';
      if (daysRemaining <= 3) return 'urgent';
      if (daysRemaining <= 7) return 'warning';
      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  /// Get days remaining for medicine
  static int getDaysRemaining(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;
      if (pillCount <= 0) return 0;

      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount = doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

      if (doseAmount <= 0) return 0;

      return (pillCount / doseAmount).floor();
    } catch (e) {
      return 0;
    }
  }

  /// Check all medicines and show refill alerts
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
            body = '${medicine.name} is out of stock. Please refill immediately.';
          } else if (urgency == 'urgent') {
            title = '🔴 Urgent: Refill Needed';
            body = '${medicine.name} will run out in $daysRemaining day${daysRemaining == 1 ? '' : 's'}. Please refill soon.';
          } else {
            title = '🟡 Refill Reminder';
            body = '${medicine.name} will run out in $daysRemaining day${daysRemaining == 1 ? '' : 's'}. Consider refilling.';
          }

          // Show notification (you can customize this)
          await NotificationService.showConfirmationNotification(title, body);
        }
      }
    } catch (e) {
      print('Error checking refill alerts: $e');
    }
  }

  /// Get list of medicines that need refill
  static Future<List<Medicine>> getMedicinesNeedingRefill() async {
    try {
      final medicineService = MedicineService();
      final medicines = await medicineService.getMedicines();
      return medicines.where((med) => needsRefill(med)).toList();
    } catch (e) {
      print('Error getting medicines needing refill: $e');
      return [];
    }
  }
}

