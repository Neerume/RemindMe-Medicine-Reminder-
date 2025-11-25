import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/user.dart';
import '../config/api.dart';
import '../services/user_data_service.dart';

class UserController {
  Future<User?> fetchProfile() async {
    try {
      final token = await UserDataService.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.getProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  Future<bool> updateProfile(User user) async {
    try {
      final token = await UserDataService.getToken();
      final response = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(user.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }
}
