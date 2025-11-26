import 'dart:convert';

import 'package:http/http.dart' as http;

import '../Model/relationship_connection.dart';
import '../config/api.dart';

class RelationshipService {
  static const String inviteScheme = 'remindme';
  static const String inviteHost = 'app';
  static const String invitePath = '/invite';

  static String buildInviteLink({
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
        if (inviterName != null && inviterName.isNotEmpty) 'inviterName': inviterName,
      },
    );
    return uri.toString();
  }

  static Future<List<RelationshipConnection>> fetchCaregivers(String userId) async {
    final response = await http.get(Uri.parse('${ApiConfig.getCaregivers}/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load caregivers');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .map((entry) => RelationshipConnection.fromCaregiverJson(entry))
        .toList();
  }

  static Future<List<RelationshipConnection>> fetchPatients(String userId) async {
    final response = await http.get(Uri.parse('${ApiConfig.getPatients}/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load patients');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data.map((entry) => RelationshipConnection.fromPatientJson(entry)).toList();
  }

  static Future<String> respondToInvite({
    required String inviterId,
    required String inviteeId,
    required String type,
    required String action,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.respondInvite),
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
}

