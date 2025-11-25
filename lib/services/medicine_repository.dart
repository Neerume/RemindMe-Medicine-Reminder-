import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineEntry {
  // ✅ CHANGED: id is now a String to prevent type errors
  final String id;
  final String name;
  final DateTime scheduledDateTime;
  final String dosage;
  final String imagePath;
  final String repeat;
  final String instruction;
  final String ringtone;
  final int pillCount;

  MedicineEntry({
    required this.id,
    required this.name,
    required this.scheduledDateTime,
    required this.dosage,
    this.imagePath = '',
    this.repeat = 'None',
    this.instruction = '',
    this.ringtone = 'Default',
    this.pillCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'dosage': dosage,
      'imagePath': imagePath,
      'repeat': repeat,
      'instruction': instruction,
      'ringtone': ringtone,
      'pillCount': pillCount,
    };
  }

  factory MedicineEntry.fromJson(Map<String, dynamic> json) {
    return MedicineEntry(
      // ✅ FIXED: Safely convert any ID (int or string) to String
      id: json['id'].toString(),
      name: json['name'],
      scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
      dosage: json['dosage'],
      imagePath: json['imagePath'] ?? '',
      repeat: json['repeat'] ?? 'None',
      instruction: json['instruction'] ?? '',
      ringtone: json['ringtone'] ?? 'Default',
      pillCount: json['pillCount'] ?? 0,
    );
  }
}

class MedicineRepository {
  MedicineRepository._privateConstructor();
  static final MedicineRepository instance =
      MedicineRepository._privateConstructor();

  static const String _storageKey = 'medicines_list';

  Future<List<MedicineEntry>> getAllMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];

    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => MedicineEntry.fromJson(e)).toList();
  }

  Future<void> addMedicine(MedicineEntry entry) async {
    final list = await getAllMedicines();
    list.add(entry);
    await _saveList(list);
  }

  // ✅ THIS METHOD WAS MISSING. IT IS NOW ADDED.
  Future<void> deleteMedicine(String id) async {
    final list = await getAllMedicines();
    list.removeWhere((entry) => entry.id == id);
    await _saveList(list);
  }

  Future<void> _saveList(List<MedicineEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<List<MedicineEntry>> getTodayMedicines(DateTime date) async {
    final all = await getAllMedicines();
    return all.where((e) {
      return e.scheduledDateTime.year == date.year &&
          e.scheduledDateTime.month == date.month &&
          e.scheduledDateTime.day == date.day;
    }).toList();
  }
}
