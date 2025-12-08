import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/refill_alert_service.dart';
import '../services/user_data_service.dart';

class MedicineController {
  final MedicineService _medicineService = MedicineService();
  final Set<String> _processingMedicines = {};

  // Fetch
  Future<List<Medicine>> getAllMedicines() async {
    try {
      return await _medicineService.getMedicines();
    } catch (e) {
      return [];
    }
  }

  // Add
  Future<String> addMedicine(Medicine medicine, String? imagePath) async {
    try {
      final userData = await UserDataService.getUserData();
      final String? currentUserId = userData['phone'];

      Medicine newMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        dose: medicine.dose,
        time: medicine.time,
        instruction: medicine.instruction,
        pillCount: medicine.pillCount,
        photo: medicine.photo,
        repeat: medicine.repeat,
        ringtone: medicine.ringtone,
        userId: medicine.userId ?? currentUserId ?? "unknown",
        createdAt: medicine.createdAt,
      );

      bool success = await _medicineService.addMedicine(newMedicine);
      return success ? "Success" : "Failed";
    } catch (e) {
      return "Error: $e";
    }
  }

  // Update
  Future<String> updateMedicine(String id, Medicine medicine) async {
    try {
      bool success = await _medicineService.updateMedicine(id, medicine);
      return success ? "Success" : "Failed";
    } catch (e) {
      return "Error: $e";
    }
  }

  // Delete
  Future<String> deleteMedicine(String id) async {
    try {
      bool success = await _medicineService.deleteMedicine(id);
      return success ? "Success" : "Failed";
    } catch (e) {
      return "Error: $e";
    }
  }

  // Mark Taken
  Future<String> markMedicineAsTaken(Medicine medicine) async {
    if (_processingMedicines.contains(medicine.id)) return "Processing";
    _processingMedicines.add(medicine.id);

    try {
      int currentStock = int.tryParse(medicine.pillCount) ?? 0;
      if (currentStock <= 0) {
        _processingMedicines.remove(medicine.id);
        return "Already Empty";
      }

      int newStock = currentStock - 1;
      if (newStock < 0) newStock = 0;

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

      await _medicineService.updateMedicine(medicine.id, updatedMedicine);
      if (newStock <= 5) {
        await RefillAlertService.checkStockAfterTaken(updatedMedicine);
      }
      _processingMedicines.remove(medicine.id);
      return "Success";
    } catch (e) {
      _processingMedicines.remove(medicine.id);
      return "Failed";
    }
  }
}
