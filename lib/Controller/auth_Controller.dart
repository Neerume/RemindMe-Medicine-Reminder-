import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../services/user_data_service.dart';

class AuthController {
  /// ---------------- SEND OTP ----------------
  /// Sends OTP to the given phone number.
  /// Returns true if OTP sent successfully.
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phoneNumber}),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print("Error sending OTP: $e");
      return false;
    }
  }

  /// ---------------- VERIFY OTP ----------------
  /// Verifies the OTP entered by the user.
  /// Returns true if OTP is correct.
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print("Error verifying OTP: $e");
      return false;
    }
  }

  /// ---------------- LOGIN ----------------
  /// Logs in the user after OTP verification.
  /// Saves token and username locally.
  /// Returns true if login successful.
  Future<bool> login(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        // Save token and username locally
        await UserDataService.saveToken(data['token']);
        await UserDataService.saveUserData(
          phone: phoneNumber,
          username: data['username'] ?? '',
        );
        return true;
      } else {
        print("Login failed: ${data['error'] ?? 'Unknown error'}");
        return false;
      }
    } catch (e) {
      print("Error logging in: $e");
      return false;
    }
  }
}
