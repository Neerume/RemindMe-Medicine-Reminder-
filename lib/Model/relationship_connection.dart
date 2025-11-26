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
      relationshipId: json['_id'] ?? '',
      role: 'caregiver',
      name: inviter['name'] ?? 'Unknown caregiver',
      phoneNumber: inviter['phoneNumber'] ?? '',
      photo: inviter['photo'] as String?,
    );
  }

  factory RelationshipConnection.fromPatientJson(Map<String, dynamic> json) {
    final invited = (json['invitedId'] as Map?) ?? {};
    return RelationshipConnection(
      relationshipId: json['_id'] ?? '',
      role: 'patient',
      name: invited['name'] ?? 'Unknown patient',
      phoneNumber: invited['phoneNumber'] ?? '',
      photo: invited['photo'] as String?,
    );
  }
}

