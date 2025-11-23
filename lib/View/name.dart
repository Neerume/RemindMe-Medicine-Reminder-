import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your routes.dart file to use named routes
import '../routes.dart'; // Adjust this path if routes.dart is not in lib/
import '../services/user_data_service.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final TextEditingController nameController = TextEditingController();

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
                    onPressed: () async {
                      // Save user data
                      final user = FirebaseAuth.instance.currentUser;
                      final userId = user?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
                      final username = nameController.text.trim();
                      final email = user?.email ?? '';
                      final phone = user?.phoneNumber ?? '';
                      final navigator = Navigator.of(context);

                      await UserDataService.saveUserData(
                        email: email,
                        phone: phone,
                        username: username.isEmpty ? 'User${userId.substring(0, 6)}' : username,
                        userId: userId,
                      );

                      if (!mounted) return;

                      navigator.pushReplacementNamed(AppRoutes.dashboard);
                    },
                    child: const Text(
                      "Done",
                      style: TextStyle(
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
                  onPressed: () {
                    // *** CHANGE MADE HERE: Navigate to Dashboard after "Skip" ***
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.dashboard);
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
