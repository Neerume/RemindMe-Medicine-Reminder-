import 'package:flutter/material.dart';

// Import your screens
import 'View/signup.dart';
import 'View/verification.dart';
import 'View/name.dart';
import 'View/add_medicine.dart'; // <-- NEWLY ADDED

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
      home: const AddMedicinePage(),

      /// -------------------- APP ROUTES --------------------
      routes: {
        "/signup": (context) => const SignupPage(),
        "/verify": (context) => const VerificationPage(),
        "/name": (context) => const NamePage(),
        "/addMedicine": (context) => const AddMedicinePage(), // NEW ROUTE
      },
    );
  }
}
