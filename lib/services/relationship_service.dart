import 'dart:async';
import '../Model/relationship_connection.dart';
import '../config/api.dart';

class RelationshipService {
  // Deep link configuration
  static const String inviteScheme = 'remindme';
  static const String inviteHost = 'app';
  static const String invitePath = '/invite';
  static const String androidPackage = 'com.example.remindme';
  static const String hostedInviteBase =
      'https://neerume.github.io/remindme_links/invite.html';

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

  // --- MOCKED METHODS WITH FAKE API LOGGING ---

  static Future<String> respondToInvite({
    required String inviterId,
    required String inviteeId,
    required String type,
    required String action,
  }) async {
    // We print this to use the import and simulate a real call
    print("POST Request to: ${ApiConfig.respondInvite}");

    await Future.delayed(const Duration(seconds: 1));
    return "Successfully ${action}ed invite";
  }

  static Future<List<RelationshipConnection>> fetchCaregivers(
      String userId) async {
    // We print this to use the import and simulate a real call
    print("GET Request to: ${ApiConfig.getCaregivers}");

    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const RelationshipConnection(
        relationshipId: 'cg_1',
        role: 'caregiver',
        name: 'Dr. Sarah Khadka',
        phoneNumber: '+9779857832381',
        photo: null,
      ),
      const RelationshipConnection(
        relationshipId: 'cg_2',
        role: 'caregiver',
        name: 'Mom',
        phoneNumber: '+9745711559',
        photo: null,
      ),
    ];
  }

  static Future<List<RelationshipConnection>> fetchPatients(
      String userId) async {
    // We print this to use the import and simulate a real call
    print("GET Request to: ${ApiConfig.getPatients}");

    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const RelationshipConnection(
        relationshipId: 'pt_1',
        role: 'patient',
        name: 'Sanjulaa',
        phoneNumber: '+9745711559',
        photo: null,
      ),
    ];
  }

  static Future<void> inviteCaregiver(
      {required String inviterId, required String inviteeId}) async {
    print("POST Request to: ${ApiConfig.inviteCaregiver}/$inviterId");
    await Future.delayed(const Duration(seconds: 1));
  }

  static Future<void> invitePatient(
      {required String inviterId, required String inviteeId}) async {
    print("POST Request to: ${ApiConfig.invitePatient}/$inviterId");
    await Future.delayed(const Duration(seconds: 1));
  }
}
