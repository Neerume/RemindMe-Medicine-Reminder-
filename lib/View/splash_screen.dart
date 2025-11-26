import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:shared_preferences/shared_preferences.dart';
<<<<<<< HEAD
import '../routes.dart';
=======
import '../routes.dart'; // Make sure this path is correct
=======
import '../routes.dart';
import '../services/user_data_service.dart';
import 'inviteScreen.dart';
>>>>>>> Stashed changes
>>>>>>> 9be36d7 (made some changes in the caregiver sync and connection files)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

<<<<<<< HEAD
=======
<<<<<<< Updated upstream
    // Check if user is logged in
>>>>>>> 9be36d7 (made some changes in the caregiver sync and connection files)
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('user_token');

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
=======
    final token = await UserDataService.getToken();

    if (token != null && token.isNotEmpty) {
      // Check for pending invite
      final inviteInfo = await UserDataService.getInviteInfo();

      if (inviteInfo['inviterId'] != null && inviteInfo['role'] != null) {
        // Navigate to InviteScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InviteScreen(
              inviterId: inviteInfo['inviterId']!,
              role: inviteInfo['role']!,
              inviterName: inviteInfo['inviterName'],
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
>>>>>>> Stashed changes
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/1.png',
            width: 300,
            height: 380,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
