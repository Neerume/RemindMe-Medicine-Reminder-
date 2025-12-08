// FILE: lib/Model/relationship_connection.dart
class RelationshipConnection {
  final String relationshipId;
  final String role; // caregiver or patient
  final String name;
  final String phoneNumber;
  final String? photo;

  const RelationshipConnection({
    required this.relationshipId,
    required this.role,
    required this.name,
    required this.phoneNumber,
    this.photo,
  });

  factory RelationshipConnection.fromCaregiverJson(Map<String, dynamic> json) {
    final inviter = (json['inviterId'] as Map?) ?? {};
    return RelationshipConnection(
      relationshipId: (json['_id'] as String?) ?? '',
      role: 'caregiver',
      name: (inviter['name'] as String?) ?? 'Unknown caregiver',
      phoneNumber: (inviter['phoneNumber'] as String?) ?? '',
      photo: inviter['photo'] as String?,
    );
  }

  factory RelationshipConnection.fromPatientJson(Map<String, dynamic> json) {
    final invited = (json['invitedId'] as Map?) ?? {};
    return RelationshipConnection(
      relationshipId: (json['_id'] as String?) ?? '',
      role: 'patient',
      name: (invited['name'] as String?) ?? 'Unknown patient',
      phoneNumber: (invited['phoneNumber'] as String?) ?? '',
      photo: invited['photo'] as String?,
    );
  }
}
