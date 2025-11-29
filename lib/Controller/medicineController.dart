import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';

class MedicineController {
  final MedicineService _medicineService = MedicineService();

  Future<List<Medicine>> getAllMedicines() async {
    return await _medicineService.getMedicines();
  }

  Future<bool> addMedicine(Medicine med) async {
    return await _medicineService.addMedicine(med);
  }

  Future<bool> updateMedicine(String id, Medicine med) async {
    return await _medicineService.updateMedicine(id, med);
  }

  Future<bool> deleteMedicine(String id) async {
    return await _medicineService.deleteMedicine(id);
  }

  /// 🛠️ FIXED: Stronger Logic to handle Stock Updates
  Future<String> markMedicineAsTaken(Medicine med) async {
    try {
      print("🔍 PROCESSING MEDICINE: ${med.name} | ID: ${med.id}");
      print("Old Stock String: '${med.pillCount}'");

      // 1. Extract Current Stock (Force extract digits)
      int currentStock = 0;
      final stockMatch = RegExp(r'\d+').firstMatch(med.pillCount.toString());
      if (stockMatch != null) {
        currentStock = int.parse(stockMatch.group(0)!);
      }

      print("Parsed Current Stock: $currentStock");

      // 2. Extract Dose Amount (e.g., "2 Tablets" -> 2)
      int doseAmount = 1; // Default
      final doseMatch = RegExp(r'\d+').firstMatch(med.dose.toString());
      if (doseMatch != null) {
        doseAmount = int.parse(doseMatch.group(0)!);
      }

      print("Dose to subtract: $doseAmount");

      // 3. Calculate New Stock
      int newStock = currentStock - doseAmount;
      if (newStock < 0) newStock = 0;

      print("✅ New Stock Calculated: $newStock");

      // 4. Update the Medicine object
      // IMPORTANT: Keep the format consistent (Just the number)
      med.pillCount = newStock.toString();

      // 5. Send update to Backend
      bool success = await _medicineService.updateMedicine(med.id, med);

      if (!success) {
        return "Error: Server failed to update stock.";
      }

      // 6. REAL-TIME REFILL ALERT LOGIC
      if (newStock <= 5) {
        String title = "⚠️ Low Medicine Stock";
        String body = "";

        if (newStock == 0) {
          title = "❌ Medicine Finished";
          body = "Your ${med.name} is finished! Please refill immediately.";
        } else {
          body = "Only $newStock left of ${med.name}. Please refill soon.";
        }

        // Trigger Notification
        await NotificationService.showRefillNotification(title, body);
      }

      return "Success"; // Return success string
    } catch (e) {
      print("Error marking medicine as taken: $e");
      return "Error: $e";
    }
  }
}
