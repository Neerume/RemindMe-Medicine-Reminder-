import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/activity_log_service.dart';
import '../services/medicinelog_service.dart';
import '../services/medicine_service.dart';
// ✅ ADDED FOR STOCK UPDATE & REFILL CHECK
import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../services/refill_alert_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  String currentTime = "";
  String currentDate = "";
  final ScrollController _scrollController = ScrollController();

  // ✅ Added Controller
  final MedicineController _medicineController = MedicineController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentTime = DateFormat('h:mm').format(now);
    currentDate = DateFormat('EEEE, MMMM d').format(now);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAction(String action, String medicineName, String payload) async {
    // Stop the ringing
    await NotificationService.cancelAll();

    String title = "";
    String body = "";
    final now = DateTime.now();
    String timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    // Extract ID from Payload (Payload format: Name|Dose|Instruction|Photo|ID)
    List<String> parts = payload.split('|');
    String medicineId = parts.length > 4 ? parts[4] : "";

    // --- SNOOZE LOGIC ---
    if (action == "Snooze") {
      await NotificationService.scheduleSnoozeNotification(payload, minutes: 5);

      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Alarm Snoozed",
        message: "Snoozed $medicineName for 5 min",
        time: timeStr,
        type: NotificationType.snoozed,
      ));

      title = "Snoozed 💤";
      body = "Alarm will ring again in 5 minutes.";
    }

    // --- TAKEN LOGIC ---
    else if (action == "Taken") {
      title = "Great Job! 🎉";
      body = "Marked $medicineName as taken.";

      // 1. Log to Dashboard
      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Medicine Taken",
        message: "You took $medicineName",
        time: timeStr,
        type: NotificationType.taken,
      ));

      // 2. Log to Backend
      if (medicineId.isNotEmpty) {
        MedicineLogService().logAction(medicineId, "taken");
      }

      // 3. ✅ UPDATE STOCK & CHECK REFILL
      try {
        final medicineService = MedicineService();
        final medicines = await medicineService.getMedicines();
        Medicine? medicineToUpdate;

        // Try finding medicine by ID or Name
        if (medicineId.isNotEmpty) {
          try {
            medicineToUpdate = medicines.firstWhere((m) => m.id == medicineId);
          } catch (_) {}
        }
        if (medicineToUpdate == null) {
          try {
            medicineToUpdate = medicines.firstWhere(
                (m) => m.name.toLowerCase() == medicineName.toLowerCase());
          } catch (_) {}
        }

        if (medicineToUpdate != null) {
          // A. Update Stock in DB
          await _medicineController.markMedicineAsTaken(medicineToUpdate);

          // B. Trigger Refill Check (System Notification + Dashboard Log)
          await RefillAlertService.checkStockAfterTaken(medicineToUpdate);
        }
      } catch (e) {
        print("Stock update error: $e");
      }
    }

    // --- SKIP LOGIC ---
    else if (action == "Skip") {
      title = "Skipped ⚠️";
      body = "You skipped $medicineName.";

      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Medicine Skipped",
        message: "You skipped $medicineName",
        time: timeStr,
        type: NotificationType.skipped,
      ));

      if (medicineId.isNotEmpty) {
        MedicineLogService().logAction(medicineId, "skipped");
      }
    }

    await NotificationService.showConfirmationNotification(title, body);
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final String payload =
        ModalRoute.of(context)?.settings.arguments as String? ?? "Medicine|||";
    final List<String> parts = payload.split('|');

    final String medicineName = parts.isNotEmpty ? parts[0] : "Medicine";
    final String dose = parts.length > 1 ? parts[1] : "1 Dose";
    final String instruction = parts.length > 2 ? parts[2] : "Take medicine";
    final String imagePath = parts.length > 3 ? parts[3] : "";

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Container(
            height: size.height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  currentTime,
                  style: const TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  currentDate,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 25),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Medicine time",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: (imagePath.isNotEmpty &&
                                    File(imagePath).existsSync())
                                ? Image.file(File(imagePath), fit: BoxFit.cover)
                                : const Icon(Icons.medication,
                                    size: 60, color: Colors.grey),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              medicineName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5C6BC0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              instruction,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    dose,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.local_pharmacy,
                                      color: Colors.redAccent, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            SizedBox(
                              width: 150,
                              height: 45,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD37B79),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                onPressed: () => _handleAction(
                                    "Snooze", medicineName, payload),
                                child: const Text("Snooze 5m",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildActionButton(
                                  label: "Skip",
                                  color: const Color(0xFFE1BEE7),
                                  textColor: Colors.black87,
                                  onTap: () => _handleAction(
                                      "Skip", medicineName, payload),
                                ),
                                _buildActionButton(
                                  label: "Taken",
                                  color: const Color(0xFF69F0AE),
                                  textColor: Colors.black87,
                                  onTap: () => _handleAction(
                                      "Taken", medicineName, payload),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 55,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: TextStyle(
                color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
