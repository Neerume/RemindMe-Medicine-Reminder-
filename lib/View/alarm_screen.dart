import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
// You can keep dashboard_screen import if you navigate there,
// but we will define the missing services locally or you should move them to a separate file.
import 'dashboard_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  String currentTime = "";
  String currentDate = "";

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentTime = DateFormat('h:mm').format(now);
    currentDate = DateFormat('EEEE, MMMM d').format(now);
  }

  // UPDATED: Sends Log to Dashboard
  void _handleAction(String action, String medicineName, String payload) async {
    // 1. Stop Current Sound
    await NotificationService.cancelAll();

    String title = "";
    String body = "";

    // Format Time for Log
    final now = DateTime.now();
    String timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    if (action == "Snooze") {
      // Schedule a new notification 5 minutes from now
      await NotificationService.scheduleSnoozeNotification(payload, minutes: 5);

      // ADD LOG
      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Alarm Snoozed",
        message: "Snoozed $medicineName for 5 min",
        time: timeStr,
        type: NotificationType.snoozed,
      ));

      title = "Snoozed 💤";
      body = "Alarm will ring again in 5 minutes.";
    } else if (action == "Taken") {
      title = "Great Job! 🎉";
      body = "Marked $medicineName as taken.";

      // ADD LOG
      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Medicine Taken",
        message: "You took $medicineName",
        time: timeStr,
        type: NotificationType.taken,
      ));
    } else if (action == "Skip") {
      title = "Skipped ⚠️";
      body = "You skipped $medicineName.";

      // ADD LOG
      ActivityLogService.addLog(NotificationEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "Medicine Skipped",
        message: "You skipped $medicineName",
        time: timeStr,
        type: NotificationType.skipped,
      ));
    }

    // 2. Show Confirmation Feedback
    await NotificationService.showConfirmationNotification(title, body);

    // 3. Close the Alarm Screen and App
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Decode Payload
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
          child: Container(
            height: size.height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // --- TOP: TIME & DATE ---
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

                // --- MAIN CARD ---
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. Header
                        const Text(
                          "Medicine time",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // 2. Photo Circle
                        Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
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

                        // 3. Info Section
                        Column(
                          children: [
                            Text(
                              medicineName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                // Fixed unnecessary const error here
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

                        // 4. Buttons
                        Column(
                          children: [
                            // Snooze
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

                            // Skip & Taken Row
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

// =========================================================
// MISSING CLASSES ADDED BELOW TO FIX ERRORS
// (Ideally, move these to a separate file like services/activity_service.dart)
// =========================================================

enum NotificationType { snoozed, taken, skipped }

class NotificationEntry {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;

  NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
  });
}

class ActivityLogService {
  // A simple list to act as temporary storage.
  // In a real app, replace this with SharedPreferences or Database logic.
  static final List<NotificationEntry> _logs = [];

  static void addLog(NotificationEntry entry) {
    _logs.add(entry);
    print("LOG ADDED: ${entry.title} - ${entry.message} [${entry.type}]");
  }

  static List<NotificationEntry> get logs => _logs;
}
