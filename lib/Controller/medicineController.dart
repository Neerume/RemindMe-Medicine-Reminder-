import '../Model/medicine.dart';
import '../services/medicine_service.dart';
// ✅ IMPORT REFILL SERVICE (Centralized Logic)
import '../services/refill_alert_service.dart';

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
}
