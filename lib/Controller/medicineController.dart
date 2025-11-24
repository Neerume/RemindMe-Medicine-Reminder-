import '../Model/medicine.dart';
import '../services/medicine_service.dart';

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
}
