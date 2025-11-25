import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Model/medicine.dart';
import '../Controller/medicineController.dart';
import '../services/notification_service.dart'; // Import Service

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
  String selectedDose = "1 tablet";
  String selectedPillCount = "20";
  String selectedInstruction = "Before meal";
  XFile? selectedImage;
  bool _isLoading = false;

  final List<String> repeatOptions = ["Everyday", "Weekdays", "Weekends"];
  final List<String> doseOptions = [
    "1 tablet",
    "2 tablets",
    "3 tablets",
    "1 capsule"
  ];
  final List<String> pillCounts = ["10", "20", "30", "40", "50"];
  final List<String> instructions = ["Before meal", "After meal", "Anytime"];

  @override
  void dispose() {
    medicineController.dispose();
    super.dispose();
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
    final TimeOfDay? time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() {
        selectedAlarms.clear();
        selectedAlarms.add(time);
      });
    }
  }

  String formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  Future<void> saveMedicine() async {
    if (medicineController.text.isEmpty || selectedAlarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Name and Alarm required!")));
      return;
    }
    setState(() => _isLoading = true);

    // 1. Create Medicine Object
    // We create a temporary ID based on time for local purposes,
    // though the DB will likely assign its own ID.
    final med = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: "",
      name: medicineController.text,
      time: formatTime(selectedAlarms[0]),
      repeat: selectedRepeat,
      dose: selectedDose,
      pillCount: selectedPillCount,
      instruction: selectedInstruction,
      photo: selectedImage?.path,
      createdAt: DateTime.now().toIso8601String(),
    );

    // 2. Save to Database/API
    bool success = await medicineControllerApi.addMedicine(med);

    // 3. Schedule Notification (Crucial for Reminder)
    // We schedule it regardless of API success so it works offline instantly
    await NotificationService.scheduleMedicineReminder(med);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Added & Reminder Scheduled!")));
      Navigator.pop(context);
    } else if (!success && mounted) {
      // Just a fallback message
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved locally (Offline mode)")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text("Add New Medicine",
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF0F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Container(
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
              _buildInputContainer(
                child: Column(
                  children: [
                    TextField(
                      controller: medicineController,
                      decoration: const InputDecoration(
                          labelText: "Medicine Name",
                          prefixIcon: Icon(Icons.medication_outlined,
                              color: Colors.pinkAccent),
                          border: InputBorder.none),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_filled,
                          color: Colors.blueAccent),
                      title: Text(
                          selectedAlarms.isEmpty
                              ? "Set Alarm Time"
                              : formatTime(selectedAlarms[0]),
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold)),
                      trailing: TextButton(
                          onPressed: pickTime, child: const Text("Select")),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildDropdownTile(Icons.repeat, "Repeat", selectedRepeat,
                  repeatOptions, (v) => setState(() => selectedRepeat = v!)),
              _buildDropdownTile(
                  Icons.medical_services_outlined,
                  "Dose",
                  selectedDose,
                  doseOptions,
                  (v) => setState(() => selectedDose = v!)),
              _buildDropdownTile(Icons.tag, "Quantity", selectedPillCount,
                  pillCounts, (v) => setState(() => selectedPillCount = v!)),
              _buildDropdownTile(
                  Icons.info_outline,
                  "Instruction",
                  selectedInstruction,
                  instructions,
                  (v) => setState(() => selectedInstruction = v!)),
              const SizedBox(height: 15),
              _buildInputContainer(
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
                            child: Image.file(File(selectedImage!.path),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover)),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF06292),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: _isLoading ? null : saveMedicine,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE MEDICINE",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)
          ]),
      child: child,
    );
  }

  Widget _buildDropdownTile(IconData icon, String title, String value,
      List<String> items, ValueChanged<String?> changed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)
          ]),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey),
        title: Text(title,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: changed,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
