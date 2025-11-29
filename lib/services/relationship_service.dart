import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/relationship_connection.dart';
import '../config/api.dart';
import 'user_data_service.dart';

class RelationshipService {
  // Deep link configuration
  static const String inviteScheme = 'remindme';
  static const String inviteHost = 'app';
  static const String invitePath = '/invite';
  static const String androidPackage = 'com.example.remindme';
  static const String hostedInviteBase =
      'https://neerume.github.io/remindme_links/invite.html';

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

  /// HTTPS invite link hosted on GitHub Pages (App Link entry point)
  static String buildHostedInviteLink({
    required String role,
    required String inviterId,
    String? inviterName,
  }) {
    final params = {
      'role': role,
      'inviterId': inviterId,
      if (inviterName != null && inviterName.isNotEmpty)
        'inviterName': inviterName,
    };
    final query = Uri(queryParameters: params).query;
    return '$hostedInviteBase?$query';
  }

  /// Respond to an invite (accept/reject)
  static Future<String> respondToInvite({
    required String inviterId,
    required String inviteeId,
    required String type,
    required String action, // 'accept' or 'reject'
  }) async {
    final token = await UserDataService.getToken();
<<<<<<< Updated upstream
    final url = Uri.parse(ApiConfig.respondInvite);

    // Define the body first
    final body = jsonEncode({
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'type': type,
      'action': action,
    });

    print("Sending POST to $url");
    print("Body: $body");
=======

    final url = Uri.parse(ApiConfig.respondInvite);

    // Ensure IDs are trimmed strings
    final requestBody = {
      'inviterId': inviterId.trim(),
      'inviteeId': inviteeId.trim(),
      'type': type.trim(),
      'action': action.trim(),
    };

    final bodyEncoded = jsonEncode(requestBody);

    // DEBUG
    debugPrint("🚀 Sending POST to: $url");
    debugPrint("📦 Payload: $bodyEncoded");
>>>>>>> Stashed changes

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    print("Response: ${response.statusCode} ${response.body}");

    final bodyJson = jsonDecode(response.body);
    // Handle cases where message might not exist or be null
    final message = bodyJson['message'] ?? 'Unexpected response';

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return message.toString();
    }

    throw Exception(message.toString());
  }

  /// Fetch caregivers
  static Future<List<RelationshipConnection>> fetchCaregivers(
      String userId) async {
    final token = await UserDataService.getToken();
    final url = Uri.parse(ApiConfig.getCaregivers);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => RelationshipConnection.fromCaregiverJson(e))
          .toList();
    }
    throw Exception('Failed to load caregivers');
  }

  /// Fetch patients
  static Future<List<RelationshipConnection>> fetchPatients(
      String userId) async {
    final token = await UserDataService.getToken();
    final url = Uri.parse(ApiConfig.getPatients);

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data
          .map((e) => RelationshipConnection.fromPatientJson(e))
          .toList();
    }
    throw Exception('Failed to load patients');
  }

  /// Invite a caregiver (creates pending invite on backend)
  static Future<void> inviteCaregiver({
    required String inviterId,
    required String inviteeId,
  }) async {
    final token = await UserDataService.getToken();
    final url =
    Uri.parse('${ApiConfig.inviteCaregiver}/$inviterId?userId=$inviteeId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      // FIXED: Added empty JSON body to prevent server 500 error
      body: jsonEncode({}),
    );

    // If status is 409, it means invite already exists.
    // We treat this as success so the user can proceed to Accept it.
    if (response.statusCode == 409) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to send caregiver invite');
    }
  }

  /// Invite a patient (creates pending invite on backend)
  static Future<void> invitePatient({
    required String inviterId,
    required String inviteeId,
  }) async {
    final token = await UserDataService.getToken();
    final url =
    Uri.parse('${ApiConfig.invitePatient}/$inviterId?userId=$inviteeId');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      // FIXED: Added empty JSON body to prevent server 500 error
      body: jsonEncode({}),
    );

    // If status is 409, it means invite already exists.
    // We treat this as success so the user can proceed to Accept it.
    if (response.statusCode == 409) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to send patient invite');
    }
  }
}
