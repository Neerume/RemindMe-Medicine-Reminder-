import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _keyUsername = 'user_username';
  static const String _keyToken = 'user_token';
  static const String _keyPhone = 'user_phone';
  static const String _keyUserId = 'user_id';
  static const String _keyInviteInviterId = 'invite_inviter_id';
  static const String _keyInviteRole = 'invite_role';
  static const String _keyInviteInviterName = 'invite_inviter_name';

  // ---------------- Token ----------------
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

  // ---------------- User Data ----------------
  static Future<void> saveUserData({required String phone, required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyUsername, username);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'phone': prefs.getString(_keyPhone),
      'username': prefs.getString(_keyUsername),
    };
  }

  // ---------------- Invite Info ----------------
  static Future<void> saveInviteInfo({
    required String inviterId,
    required String role,
    String? inviterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyInviteInviterId, inviterId);
    await prefs.setString(_keyInviteRole, role);
    if (inviterName != null && inviterName.isNotEmpty) {
      await prefs.setString(_keyInviteInviterName, inviterName);
    }
  }

  static Future<Map<String, String?>> getInviteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'inviterId': prefs.getString(_keyInviteInviterId),
      'role': prefs.getString(_keyInviteRole),
      'inviterName': prefs.getString(_keyInviteInviterName),
    };
  }

  static Future<void> clearInviteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInviteInviterId);
    await prefs.remove(_keyInviteRole);
    await prefs.remove(_keyInviteInviterName);
  }
}
