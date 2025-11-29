import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/user_data_service.dart';
import 'activity_log_service.dart';

class MedicineLogService {
  Future<bool> logAction(String medicineId, String action) async {
    try {
      final token = await UserDataService.getToken();
      print("Sending medicineId: $medicineId with action: $action");

      final response = await http.post(
        Uri.parse(ApiConfig.logAction),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "medicineId": medicineId,
          "action": action,
        }),
      );

      print("Response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Add to in-app activity log
        ActivityLogService.addLog(
          NotificationEntry(
            id: medicineId,
            title: "Medicine ${action[0].toUpperCase()}${action.substring(1)}",
            message: "You have ${action} your medicine",
            time: DateTime.now().toLocal().toString().split('.')[0],
            type: _mapActionToType(action),
          ),
        );

        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error logging action: $e");
      return false;
    }
  }

  NotificationType _mapActionToType(String action) {
    switch (action) {
      case "taken":
        return NotificationType.taken;
      case "skipped":
        return NotificationType.skipped;
      case "snoozed":
        return NotificationType.snoozed;
      default:
        return NotificationType.taken;
    }
  }
}
