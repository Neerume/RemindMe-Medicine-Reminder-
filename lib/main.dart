import 'package:flutter/material.dart';
import 'View/signup.dart';
import 'View/verification.dart';
import 'View/name.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RemindMe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      /// -------------------- STARTUP SCREEN --------------------
      home: const SignupPage(),

      /// -------------------- NAMED ROUTES (optional) --------------------
      routes: {
        "/signup": (context) => const SignupPage(),
        "/verify": (context) => const VerificationPage(),
        "/name": (context) => const NamePage(),
      },
    );
  }
}
