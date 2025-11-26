class Medicine {
  final String id;
  final String userId;

  String name; // backend: name
  String time; // "07:30 AM"  (converted from alarms[])
  String repeat; // Everyday / Weekdays / Weekends
  String dose; // 1 tablet / 2 tablets
  String pillCount; // convert number to string for now
  String instruction; // Before meal / After meal
  String? photo; // backend: photo
  String createdAt;
  String ringtone;

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
    required this.ringtone,
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
      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(
          2, '0')} $amPm";
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
      ringtone: json['ringtone'] ?? "", // Add this
    );
  }

  /// Convert Flutter model to backend JSON
  Map<String, dynamic> toJson() {
    int hour = 0;
    int minute = 0;
    String amPm = 'AM';

    if (time.isNotEmpty) {
      final parts = time.split(" ");
      if (parts.length == 2) {
        final hm = parts[0].split(":");
        if (hm.length == 2) {
          hour = int.tryParse(hm[0]) ?? 0;
          minute = int.tryParse(hm[1]) ?? 0;
        }
        amPm = parts[1];
      }
    }

    return {
      "userId": userId,
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
      ],
      "ringtone": ringtone,
    };
  }
}
