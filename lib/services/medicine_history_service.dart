import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MedicineRecord {
  final String medicineName;
  final String time;
  final String dosage;
  final DateTime dateTaken;

  MedicineRecord({
    required this.medicineName,
    required this.time,
    required this.dosage,
    required this.dateTaken,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'time': time,
      'dosage': dosage,
      'dateTaken': dateTaken.toIso8601String(),
    };
  }

  factory MedicineRecord.fromJson(Map<String, dynamic> json) {
    return MedicineRecord(
      medicineName: json['medicineName'] as String,
      time: json['time'] as String,
      dosage: json['dosage'] as String,
      dateTaken: DateTime.parse(json['dateTaken'] as String),
    );
  }
}

class MedicineHistoryService {
  static const String _keyHistory = 'medicine_history';

  static Future<void> addMedicineRecord(MedicineRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyHistory);
    List<MedicineRecord> history = [];

    if (historyJson != null) {
      final List<dynamic> historyList = json.decode(historyJson);
      history = historyList.map((json) => MedicineRecord.fromJson(json)).toList();
    }

    history.add(record);

    final updatedHistoryJson = json.encode(
      history.map((record) => record.toJson()).toList(),
    );
    await prefs.setString(_keyHistory, updatedHistoryJson);
  }

  static Future<List<MedicineRecord>> getMedicineHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_keyHistory);

    if (historyJson == null) {
      return [];
    }

    final List<dynamic> historyList = json.decode(historyJson);
    return historyList.map((json) => MedicineRecord.fromJson(json)).toList();
  }

  static Future<List<MedicineRecord>> getMedicineHistoryForPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allHistory = await getMedicineHistory();
    return allHistory.where((record) {
      return record.dateTaken.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.dateTaken.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  static Future<List<MedicineRecord>> getMedicineHistoryForLastMonth() async {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    return getMedicineHistoryForPeriod(startDate: oneMonthAgo, endDate: now);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }
}

