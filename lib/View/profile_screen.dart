import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';
import '../services/user_data_service.dart'; // For getting JWT token
import '../services/medicine_history_service.dart';
import '../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  File? _profileImage;
  String? base64Image; // store image in base64
  final ImagePicker _imagePicker = ImagePicker();
  String? backendPhotoBase64; // store backend image

  @override
  void initState() {
    super.initState();
    _fetchProfileFromBackend();
  }

  /// ---------------------- FETCH PROFILE ----------------------
  Future<void> _fetchProfileFromBackend() async {
    setState(() => _isLoading = true);

    try {
      final token = await UserDataService.getToken();
      final response = await http.get(
        Uri.parse(ApiConfig.getProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _usernameController.text = data['name'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';

        setState(() {
          _profileImage = null; // reset picked image
          backendPhotoBase64 = (data['photo'] != null && data['photo'].isNotEmpty) ? data['photo'] : null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ---------------------- UPDATE PROFILE ----------------------
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final token = await UserDataService.getToken();
      final response = await http.put(
        Uri.parse(ApiConfig.updateProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": _usernameController.text.trim(),
          "photo": base64Image ?? backendPhotoBase64, // send new image if picked
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        setState(() => _isEditing = false);
        _fetchProfileFromBackend(); // refresh profile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ---------------------- LOGOUT ----------------------
  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          content: const Text('Do you want to logout?', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await UserDataService.clearToken();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.signup, (route) => false);
    }
  }

  /// ---------------------- PICK IMAGE ----------------------
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        base64Image = base64Encode(bytes);
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  /// ---------------------- UI ----------------------
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
            Image.asset('assets/1.png', width: 40, height: 50, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('RemindMe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('View History'))),
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
                    Text('Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87)),
                    SizedBox(height: 6),
                    Text('Update how caregivers reach you', style: TextStyle(fontSize: 15, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.redAccent.withOpacity(0.2),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (backendPhotoBase64 != null
                        ? MemoryImage(base64Decode(backendPhotoBase64!))
                        : null) as ImageProvider<Object>?,
                    child: (_profileImage == null && backendPhotoBase64 == null)
                        ? Icon(Icons.person_rounded, size: 68, color: Theme.of(context).primaryColor)
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
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileField(controller: _usernameController, label: 'Username', icon: Icons.person, enabled: _isEditing),
              const SizedBox(height: 18),
              _buildProfileField(controller: _phoneController, label: 'Phone', icon: Icons.phone, enabled: _isEditing, keyboardType: TextInputType.phone),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF9FA0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(_isEditing ? 'Save Changes' : 'Edit Profile', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
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
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: !enabled,
        fillColor: enabled ? Colors.white : const Color(0xfff4f5f8),
      ),
    );
  }
}
