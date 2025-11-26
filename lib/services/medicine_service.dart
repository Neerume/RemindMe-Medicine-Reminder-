  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import '../Model/medicine.dart';
  import '../config/api.dart';
  import '../services/user_data_service.dart';

  class MedicineService {

    /// Fetch all medicines for logged-in user
    Future<List<Medicine>> getMedicines() async {
      try {
        final token = await UserDataService.getToken();

        final response = await http.get(
          Uri.parse(ApiConfig.viewMedicine),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body); // decode as Map
          final List medicinesJson = data['medicines']; // get the medicines array
          return medicinesJson.map((e) => Medicine.fromJson(e)).toList();
        }

      } catch (e) {
        print("Error fetching medicine: $e");
      }
      return [];
    }

    /// Add medicine
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
        print("Response code: ${response.statusCode}");
        print("Response body: ${response.body}");
        print("Sending JSON: ${jsonEncode(med.toJson())}");

        // Updated: Check for 200 or 201, OR parse the body for "success": true
        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return responseData['success'] == true;  // Extra safety check

        }
        return false;
      } catch (e) {
        print("Error adding medicine: $e");
        return false;
      }
    }
    /// Update medicine
    Future<bool> updateMedicine(String id, Medicine med) async {
      try {
        final token = await UserDataService.getToken();

        final response = await http.put(
          Uri.parse("${ApiConfig.updateMedicine}/$id"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(med.toJson()),
        );

        return response.statusCode == 200;
      } catch (e) {
        print("Error updating medicine: $e");
        return false;
      }
    }

    /// Delete medicine
    Future<bool> deleteMedicine(String id) async {
      try {
        final token = await UserDataService.getToken();

        final response = await http.delete(
          Uri.parse("${ApiConfig.deleteMedicine}/$id"),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        return response.statusCode == 200;
      } catch (e) {
        print("Error deleting medicine: $e");
        return false;
      }
    }
    /// Fetch a single medicine by ID (from API)
    Future<Medicine?> getMedicineById(int id) async {
      try {
        final token = await UserDataService.getToken();
        final response = await http.get(
          Uri.parse("${ApiConfig.viewMedicine}/$id"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Medicine.fromJson(data['medicine']); // adjust according to your API
        }
      } catch (e) {
        print("Error fetching medicine by ID: $e");
      }
      return null;
    }

  }
