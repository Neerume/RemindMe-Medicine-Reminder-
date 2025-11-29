import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/user_data_service.dart';

class ReportService {
  // GENERATE REPORT
  static Future<Map<String, dynamic>> generateReport({int? month, int? year}) async {
    final token = await UserDataService.getToken();

    final now = DateTime.now();
    final queryMonth = month ?? now.month;
    final queryYear = year ?? now.year;

    // Add query parameters
    final url = Uri.parse('${ApiConfig.getReport}?month=$queryMonth&year=$queryYear');
    print("Generating report for $queryMonth/$queryYear"); // Debug
    print("Request URL: $url"); // Debug
    print("Token: ${token?.substring(0, 10)}..."); // Partial token for safety

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );
    print("Response status: ${response.statusCode}"); // Debug
    print("Response body: ${response.body}"); // Debug
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Failed to generate report."); // Debug
      throw Exception("Failed to generate report: ${response.body}");
    }
  }
}
