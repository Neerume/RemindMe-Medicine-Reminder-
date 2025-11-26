import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/user_data_service.dart';
import 'inviteScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final token = await UserDataService.getToken();
    if (token == null || token.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
      return;
    }

    final invite = await UserDataService.getInviteInfo();
    if (invite['inviterId'] != null && invite['role'] != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InviteScreen(
            inviterId: invite['inviterId']!,
            role: invite['role']!,
            inviterName: invite['inviterName'],
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/1.png',
          width: 240,
          height: 320,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
