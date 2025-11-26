class InviteInfo {
  final String role;        // 'caregiver' or 'patient'
  final String inviterId;   // the user who sent the invite
  final String? inviterName;

  InviteInfo({
    required this.role,
    required this.inviterId,
    this.inviterName,
  });

  // Optional: helper to convert from JSON if you store it in SharedPreferences
  factory InviteInfo.fromJson(Map<String, dynamic> json) {
    return InviteInfo(
      role: json['role'] as String,
      inviterId: json['inviterId'] as String,
      inviterName: json['inviterName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'inviterId': inviterId,
    'inviterName': inviterName,
  };
}
