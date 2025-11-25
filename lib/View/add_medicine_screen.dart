import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/medicine_repository.dart';
import '../services/notification_center_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final MedicineRepository _repository = MedicineRepository.instance;
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedRingtone = 'Dhum dhum';
  String _selectedRepeat = 'Everyday';
  String _selectedDose = '1 tablet'; // New state for Dose
  String _selectedPillCount = '20'; // New state for Pill count
  String _selectedInstruction = 'Before meal'; // New state for Instruction
  String? _selectedImagePath;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  int _selectedHourIndex = 8;
  int _selectedMinuteIndex = 0;
  int _selectedAmPmIndex = 0;

  // Example for Time selection
  final FixedExtentScrollController _hourController =
      FixedExtentScrollController(
    initialItem: 8,
  ); // Default to 8 AM
  final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(
    initialItem: 0,
  );
  final FixedExtentScrollController _ampmController =
      FixedExtentScrollController(
    initialItem: 0,
  ); // 0 for AM, 1 for PM

  final TextEditingController _medicineNameController = TextEditingController();

  String get _formattedTimeLabel {
    final hourDisplay = _selectedHourIndex == 0 ? 12 : _selectedHourIndex;
    final minuteLabel = _selectedMinuteIndex.toString().padLeft(2, '0');
    final period = _selectedAmPmIndex == 0 ? 'AM' : 'PM';
    return '${hourDisplay.toString().padLeft(2, '0')}:$minuteLabel $period';
  }

  DateTime get _scheduledDateTime {
    final selectedHour = _selectedHourIndex == 0 ? 12 : _selectedHourIndex;
    final isPm = _selectedAmPmIndex == 1;
    int hour24 = selectedHour % 12;
    if (isPm) {
      hour24 += 12;
    }

    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour24,
      _selectedMinuteIndex,
    );
  }

  String get _formattedDateLabel =>
      DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    _medicineNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/1.png', // Your logo
              width: 40,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, color: Colors.red, size: 24);
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'RemindMe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('View History')));
            },
            color: Colors.grey[700],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medicine Name:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _medicineNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter medicine name',
                        fillColor: Colors.grey[100],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Alarm',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 28,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add another alarm'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Time Picker (using CupertinoPicker for the scrolling effect)
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimePickerColumn(
                            _hourController,
                            List.generate(
                              12,
                              (index) => (index == 0 ? 12 : index)
                                  .toString()
                                  .padLeft(2, '0'),
                            ),
                            (index) {
                              setState(() {
                                _selectedHourIndex = index;
                              });
                            },
                          ),
                          _buildTimePickerColumn(
                            _minuteController,
                            List.generate(
                              60,
                              (index) => index.toString().padLeft(2, '0'),
                            ),
                            (index) {
                              setState(() {
                                _selectedMinuteIndex = index;
                              });
                            },
                          ),
                          _buildTimePickerColumn(
                            _ampmController,
                            ['AM', 'PM'],
                            (index) {
                              setState(() {
                                _selectedAmPmIndex = index;
                              });
                            },
                            itemHeight: 35, // Adjust item height for AM/PM
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildOptionRow(
                      context,
                      'Date',
                      _formattedDateLabel,
                      _selectDate,
                      icon: Icons.calendar_month,
                    ),

                    _buildOptionRow(
                      context,
                      'Reminder Time',
                      _formattedTimeLabel,
                      () {},
                      icon: Icons.schedule,
                      showArrow: false,
                    ),
                    const SizedBox(height: 10),

                    _buildOptionRow(context, 'Ringtone', _selectedRingtone, () {
                      _showStringPicker(
                        context,
                        'Select Ringtone',
                        ['Dhum dhum', 'Alarm 1', 'Alarm 2', 'Chime', 'Beep'],
                        _selectedRingtone,
                        (newValue) {
                          setState(() {
                            _selectedRingtone = newValue;
                          });
                        },
                      );
                    }, icon: Icons.music_note),

                    _buildOptionRow(context, 'Repeat', _selectedRepeat, () {
                      _showStringPicker(
                        context,
                        'Select Repeat',
                        ['Everyday', 'Weekdays', 'Weekends', 'Custom'],
                        _selectedRepeat,
                        (newValue) {
                          setState(() {
                            _selectedRepeat = newValue;
                          });
                        },
                      );
                    }, icon: Icons.repeat),

                    _buildOptionRow(
                      context,
                      'Dose',
                      _selectedDose,
                      () {
                        _showStringPicker(
                          context,
                          'Select Dose',
                          [
                            '1 tablet',
                            '2 tablets',
                            '1 capsule',
                            '2 capsules',
                            '5ml',
                            '10ml',
                          ],
                          _selectedDose,
                          (newValue) {
                            setState(() {
                              _selectedDose = newValue;
                            });
                          },
                        );
                      },
                      icon: Icons.medical_services_outlined,
                    ),

                    _buildOptionRow(
                      context,
                      'No of Pill in packet',
                      _selectedPillCount,
                      () {
                        _showNumberPicker(
                          context,
                          'Pills in Packet',
                          20, // Initial value
                          1, // Min value
                          100, // Max value
                          (newValue) {
                            setState(() {
                              _selectedPillCount = newValue.toString();
                            });
                          },
                        );
                      },
                      icon: Icons.numbers,
                    ),

                    _buildPhotoPicker(context),

                    _buildOptionRow(
                      context,
                      'Instruction',
                      _selectedInstruction,
                      () {
                        _showStringPicker(
                          context,
                          'Select Instruction',
                          [
                            'Before meal',
                            'After meal',
                            'With food',
                            'Empty stomach',
                            'As directed',
                          ],
                          _selectedInstruction,
                          (newValue) {
                            setState(() {
                              _selectedInstruction = newValue;
                            });
                          },
                        );
                      },
                      icon: Icons.notes,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: _AnimatedButton(
                            onPressed: _handleAddMedicine,
                            buttonText: _isSaving ? 'Saving...' : 'ADD',
                            backgroundColor: const Color(0xFFF06292),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _AnimatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            buttonText: 'Back',
                            backgroundColor:
                                Colors.grey[300]!, // Light grey for back
                            textColor: Colors.grey[800]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerColumn(
    FixedExtentScrollController controller,
    List<String> items,
    ValueChanged<int> onSelected, {
    double itemHeight = 40.0,
  }) {
    return SizedBox(
      width: 80, // Adjust width as needed
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: itemHeight,
        onSelectedItemChanged: onSelected,
        children: items
            .map(
              (item) => Center(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildOptionRow(
    BuildContext context,
    String title,
    String value,
    VoidCallback onTap, {
    IconData? icon,
    Widget? trailingWidget,
    bool showArrow = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black54, size: 24),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const Spacer(),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              if (trailingWidget != null) trailingWidget,
              if (showArrow)
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _selectedImagePath == null
                  ? Container(
                      width: 60,
                      height: 60,
                      color: Colors.white,
                      child: const Icon(
                        Icons.photo,
                        color: Colors.grey,
                      ),
                    )
                  : Image.file(
                      File(_selectedImagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medicine Photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedImagePath == null
                        ? 'Add a clear photo to help elders identify pills.'
                        : 'Photo added. Tap change to replace.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: _pickMedicineImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_selectedImagePath == null ? 'Add' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStringPicker(
    BuildContext context,
    String title,
    List<String> options,
    String currentValue,
    ValueChanged<String> onSelected,
  ) {
    int initialIndex = options.indexOf(currentValue);
    if (initialIndex == -1) initialIndex = 0; // Fallback

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250, // Increased height for better visibility
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    onSelected(options[index]);
                  },
                  children: options
                      .map((option) => Center(child: Text(option)))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickMedicineImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedImagePath = picked.path;
    });
  }

  Future<void> _handleAddMedicine() async {
    if (_isSaving) return;

    final name = _medicineNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final generatedId = DateTime.now().millisecondsSinceEpoch.toString();
      final entry = MedicineEntry(
        id: generatedId,
        name: name,
        dosage: _selectedDose,
        scheduledDateTime: _scheduledDateTime,
        repeat: _selectedRepeat,
        ringtone: _selectedRingtone,
        pillCount: int.tryParse(_selectedPillCount) ?? 0,
        instruction: _selectedInstruction,
        // ✅ FIXED: Check if path is null, use empty string if so
        imagePath: _selectedImagePath ?? '',
      );

      await _repository.addMedicine(entry);
      await NotificationCenterService.addNotification(
        NotificationEntry(
          id: 'added-$generatedId',
          title: '${entry.name} scheduled',
          message:
              '${entry.dosage} on ${DateFormat('EEE, MMM d • h:mm a').format(_scheduledDateTime)}',
          timestamp: DateTime.now(),
          type: 'info',
          metadataTag: 'added-$generatedId',
        ),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name saved successfully.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save medicine. Please retry.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      } else {
        _isSaving = false;
      }
    }
  }

  void _showNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    int minValue,
    int maxValue,
    ValueChanged<int> onSelected,
  ) {
    int initialIndex = currentValue - minValue;
    if (initialIndex < 0 || initialIndex >= (maxValue - minValue + 1)) {
      initialIndex = 0; // Fallback
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: initialIndex,
                  ),
                  onSelectedItemChanged: (int index) {
                    onSelected(minValue + index);
                  },
                  children: List.generate(maxValue - minValue + 1, (index) {
                    return Center(child: Text((minValue + index).toString()));
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Animated Button Widget for subtle feedback
class _AnimatedButton extends StatefulWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _AnimatedButton({
    required this.buttonText,
    required this.onPressed,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95, // Scale down to 95%
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.4),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          child: Text(
            widget.buttonText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
