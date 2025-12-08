class Medicine {
  final String id;
  final String name;
  final String dose;
  final String time;
  final String instruction;
  final String pillCount;
  final String? photo;
  final String repeat;
  final String? ringtone;
  final String? userId;
  final int? createdAt;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.instruction,
    required this.pillCount,
    this.photo,
    required this.repeat,
    this.ringtone,
    this.userId,
    this.createdAt,
  });

  // ✅ FIXED: Correctly maps '_id' from MongoDB so ID is never "null"
  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse CreatedAt
    int? parseCreatedAt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return DateTime.tryParse(val)?.millisecondsSinceEpoch;
      return null;
    }

    return Medicine(
      // CRITICAL FIX: Check 'id', then '_id'. prevents "null" string.
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',

      name: json['name']?.toString() ?? 'Unknown',
      dose: json['dose']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      pillCount: json['pillCount']?.toString() ?? '0',
      photo: json['photo']?.toString(),
      repeat: json['repeat']?.toString() ?? 'Everyday',
      ringtone: json['ringtone']?.toString(),
      userId: json['userId']?.toString() ?? json['user_id']?.toString(),
      createdAt: parseCreatedAt(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Ensure we send back the ID if needed
      'name': name,
      'dose': dose,
      'time': time,
      'instruction': instruction,
      'pillCount': pillCount,
      'photo': photo,
      'repeat': repeat,
      'ringtone': ringtone,
      'userId': userId,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
}
