import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/relationship_connection.dart';

class RelationshipService {
  // Deep link configuration
  static const String inviteScheme = 'remindme';
  static const String inviteHost = 'app';
  static const String invitePath = '/invite';
  static const String androidPackage = 'com.example.remindme';

  // Base API URL (for invite response and fetching)
  static const String baseApiUrl = 'https://remindme-backend-x1qd.onrender.com';

  /// Build an in-app deep link to open the Flutter app
  static String buildDeepLink({
    required String role,
    required String inviterId,
    String? inviterName,
  }) {
    final uri = Uri(
      scheme: inviteScheme,
      host: inviteHost,
      path: invitePath,
      queryParameters: {
        'role': role,
        'inviterId': inviterId,
        if (inviterName != null && inviterName.isNotEmpty)
          'inviterName': inviterName,
      },
    );
    return uri.toString();
  }

  /// Android intent link (optional, for sharing)
  static String buildIntentLink({
    required String role,
    required String inviterId,
    String? inviterName,
  }) {
    final params = Uri(
      queryParameters: {
        'role': role,
        'inviterId': inviterId,
        if (inviterName != null && inviterName.isNotEmpty)
          'inviterName': inviterName,
      },
    ).query;

    return 'intent://$inviteHost$invitePath?$params#Intent;scheme=$inviteScheme;package=$androidPackage;end';
  }

  /// Respond to an invite (accept/reject)
  static Future<String> respondToInvite({
    required String inviterId,
    required String inviteeId,
    required String type,
    required String action, // 'accept' or 'reject'
  }) async {
    final url = Uri.parse('$baseApiUrl/respond-invite');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'inviterId': inviterId,
        'inviteeId': inviteeId,
        'type': type,
        'action': action,
      }),
    );

    final body = jsonDecode(response.body);
    final message = body['message'] ?? 'Unexpected response';

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return message;
    }

    throw Exception(message);
  }

  /// Fetch caregivers
  static Future<List<RelationshipConnection>> fetchCaregivers(String userId) async {
    final url = Uri.parse('$baseApiUrl/users/$userId/caregivers');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RelationshipConnection.fromCaregiverJson(e)).toList();
    }
    throw Exception('Failed to load caregivers');
  }

  /// Fetch patients
  static Future<List<RelationshipConnection>> fetchPatients(String userId) async {
    final url = Uri.parse('$baseApiUrl/users/$userId/patients');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => RelationshipConnection.fromPatientJson(e)).toList();
    }
    throw Exception('Failed to load patients');
  }
}
