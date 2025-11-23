import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _keyEmail = 'user_email';
  static const String _keyPhone = 'user_phone';
  static const String _keyUsername = 'user_username';
  static const String _keyUserId = 'user_id';
  static const String _keyAddress = 'user_address';
  static const String _keyGender = 'user_gender';
  static const String _keyDob = 'user_dob';
  static const String _keyEmergency = 'user_emergency_contact';

  static Future<void> saveUserData({
    required String email,
    required String phone,
    required String username,
    required String userId,
    String address = '',
    String gender = '',
    String dob = '',
    String emergencyContact = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyAddress, address);
    await prefs.setString(_keyGender, gender);
    await prefs.setString(_keyDob, dob);
    await prefs.setString(_keyEmergency, emergencyContact);
  }

  static Future<void> updateEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  static Future<void> updatePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, phone);
  }

  static Future<void> updateUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  static Future<void> updateAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAddress, address);
  }

  static Future<void> updateGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGender, gender);
  }

  static Future<void> updateDob(String dobIso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDob, dobIso);
  }

  static Future<void> updateEmergencyContact(String contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmergency, contact);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail),
      'phone': prefs.getString(_keyPhone),
      'username': prefs.getString(_keyUsername),
      'userId': prefs.getString(_keyUserId),
      'address': prefs.getString(_keyAddress),
      'gender': prefs.getString(_keyGender),
      'dob': prefs.getString(_keyDob),
      'emergency': prefs.getString(_keyEmergency),
    };
  }
}

