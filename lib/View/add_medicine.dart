import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
// Ensure these imports exist in your project structure
import '../Model/medicine.dart';
import '../Controller/medicineController.dart';
import '../services/notification_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  // --- Controllers & Variables ---
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController pillCountController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final MedicineController medicineControllerApi = MedicineController();
  final AudioPlayer audioPlayer = AudioPlayer();

  // --- State Data ---
  List<TimeOfDay> selectedAlarms = [];
  XFile? selectedImage;
  bool _isLoading = false;

  // --- Dropdown Options ---
  String selectedRingtone = "Tone 1";
  final List<String> ringtoneOptions = ["Tone 1", "Tone 2", "Tone 3", "Tone 4"];

  String selectedRepeat = "Everyday";
  final List<String> repeatOptions = ["Everyday", "Weekdays", "Weekends"];

  String selectedDose = "1 tablet";
  final List<String> doseOptions = [
    "1 tablet",
    "2 tablets",
    "3 tablets",
    "1 capsule"
  ];

  String selectedPillCount = "20";
  final List<String> pillCounts = ["10", "20", "30", "40", "50"];

  String selectedInstruction = "Before meal";
  final List<String> instructions = ["Before meal", "After meal", "Anytime"];

  @override
  void dispose() {
    medicineController.dispose();
    doseController.dispose();
    pillCountController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  // --- Helper Methods ---

  // UPDATED METHOD HERE
  Future<void> playRingtone(String ringtoneName) async {
    // 1. Stop any currently playing sound
    await audioPlayer.stop();

    String filePath = "";
    // Note: When using AssetSource, do NOT include 'assets/' prefix.
    // The package adds it automatically.
    if (ringtoneName == "Tone 1") filePath = "sounds/tone1.wav";
    if (ringtoneName == "Tone 2") filePath = "sounds/tone2.wav";
    if (ringtoneName == "Tone 3") filePath = "sounds/tone3.wav";
    if (ringtoneName == "Tone 4") filePath = "sounds/tone4.wav";

    if (filePath.isNotEmpty) {
      try {
        // 2. Set source first (helps with buffering on some devices)
        await audioPlayer.setSource(AssetSource(filePath));

        // 3. Set volume to max to ensure we can hear it
        await audioPlayer.setVolume(1.0);

        // 4. Play
        await audioPlayer.resume();

        print("Playing sound from: assets/$filePath"); // Debug print
      } catch (e) {
        print("ERROR PLAYING SOUND: $e");
        // This will print to your console if the file is not found or pubspec is wrong
      }
    }
  }

  Future<void> pickImageCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) setState(() => selectedImage = image);
  }

  Future<void> pickImageGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => selectedImage = image);
  }

  Future<void> pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (!selectedAlarms
            .any((t) => t.hour == time.hour && t.minute == time.minute)) {
          selectedAlarms.add(time);
        }
      });
    }
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // --- NEW: Custom Ringtone Picker with Preview ---
  void _showRingtonePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // We use a local state builder so the BottomSheet can update itself (radio buttons)
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                children: [
                  const Text(
                    "Select Alarm Tone",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Tap to preview",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: ringtoneOptions.length,
                      itemBuilder: (context, index) {
                        final tone = ringtoneOptions[index];
                        return RadioListTile<String>(
                          title: Text(tone),
                          value: tone,
                          groupValue: selectedRingtone,
                          activeColor: Colors.pinkAccent,
                          secondary: IconButton(
                            icon: const Icon(Icons.play_circle_fill,
                                color: Colors.pinkAccent),
                            onPressed: () => playRingtone(tone),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              // 1. Play sound immediately
                              playRingtone(value);
                              // 2. Update local state (visual radio button)
                              setModalState(() {
                                selectedRingtone = value;
                              });
                              // 3. Update parent state
                              setState(() {
                                selectedRingtone = value;
                              });
                            }
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        audioPlayer.stop(); // Stop sound when closing
                        Navigator.pop(context);
                      },
                      child: const Text("Confirm Selection",
                          style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Ensure sound stops if user clicks outside the modal to close it
      audioPlayer.stop();
    });
  }

  // --- Save Logic ---
  Future<void> saveMedicine() async {
    if (medicineController.text.isEmpty || selectedAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and at least one Alarm required!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String primaryTime = formatTime(selectedAlarms[0]);

      final med = Medicine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: "currentUser",
        name: medicineController.text,
        time: primaryTime,
        repeat: selectedRepeat,
        dose:
            doseController.text.isNotEmpty ? doseController.text : selectedDose,
        pillCount: pillCountController.text.isNotEmpty
            ? pillCountController.text
            : selectedPillCount,
        instruction: selectedInstruction,
        photo: selectedImage?.path,
        createdAt: DateTime.now().toIso8601String(), ringtone: '',
      );

      bool success = await medicineControllerApi.addMedicine(med);
      await NotificationService.scheduleMedicineReminder(med, selectedRingtone);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added & Reminder Scheduled!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved locally (Offline mode)")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
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
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent),
        title: Text(title,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text(
          "Add New Medicine",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Name Input
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10)
                  ],
                ),
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

              // 2. Alarm Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Alarms",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        TextButton.icon(
                          onPressed: pickTime,
                          icon: const Icon(Icons.add_alarm),
                          label: const Text("Add Time"),
                        )
                      ],
                    ),
                    if (selectedAlarms.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No alarms set",
                            style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Wrap(
                        spacing: 8.0,
                        children: selectedAlarms.map((time) {
                          return Chip(
                            label: Text(formatTime(time)),
                            backgroundColor: Colors.pink.shade50,
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                selectedAlarms.remove(time);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 3. Ringtone Picker (MODIFIED)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 5)
                  ],
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.music_note, color: Colors.pinkAccent),
                  title: const Text("Ringtone",
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedRingtone,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.pinkAccent),
                    ],
                  ),
                  onTap: _showRingtonePicker, // Opens the picker to hear/select
                ),
              ),

              // 4. Other Dropdowns
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

              // 5. Manual Inputs for Count
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 5)
                  ],
                ),
                child: TextField(
                  controller: pillCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.numbers, color: Colors.pinkAccent),
                    labelText: "Total Pills Quantity (e.g. 20)",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 6. Image Picker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10)
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Medicine Photo",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.purpleAccent),
                                onPressed: pickImageCamera),
                            IconButton(
                                icon: const Icon(Icons.image,
                                    color: Colors.blueAccent),
                                onPressed: pickImageGallery),
                          ],
                        )
                      ],
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(selectedImage!.path),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 7. Action Buttons
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06292),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : saveMedicine,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SAVE MEDICINE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
