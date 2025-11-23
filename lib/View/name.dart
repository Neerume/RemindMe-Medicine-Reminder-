import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:remindme/config/api.dart';
import '../routes.dart';

class NamePage extends StatefulWidget {
  final String phoneNumber; // Pass phone number from OTP screen
  const NamePage({super.key, required this.phoneNumber});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitName() async {
    final name = nameController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": widget.phoneNumber,
          "name": name.isEmpty ? null : name,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        _showSnack("Welcome ${data['user']['name']}!");

        // Navigate to dashboard
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      } else {
        _showSnack(data['error'] ?? "Something went wrong!");
      }
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// ---------------------- LOGO ------------------------
                Image.asset(
                  "assets/1.png",
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),

                /// ---------------------- TITLE ------------------------
                const Text(
                  "Enter your name",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                /// ---------------------- NAME INPUT ------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8E9FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: nameController,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your name...",
                      hintStyle: TextStyle(color: Colors.black38),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// ---------------------- DONE BUTTON ------------------------
                SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF9FA0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitName,
                    child: Text(
                      _isLoading ? "Submitting..." : "Done",
                      style: const TextStyle(
                        fontSize: 19,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// ---------------------- SKIP BUTTON ------------------------
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    // Skip → call backend with no name to save default
                    _submitName();
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
