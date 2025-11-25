import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';   // 🔊 NEW
import '../Model/medicine.dart';
import '../Controller/medicineController.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController doseController = TextEditingController();
  final TextEditingController pillCountController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  final MedicineController medicineControllerApi = MedicineController();

  List<TimeOfDay> selectedAlarms = [];

  // NEW: Ringtone feature
  String selectedRingtone = "Tone 1";
  final List<String> ringtoneOptions = [
    "Tone 1",
    "Tone 2",
    "Tone 3",
    "Tone 4",
  ];

  String selectedRepeat = "Everyday";
  final List<String> repeatOptions = ["Everyday", "Weekdays", "Weekends"];
  String selectedInstruction = "Before meal";
  final List<String> instructions = ["Before meal", "After meal", "Anytime"];
  XFile? selectedImage;

  // 🔊 NEW — audio player
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    medicineController.dispose();
    doseController.dispose();
    pillCountController.dispose();
    super.dispose();
  }

  // 🔊 NEW — function to play ringtone
  Future<void> playRingtone(String ringtoneName) async {
    String file = "";

    if (ringtoneName == "Tone 1") file = "assets/sounds/tone1.wav";
    if (ringtoneName == "Tone 2") file = "assets/sounds/tone2.wav";
    if (ringtoneName == "Tone 3") file = "assets/sounds/tone3.wav";
    if (ringtoneName == "Tone 4") file = "assets/sounds/tone4.wav";

    await audioPlayer.play(
      AssetSource(file.replaceFirst("assets/", "")),
    );
  }

  Future<void> pickImageCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => selectedImage = image);
    }
  }

  Future<void> pickImageGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => selectedImage = image);
    }
  }

  Future<void> pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => selectedAlarms.add(time));
    }
  }

  Widget customTile({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 16)),
          ]),
          child,
        ],
      ),
    );
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  Future<void> saveMedicine() async {
    if (medicineController.text.isEmpty ||
        doseController.text.isEmpty ||
        pillCountController.text.isEmpty ||
        selectedAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields and add at least one alarm")),
      );
      return;
    }

    final med = Medicine(
      id: "",
      userId: "dummyUser",
      name: medicineController.text,
      time: formatTime(selectedAlarms[0]),
      repeat: selectedRepeat,
      dose: doseController.text,
      pillCount: pillCountController.text,
      instruction: selectedInstruction,
      photo: selectedImage?.path,
      createdAt: DateTime.now().toIso8601String(),
    );

 
    // Convert selectedAlarms to backend format
    final alarmsJson = selectedAlarms
        .map((t) => {"hour": t.hour, "minute": t.minute, "amPm": t.period == DayPeriod.am ? "AM" : "PM"})
        .toList();

    final medJson = med.toJson();
    medJson["alarms"] = alarmsJson;
    medJson["ringtone"] = selectedRingtone;

    final success =
    await medicineControllerApi.addMedicine(Medicine.fromJson(medJson));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medicine added successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to add medicine")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "RemindMe",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Medicine Name:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: medicineController,
                    decoration: InputDecoration(
                      hintText: "Enter medicine name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Alarms:",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  Column(
                    children: selectedAlarms
                        .map(
                          (t) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatTime(t),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              setState(() => selectedAlarms.remove(t));
                            },
                          ),
                        ],
                      ),
                    )
                        .toList(),
                  ),

                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: pickTime,
                    child: const Text("Add Alarm"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔔 NEW: Ringtone Selection
            customTile(
              icon: Icons.music_note,
              label: "Ringtone",
              child: DropdownButton<String>(
                value: selectedRingtone,
                items: ringtoneOptions
                    .map((item) =>
                    DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRingtone = value);
                    playRingtone(value); // 🔊 Play immediately
                  }
                },
              ),
            ),

            // Repeat
            customTile(
              icon: Icons.repeat,
              label: "Repeat",
              child: DropdownButton<String>(
                value: selectedRepeat,
                items: repeatOptions
                    .map((item) =>
                    DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedRepeat = value);
                },
              ),
            ),

            // Dose
            customTile(
              icon: Icons.medical_services_outlined,
              label: "Dose",
              child: SizedBox(
                width: 120,
                child: TextField(
                  controller: doseController,
                  decoration: const InputDecoration(
                    hintText: "e.g. 1 tablet",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Pills
            customTile(
              icon: Icons.tag,
              label: "No. of Pills",
              child: SizedBox(
                width: 80,
                child: TextField(
                  controller: pillCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "20",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Image Picker
            customTile(
              icon: Icons.camera_alt_outlined,
              label: "Add Photo",
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: pickImageCamera),
                  IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: pickImageGallery),
                ],
              ),
            ),

            // Instruction
            customTile(
              icon: Icons.notes,
              label: "Instruction",
              child: DropdownButton<String>(
                value: selectedInstruction,
                items: instructions
                    .map((item) =>
                    DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() => selectedInstruction = value);
                },
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: saveMedicine,
                  child: const Text("ADD",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back",
                      style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
