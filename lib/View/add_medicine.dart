import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Controller/medicineController.dart';
import '../Model/medicine.dart';
import '../services/medicine_service.dart';
import '../services/notification_service.dart';
import '../services/user_data_service.dart';

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _pillCountController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MedicineService _medicineService = MedicineService();

  final List<TimeOfDay> _alarms = [];
  final List<String> _repeatOptions = ['Everyday', 'Weekdays', 'Weekends'];
  final List<String> _dosePresets = ['1 tablet', '2 tablets', '3 tablets', '1 capsule'];
  final List<String> _pillCountPresets = ['10', '20', '30', '40', '50'];
  final List<String> _instructions = ['Before meal', 'After meal', 'Anytime'];
  final List<String> _ringtoneOptions = ['Tone 1', 'Tone 2', 'Tone 3', 'Tone 4'];

  String _selectedRepeat = 'Everyday';
  String _selectedInstruction = 'Before meal';
  String _selectedRingtone = 'Tone 1';
  XFile? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _pillCountController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() => _alarms.add(time));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _playPreviewTone(String tone) async {
    final fileMap = {
      'Tone 1': 'assets/sounds/tone1.wav',
      'Tone 2': 'assets/sounds/tone2.wav',
      'Tone 3': 'assets/sounds/tone3.wav',
      'Tone 4': 'assets/sounds/tone4.wav',
    };
    final path = fileMap[tone];
    if (path == null) return;
    await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _alarms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a name and at least one alarm.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userId = await UserDataService.getUserId();
    print('Fetched userId: $userId');

    final medicine = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId ?? '',
      name: _nameController.text,
      time: _formatTime(_alarms.first),
      repeat: _selectedRepeat,
      dose: _doseController.text.isEmpty ? _dosePresets.first : _doseController.text,
      pillCount: _pillCountController.text.isEmpty ? _pillCountPresets.first : _pillCountController.text,
      instruction: _selectedInstruction,
      photo: _selectedImage?.path,
      createdAt: DateTime.now().toIso8601String(),
      ringtone: _selectedRingtone,
    );

    try {
      final success = await _medicineService.addMedicine(medicine); // sends JSON
      if (success) {
        await NotificationService.scheduleMedicineReminder(medicine);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine saved successfully!')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving medicine: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionHeader('Alarms'),
                  ..._alarms.map(
                    (time) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_formatTime(time)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _alarms.remove(time)),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.add_alarm),
                      label: const Text('Add alarm'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _dropdownTile(
              label: 'Repeat',
              value: _selectedRepeat,
              items: _repeatOptions,
              onChanged: (value) => setState(() => _selectedRepeat = value ?? _selectedRepeat),
            ),
            _dropdownTile(
              label: 'Instruction',
              value: _selectedInstruction,
              items: _instructions,
              onChanged: (value) => setState(() => _selectedInstruction = value ?? _selectedInstruction),
            ),
            _dropdownTile(
              label: 'Ringtone',
              value: _selectedRingtone,
              items: _ringtoneOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedRingtone = value);
                _playPreviewTone(value);
              },
            ),
            _textFieldTile(
              label: 'Dose',
              controller: _doseController,
              placeholder: _dosePresets.first,
            ),
            _textFieldTile(
              label: 'Pill count',
              controller: _pillCountController,
              placeholder: _pillCountPresets.first,
              keyboardType: TextInputType.number,
            ),
            _infoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Medicine photo'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save medicine'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _dropdownTile({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _infoCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          DropdownButton<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _textFieldTile({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return _infoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: placeholder),
          ),
        ],
      ),
    );
  }
}
