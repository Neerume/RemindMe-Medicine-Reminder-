import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';

import '../Model/medicine.dart';
import '../Controller/medicineController.dart';
import '../services/notification_service.dart';

class EditMedicineScreen extends StatefulWidget {
  final Medicine medicine;

  const EditMedicineScreen({super.key, required this.medicine});

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  // --- Controllers ---
  late TextEditingController medicineController;
  late TextEditingController doseController;
  late TextEditingController pillCountController;

  final ImagePicker picker = ImagePicker();
  final MedicineController medicineControllerApi = MedicineController();
  final AudioPlayer audioPlayer = AudioPlayer();

  // --- State Data ---
  List<TimeOfDay> selectedAlarms = [];
  XFile? selectedImage;
  bool _isLoading = false;

  // --- Dropdown Values ---
  String selectedRingtone = "Tone 1";
  String selectedRepeat = "Everyday";
  String selectedDose = "1 tablet";
  String selectedInstruction = "Before meal";

  // --- Options Lists ---
  final List<String> ringtoneOptions = ["Tone 1", "Tone 2", "Tone 3", "Tone 4"];
  final List<String> repeatOptions = ["Everyday", "Weekdays", "Weekends"];
  final List<String> doseOptions = [
    "1 tablet",
    "2 tablets",
    "3 tablets",
    "1 capsule"
  ];
  final List<String> instructions = ["Before meal", "After meal", "Anytime"];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final med = widget.medicine;

    // 1. Initialize Controllers with existing text
    medicineController = TextEditingController(text: med.name);

    // Check if the dose is one of our dropdown options
    if (doseOptions.contains(med.dose)) {
      selectedDose = med.dose;
      doseController = TextEditingController();
    } else {
      selectedDose = doseOptions.first;
      doseController = TextEditingController(text: med.dose);
    }

    pillCountController = TextEditingController(text: med.pillCount);

    // 2. Initialize Dropdowns
    if (repeatOptions.contains(med.repeat)) selectedRepeat = med.repeat;
    if (instructions.contains(med.instruction)) {
      selectedInstruction = med.instruction;
    }

    // 3. Initialize Ringtone (✅ FIXED TYPE ERROR HERE)
    // We check if it's not null AND exists in options
    if (med.ringtone != null && ringtoneOptions.contains(med.ringtone)) {
      selectedRingtone = med.ringtone!; // Added '!' to fix the error
    }

    // 4. Initialize Image
    if (med.photo != null && med.photo!.isNotEmpty) {
      selectedImage = XFile(med.photo!);
    }

    // 5. Initialize Time
    _parseTime(med.time);
  }

  void _parseTime(String timeString) {
    try {
      final parts = timeString.split(" ");
      final timeParts = parts[0].split(":");

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts.length > 1 ? parts[1] : "AM";

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;

      selectedAlarms.add(TimeOfDay(hour: hour, minute: minute));
    } catch (e) {
      selectedAlarms.add(TimeOfDay.now());
    }
  }

  @override
  void dispose() {
    medicineController.dispose();
    doseController.dispose();
    pillCountController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  // --- Logic Helpers ---
  Future<void> pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime:
          selectedAlarms.isNotEmpty ? selectedAlarms.first : TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        selectedAlarms = [time];
      });
    }
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final hourStr = hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hourStr:$minute $period";
  }

  Future<void> pickImage(ImageSource source) async {
    final image = await picker.pickImage(source: source);
    if (image != null) setState(() => selectedImage = image);
  }

  // --- Update Logic ---
  Future<void> updateMedicine() async {
    if (medicineController.text.isEmpty || selectedAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Time are required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String primaryTime = formatTime(selectedAlarms[0]);
      String finalDose =
          doseController.text.isNotEmpty ? doseController.text : selectedDose;

      final updatedMed = Medicine(
        id: widget.medicine.id,
        userId: widget.medicine.userId,
        name: medicineController.text,
        time: primaryTime,
        repeat: selectedRepeat,
        dose: finalDose,
        pillCount: pillCountController.text,
        instruction: selectedInstruction,
        photo: selectedImage?.path,
        createdAt: widget.medicine.createdAt,
        ringtone: selectedRingtone,
      );

      // Call API
      String result =
          await medicineControllerApi.updateMedicine(updatedMed.id, updatedMed);

      bool success = result == "Success";

      if (success) {
        // ✅ FIXED: Do NOT use cancelAll(). It deletes other medicines' alarms.
        // Re-scheduling with the same ID overwrites the specific alarm automatically.
        await NotificationService.scheduleMedicineReminder(
            updatedMed, selectedRingtone);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Medicine Updated Successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $result")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- UI Components ---
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent),
        title: Text(title,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _boxDecoration(),
      child: child,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Medicine",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFE1F5FE)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Name
              _buildInputContainer(
                child: TextField(
                  controller: medicineController,
                  decoration: const InputDecoration(
                    labelText: "Medicine Name",
                    prefixIcon: Icon(Icons.medication_outlined,
                        color: Colors.pinkAccent),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Time
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _boxDecoration(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Alarm Time",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (selectedAlarms.isNotEmpty)
                          Chip(
                              label: Text(formatTime(selectedAlarms.first)),
                              backgroundColor: Colors.pink.shade50),
                        IconButton(
                            onPressed: pickTime,
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent)),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Dropdowns
              _buildDropdownTile(
                icon: Icons.repeat,
                title: "Repeat",
                value: selectedRepeat,
                items: repeatOptions,
                onChanged: (v) => setState(() => selectedRepeat = v!),
              ),
              _buildDropdownTile(
                icon: Icons.medical_services_outlined,
                title: "Dose",
                value: selectedDose,
                items: doseOptions,
                onChanged: (v) => setState(() => selectedDose = v!),
              ),
              _buildDropdownTile(
                icon: Icons.info_outline,
                title: "Instruction",
                value: selectedInstruction,
                items: instructions,
                onChanged: (v) => setState(() => selectedInstruction = v!),
              ),

              // Ringtone Dropdown (Added for completeness since controller exists)
              _buildDropdownTile(
                icon: Icons.notifications_active,
                title: "Ringtone",
                value: selectedRingtone,
                items: ringtoneOptions,
                onChanged: (v) => setState(() => selectedRingtone = v!),
              ),

              // Pill Count
              _buildInputContainer(
                child: TextField(
                  controller: pillCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.numbers, color: Colors.pinkAccent),
                    labelText: "Total Pills Quantity",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _boxDecoration(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Medicine Photo",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.purpleAccent),
                          onPressed: () => pickImage(ImageSource.camera),
                        ),
                      ],
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(selectedImage!.path),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : updateMedicine,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("UPDATE MEDICINE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
