import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/medicine.dart';
import '../config/api.dart';
import '../services/user_data_service.dart';

class MedicineService {
  // Fetch
  Future<List<Medicine>> getMedicines() async {
    try {
      final token = await UserDataService.getToken();
      final userData = await UserDataService.getUserData();
      final String? currentUserId = userData['phone'];

      final response = await http.get(
        Uri.parse(ApiConfig.viewMedicine),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['medicines'] != null) {
          final List medicinesJson = data['medicines'];
          return medicinesJson.map((e) {
            Medicine med = Medicine.fromJson(e);

            // Re-attach UserID if missing (Safety check)
            if ((med.userId == null || med.userId!.isEmpty) &&
                currentUserId != null) {
              return Medicine(
                id: med.id,
                name: med.name,
                dose: med.dose,
                time: med.time,
                instruction: med.instruction,
                pillCount: med.pillCount,
                photo: med.photo,
                repeat: med.repeat,
                ringtone: med.ringtone,
                userId: currentUserId,
                createdAt: med.createdAt,
              );
            }
            return med;
          }).toList();
        }
      }
    } catch (e) {
      print("Error fetching: $e");
    }
    return [];
  }

  // Add
  Future<bool> addMedicine(Medicine med) async {
    try {
      final token = await UserDataService.getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.addMedicine),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(med.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding: $e");
      return false;
    }
  }

  // Update
  Future<bool> updateMedicine(String id, Medicine med) async {
    try {
      final token = await UserDataService.getToken();
      final String cleanId = id.toString().trim();

      // SAFETY: Don't send "null" string to backend
      if (cleanId == "null" || cleanId.isEmpty) {
        print("Error: Invalid ID 'null' detected. Cannot Update.");
        return false;
      }

      final response = await http.put(
        Uri.parse("${ApiConfig.updateMedicine}/$cleanId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(med.toJson()),
      );

      print("Update API Response: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error updating: $e");
      return false;
    }
  }

  // Delete
  Future<bool> deleteMedicine(String id) async {
    try {
      final token = await UserDataService.getToken();
      final String cleanId = id.toString().trim();

      // SAFETY: Don't send "null" string to backend
      if (cleanId == "null" || cleanId.isEmpty) {
        print("Error: Invalid ID 'null' detected. Cannot Delete.");
        return false;
      }

      final response = await http.delete(
        Uri.parse("${ApiConfig.deleteMedicine}/$cleanId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("Delete API Response: ${response.statusCode}");

      // Accept 200 (OK), 201 (Created), or 204 (No Content)
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      print("Error deleting: $e");
      return false;
    }
  }
}
