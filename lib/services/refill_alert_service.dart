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

      // Calculate days remaining
      final daysRemaining = (pillCount / doseAmount).floor();

      // Alert if 7 days or less remaining
      return daysRemaining <= 7;
    } catch (e) {
      print('Error checking refill: $e');
      return false;
    }
  }

  /// Get refill urgency level text
  static String getRefillUrgency(Medicine medicine) {
    try {
      final pillCount = int.tryParse(medicine.pillCount) ?? 0;

      if (pillCount == 0) return 'Empty';
      if (pillCount <= 3) return 'Critical';

      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      final doseAmount =
          doseMatch != null ? int.tryParse(doseMatch.group(0) ?? '1') ?? 1 : 1;

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

  /// Manual check function (can be called on app start)
  static Future<void> checkAndShowRefillAlerts() async {
    try {
      final medicineService = MedicineService();
      final medicines = await medicineService.getMedicines();

      for (var medicine in medicines) {
        if (needsRefill(medicine)) {
          final daysRemaining = getDaysRemaining(medicine);
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
