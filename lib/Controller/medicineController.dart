import '../Model/medicine.dart';
import '../services/medicine_service.dart';
// ✅ IMPORT REFILL SERVICE (Centralized Logic)
import '../services/refill_alert_service.dart';
import '../services/notification_service.dart';

class MedicineController {
  final MedicineService _medicineService = MedicineService();

  // Lock Mechanism (Prevents double-tapping "Take")
  final Set<String> _processingMedicines = {};

  // 1. Fetch all medicines
  Future<List<Medicine>> getAllMedicines() async {
    try {
      return await _medicineService.getMedicines();
    } catch (e) {
      return [];
    }
  }

  // 2. Add a new medicine
  Future<String> addMedicine(Medicine medicine, String? imagePath) async {
    try {
      await _medicineService.addMedicine(medicine);
      return "Success";
    } catch (e) {
      return "Error adding medicine: $e";
    }
  }

  // 3. Update Medicine
  Future<String> updateMedicine(String id, Medicine medicine) async {
    try {
      await _medicineService.updateMedicine(id, medicine);
      return "Success";
    } catch (e) {
      return "Error updating medicine: $e";
    }
  }

  // 4. Mark Medicine as Taken
  Future<String> markMedicineAsTaken(Medicine medicine) async {
    // 1. Controller Lock: Prevents double database updates
    if (_processingMedicines.contains(medicine.id)) {
      return "Processing";
    }
    _processingMedicines.add(medicine.id);

    try {
      // --- Step 1: Calculate New Stock ---
      int currentStock = int.tryParse(medicine.pillCount) ?? 0;

      if (currentStock <= 0) {
        _processingMedicines.remove(medicine.id);
        return "Already Empty";
      }

      int doseVal = 1;
      final doseMatch = RegExp(r'\d+').firstMatch(medicine.dose);
      if (doseMatch != null) {
        doseVal = int.parse(doseMatch.group(0)!);
      }

      int newStock = currentStock - doseVal;
      if (newStock < 0) newStock = 0;

      // --- Step 2: Create Updated Medicine Object ---
      Medicine updatedMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        dose: medicine.dose,
        time: medicine.time,
        instruction: medicine.instruction,
        pillCount: newStock.toString(),
        photo: medicine.photo,
        repeat: medicine.repeat,
        ringtone: medicine.ringtone,
        userId: medicine.userId,
        createdAt: medicine.createdAt,
      );

      // --- Step 3: Update Database ---
      await _medicineService.updateMedicine(medicine.id, updatedMedicine);

      // ✅ FIXED: DELEGATE TO REFILL SERVICE
      // Instead of showing notification directly here (which causes duplicates),
      // we call the Service. The Service has the "Debounce Lock" (5-second timer)
      // and handles both the Dashboard Log AND the Notification.
      if (newStock <= 5) {
        await RefillAlertService.checkStockAfterTaken(updatedMedicine);
      }

      _processingMedicines.remove(medicine.id);
      return "Success";
    } catch (e) {
      _processingMedicines.remove(medicine.id);
      return "Failed to update stock: $e";
    }
  }

  // 5. Delete Medicine
  Future<String> deleteMedicine(String id) async {
    try {
      await _medicineService.deleteMedicine(id);
      return "Success";
    } catch (e) {
      return "Error deleting medicine: $e";
    }
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
