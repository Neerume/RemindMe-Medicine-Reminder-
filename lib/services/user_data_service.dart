import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _keyUsername = 'user_username';
  static const String _keyToken = 'user_token';
  static const String _keyPhone = 'user_phone'; // PK, just for reference, never update

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  static Future<void> saveUserData({required String phone, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone); // just store for reference
    await prefs.setString(_keyUsername, username);
  }

  static Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone': prefs.getString(_keyPhone), // PK, readonly
      'username': prefs.getString(_keyUsername),
    };
  }
}
