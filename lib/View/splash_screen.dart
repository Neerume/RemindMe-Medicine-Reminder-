import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes.dart'; // Make sure this path is correct

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
    // Wait for 3 seconds to show splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      // User logged in, go to dashboard
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      // User not logged in, go to phone input/signup
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
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red, size: 100);
            },
          ),
        ),
      ),
    );
  }
}
