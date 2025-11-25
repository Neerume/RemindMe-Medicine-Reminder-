import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

// Ensure these imports point to your actual file locations
import '../services/user_data_service.dart';
import '../services/medicine_history_service.dart';
import '../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controller for capturing the invisible report widget
  final ScreenshotController _screenshotController = ScreenshotController();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await UserDataService.getUserData();
      _phoneController.text = userData['phone'] ?? '';
      _usernameController.text = userData['username'] ?? '';
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      if (_phoneController.text.trim().isNotEmpty) {
        await UserDataService.updatePhone(_phoneController.text.trim());
      }
      if (_usernameController.text.trim().isNotEmpty) {
        await UserDataService.updateUsername(_usernameController.text.trim());
      }
      setState(() {
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.signup, (route) => false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- REPORT GENERATION LOGIC ---
  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 1. Fetch History for Last 30 Days
      final history =
          await MedicineHistoryService.getMedicineHistoryForLastMonth();
      final userData = await UserDataService.getUserData();

      // 2. Build the Report Widget
      // We wrap it in a Scaffold/MaterialApp inside the capture method to ensure themes load
      final reportWidget = _buildReportWidgetForCapture(history, userData);

      // 3. Capture as Image
      // Using a fixed logical width (e.g. 400) ensures the layout looks like a document
      final imageBytes = await _screenshotController.captureFromWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(child: reportWidget),
          ),
        ),
        pixelRatio: 2.0, // Higher quality
        delay: const Duration(milliseconds: 150), // Give time for fonts to load
        context: context, // Inherit context for safety
      );

      // 4. Save to Temporary Directory (Safest for sharing)
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${directory.path}/RemindMe_Report_$timestamp.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // 5. Share the file
      if (!mounted) return;

      // Check if file exists before sharing
      if (await imageFile.exists()) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Here is my medicine adherence report for the last 30 days.',
          subject: 'My Medicine Report',
        );
        messenger
            .showSnackBar(const SnackBar(content: Text('Report generated!')));
      } else {
        throw Exception("Failed to save report file.");
      }
    } catch (e) {
      debugPrint("Report Generation Error: $e");
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- REPORT WIDGET UI (Invisible, used for Screenshot) ---
  Widget _buildReportWidgetForCapture(
      List<MedicineRecord> history, Map<String, String?> userData) {
    // Group by Date
    final Map<String, List<MedicineRecord>> grouped = {};
    for (var record in history) {
      final key = DateFormat('yyyy-MM-dd').format(record.dateTaken);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(record);
    }

    // Sort Dates Descending (Newest first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      width: double.infinity, // Take full width of capture context
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.health_and_safety,
                    size: 40, color: Colors.redAccent),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RemindMe App',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  Text('30-Day Adherence Report',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(thickness: 2, height: 20, color: Colors.black12),
          const SizedBox(height: 10),

          // Patient Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Patient: ${userData['username'] ?? 'User'}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Phone: ${userData['phone'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    'Report Date: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Records List
          if (sortedKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    Text(
                      'No medicines recorded in the last 30 days.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...sortedKeys.map((dateKey) {
              final records = grouped[dateKey]!;
              final displayDate = DateFormat('EEEE, MMM d, yyyy')
                  .format(DateTime.parse(dateKey));

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: records
                            .map((r) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text('${r.medicineName}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15)),
                                      ),
                                      Text('${r.dosage} • ${r.time}',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    )
                  ],
                ),
              );
            }),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Generated by RemindMe App',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Pic
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.red[100],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.redAccent)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Tap to change photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 30),

                  // Fields
                  _buildTextField(
                      "Username", _usernameController, Icons.person),
                  const SizedBox(height: 20),
                  _buildTextField("Phone", _phoneController, Icons.phone,
                      inputType: TextInputType.phone),

                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEditing
                              ? _saveProfile
                              : () => setState(() => _isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing
                                ? Colors.green
                                : const Color(0xffFF9FA0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor:
                                Colors.white, // Ensure text is white
                          ),
                          child: Text(
                              _isEditing ? 'Save Changes' : 'Edit Profile'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Report Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.description),
                      label: const Text('Generate 1-Month Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logout
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !_isEditing,
        fillColor: _isEditing ? Colors.white : Colors.grey[200],
      ),
    );
  }
}
