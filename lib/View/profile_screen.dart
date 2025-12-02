import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

import '../Controller/userController.dart';
import '../Model/user.dart';
import '../services/report_service.dart';
import '../services/user_data_service.dart';
import '../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- Controllers ---
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isEditing = false;
  bool _isLoading = false;

  User? _user;
  File? _profileImage;
  String? base64Image;
  String? backendPhotoBase64;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    _user = await UserController().fetchProfile();
    if (_user != null) {
      _usernameController.text = _user!.name;
      _phoneController.text = _user!.phoneNumber;
      backendPhotoBase64 = _user!.photo;
      setState(() => _profileImage = null);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_user != null) {
      _user!.name = _usernameController.text.trim();
      _user!.phoneNumber = _phoneController.text.trim();
      _user!.photo = base64Image ?? backendPhotoBase64;

      setState(() => _isLoading = true);
      final success = await UserController().updateProfile(_user!);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated!')));
        setState(() => _isEditing = false);
        _fetchProfile();
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        base64Image = base64Encode(bytes);
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserDataService.clearToken();

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.signup, (route) => false);
    }
  }

  // ------------------------------------------------------------------------
  // ----------------------- REPORT GENERATION LOGIC ------------------------
  // ------------------------------------------------------------------------

  Map<String, dynamic> reportStats = {
    'totalMeds': 0,
    'takenCount': 0,
    'missedCount': 0,
    'adherence': '0%',
    'medList': <String>[]
  };

  Future<void> _generateReportData({int? month, int? year}) async {
    setState(() => _isLoading = true);

    try {
      final report = await ReportService.generateReport(month: month, year: year);
      // Map API response to your reportStats
      reportStats = {
        'totalMeds': report['totalMeds'] ?? 0,
        'takenCount': report['takenCount'] ?? 0,
        'missedCount': report['missedCount'] ?? 0,
        'adherence': report['adherence'] ?? '0%',
        'medList': List<String>.from(report['medList'] ?? []),
      };
      debugPrint("Report response: $report");
    } catch (e) {
      debugPrint("Error fetching report: $e");
      reportStats = {
        'totalMeds': 0,
        'takenCount': 0,
        'missedCount': 0,
        'adherence': '0%',
        'medList': [],
      };
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _showReportPreview({int? month, int? year}) async {
    setState(() => _isLoading = true);

    try {
      final response = await ReportService.generateReport(month: month, year: year);

      if (response['success'] == true && response['report'] != null) {
        final report = response['report'];

        // Map the backend keys correctly
        reportStats = {
          'totalMeds': report['totalMeds'] ?? 0,
          'takenCount': report['takenCount'] ?? 0,
          'missedCount': report['skippedCount'] ?? 0, // map skipped → missed
          'adherence': report['adherence'] ?? '0%',
          'medList': List<String>.from(
              report['medList']?.map((e) => e['name'] ?? '') ?? []),
        };
      }
    } catch (e) {
      debugPrint("Error fetching report: $e");
      reportStats = {
        'totalMeds': 0,
        'takenCount': 0,
        'missedCount': 0,
        'adherence': '0%',
        'medList': [],
      };
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show the dialog after updating reportStats
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: _buildReportWidget(),
                ),
                const SizedBox(height: 20),
                // Buttons for saving/sharing
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.save_alt),
                          label: const Text("Save to Gallery"),
                          onPressed: () => _saveReportToGallery(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF9FA0),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                          onPressed: () => _shareReport(context),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _shareReport(BuildContext dialogContext) async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/medical_report.png');
        await file.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Here is my Monthly Medical Report from RemindMe App.',
        );
      }
    } catch (e) {
      debugPrint("Error sharing: $e");
    }
  }

  // --- SAVE LOGIC USING GAL ---
  Future<void> _saveReportToGallery(BuildContext dialogContext) async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        // Gal handles permissions automatically
        await Gal.putImageBytes(imageBytes,
            name: "medical_report_${DateTime.now().millisecondsSinceEpoch}");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Saved to Gallery! ✅")),
        );
        Navigator.pop(dialogContext);
      }
    } on GalException catch (e) {
      if (!mounted) return; // Added check here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.type.message}")),
      );
    } catch (e) {
      if (!mounted) return; // Added check here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving: $e")),
      );
    }
  }

  Widget _buildReportWidget() {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    final dateStr =
        "${DateFormat('MMM d').format(lastMonth)} - ${DateFormat('MMM d, yyyy').format(now)}";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MONTHLY REPORT",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffFF9FA0))),
                  const SizedBox(height: 4),
                  Text("RemindMe App",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              Image.asset('assets/1.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (c, o, s) =>
                  const Icon(Icons.health_and_safety)),
            ],
          ),
          const Divider(thickness: 2, height: 30),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) as ImageProvider?
                    : (backendPhotoBase64 != null
                    ? MemoryImage(base64Decode(backendPhotoBase64!))
                as ImageProvider?
                    : null),
                child: (_profileImage == null && backendPhotoBase64 == null)
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_usernameController.text,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Phone: ${_phoneController.text}",
                      style:
                      const TextStyle(fontSize: 14, color: Colors.black54)),
                  Text("Period: $dateStr",
                      style: const TextStyle(
                          fontSize: 14, color: Colors.blueGrey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          const Text("Adherence Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCard("Total Meds", "${reportStats['totalMeds']}",
                  Colors.blue.shade50, Colors.blue),
              _buildStatCard("Taken", "${reportStats['takenCount']}",
                  Colors.green.shade50, Colors.green),
              _buildStatCard("Missed", "${reportStats['missedCount']}",
                  Colors.red.shade50, Colors.red),
            ],
          ),
          const SizedBox(height: 25),
          const Text("Active Medicines",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ...(reportStats['medList'] as List).map((medName) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.medication,
                      color: Color(0xffFF9FA0)),
                  title: Text(medName),
                )),
                if ((reportStats['medList'] as List).isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("No medicines recorded."))
              ],
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              "Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(now)}",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/1.png',
                width: 40, height: 50, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('RemindMe',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('View History'))),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Profile',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    SizedBox(height: 6),
                    Text('Update how caregivers reach you',
                        style: TextStyle(
                            fontSize: 15, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor:
                    Colors.redAccent.withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) as ImageProvider?
                        : (backendPhotoBase64 != null
                        ? MemoryImage(base64Decode(backendPhotoBase64!))
                    as ImageProvider?
                        : null),
                    child: (_profileImage == null &&
                        backendPhotoBase64 == null)
                        ? Icon(Icons.person_rounded,
                        size: 68,
                        color: Theme.of(context).primaryColor)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xffFF9FA0),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person,
                  enabled: _isEditing),
              const SizedBox(height: 18),
              _buildProfileField(
                  controller: _phoneController,
                  label: 'Phone',
                  icon: Icons.phone,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEditing
                      ? _saveProfile
                      : () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF9FA0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                      _isEditing ? 'Save Changes' : 'Edit Profile',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showReportPreview,
                    icon: const Icon(Icons.summarize_outlined,
                        color: Colors.black87),
                    label: const Text("Generate 1 Month Report",
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Logout',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
