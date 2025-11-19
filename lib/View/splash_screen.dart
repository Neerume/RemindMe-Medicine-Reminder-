import 'package:flutter/material.dart';

// No direct import needed for SignupPage if using named routes
// import 'signup.dart'; // <--- Can remove this if only using named routes
// import 'dashboard_screen.dart'; // <--- Can remove this

// Import the routes file to use named routes
import '../routes.dart'; // Adjust path if routes.dart is not in lib/

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Navigate to the signup page using its named route
        Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/1.png',
                width: 300,
                height: 380,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red, size: 100);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
