class Medicine {
  final String id;
  final String userId;

  String name;               // backend: name
  String time;               // "07:30 AM"  (converted from alarms[])
  String repeat;             // Everyday / Weekdays / Weekends
  String dose;               // 1 tablet / 2 tablets
  String pillCount;          // convert number to string for now
  String instruction;        // Before meal / After meal
  String? photo;             // backend: photo
  String createdAt;

  Medicine({
    required this.id,
    required this.userId,
    required this.name,
    required this.time,
    required this.repeat,
    required this.dose,
    required this.pillCount,
    required this.instruction,
    this.photo,
    required this.createdAt,
  });

  /// Convert backend JSON to Flutter model
  factory Medicine.fromJson(Map<String, dynamic> json) {
    // Extract first alarm from array
    String formattedTime = "";
    if (json['alarms'] != null && json['alarms'].isNotEmpty) {
      final alarm = json['alarms'][0];
      final hour = alarm['hour'] ?? 0;
      final minute = alarm['minute'] ?? 0;
      final amPm = alarm['amPm'] ?? "";

      formattedTime =
      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm";
    }

    return Medicine(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? "",
      time: formattedTime,
      repeat: json['repeat'] ?? "",
      dose: json['dose'] ?? "",
      pillCount: json['pillCount']?.toString() ?? "",
      instruction: json['instruction'] ?? "",
      photo: json['photo'],
      createdAt: json['createdAt'] ?? "",
    );
  }

  /// Convert Flutter model to backend JSON
  Map<String, dynamic> toJson() {
    // Convert "07:30 AM" → hour, minute, amPm
    final parts = time.split(" ");
    final hm = parts[0].split(":");
    final amPm = parts[1];

    final hour = int.tryParse(hm[0]) ?? 0;
    final minute = int.tryParse(hm[1]) ?? 0;

    return {
      "name": name,
      "dose": dose,
      "pillCount": int.tryParse(pillCount) ?? 0,
      "instruction": instruction,
      "repeat": repeat,
      "photo": photo,
      "alarms": [
        {
          "hour": hour,
          "minute": minute,
          "amPm": amPm,
        }
      ]
    };
  }
}
