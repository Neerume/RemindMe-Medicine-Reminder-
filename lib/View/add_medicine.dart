import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'recorder_page.dart';
import '../Model/medicine.dart';
import '../Controller/medicineController.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController medicineController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  final MedicineController medicineControllerApi = MedicineController();

  List<TimeOfDay> selectedAlarms = [];
  String selectedRepeat = "Everyday";
  final List<String> repeatOptions = ["Everyday", "Weekdays", "Weekends"];
  String selectedDose = "1 tablet";
  final List<String> doseOptions = ["1 tablet", "2 tablets", "3 tablets"];
  String selectedPillCount = "20";
  final List<String> pillCounts = ["10", "20", "30", "40"];
  String selectedInstruction = "Before meal";
  final List<String> instructions = ["Before meal", "After meal", "Anytime"];
  XFile? selectedImage;

  @override
  void dispose() {
    medicineController.dispose();
    super.dispose();
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
      setState(() {
        selectedAlarms.add(time);
      });
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

  // Convert TimeOfDay to formatted string
  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  Future<void> saveMedicine() async {
    if (medicineController.text.isEmpty || selectedAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter medicine name and at least one alarm")),
      );
      return;
    }

    final med = Medicine(
      id: "", // backend will generate
      userId: "dummyUser", // replace with actual userId
      name: medicineController.text,
      time: formatTime(selectedAlarms[0]), // first alarm for display
      repeat: selectedRepeat,
      dose: selectedDose,
      pillCount: selectedPillCount,
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

    final success = await medicineControllerApi.addMedicine(Medicine.fromJson(medJson));

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
            // Medicine Name
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Column(
                    children: selectedAlarms
                        .map((t) => Text(formatTime(t),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
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

            // Repeat
            customTile(
              icon: Icons.repeat,
              label: "Repeat",
              child: DropdownButton<String>(
                value: selectedRepeat,
                items: repeatOptions.map((item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => selectedRepeat = value);
                },
              ),
            ),

            // Dose
            customTile(
              icon: Icons.medical_services_outlined,
              label: "Dose",
              child: DropdownButton<String>(
                value: selectedDose,
                items: doseOptions.map((item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => selectedDose = value);
                },
              ),
            ),

            // Pill Count
            customTile(
              icon: Icons.tag,
              label: "No of Pills",
              child: DropdownButton<String>(
                value: selectedPillCount,
                items: pillCounts.map((item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => selectedPillCount = value);
                },
              ),
            ),

            // Add Photo
            customTile(
              icon: Icons.camera_alt_outlined,
              label: "Add Photo",
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt), onPressed: pickImageCamera),
                  IconButton(icon: const Icon(Icons.image), onPressed: pickImageGallery),
                ],
              ),
            ),

            // Instruction
            customTile(
              icon: Icons.notes,
              label: "Instruction",
              child: DropdownButton<String>(
                value: selectedInstruction,
                items: instructions.map((item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  setState(() => selectedInstruction = value);
                },
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
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
                  child: const Text("ADD", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Back", style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
