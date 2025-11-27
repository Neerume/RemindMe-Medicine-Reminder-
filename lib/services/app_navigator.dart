import 'package:flutter/material.dart';
import '../Model/medicine.dart';
import '../View/MedicineReminderPage.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static void toMedicineReminderPage(Medicine medicine) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            MedicineReminderPage(
              medicineName: medicine.name,
              timing: medicine.instruction, // or medicine.timing
              pills: int.tryParse(medicine.dose) ?? 1,
              photoUrl: "", // pass empty if you don't have photo
            ),
      ),
    );
  }
}