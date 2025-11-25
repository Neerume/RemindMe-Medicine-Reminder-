import 'package:flutter/material.dart';

// Import all screen files from the 'View/' directory
// Make sure these paths and class names are correct!
import 'View/splash_screen.dart';
import 'View/signup.dart';
import 'View/verification.dart';
import 'View/name.dart';
import 'View/dashboard_screen.dart';
import 'View/add_medicine_screen.dart'; // Assuming this is the correct file for AddMedicineScreen
import 'View/view_all_medicine.dart'; // Assuming this is the correct file for ViewAllMedicinesScreen
import 'View/caregiver_screen.dart';
import 'View/profile_screen.dart';
// If you have a 'new.dart' in View folder and want to use it, uncomment and specify class
// import 'View/new.dart';

class AppRoutes {
  static const String splash = '/'; // Often '/' is used for the initial route
  static const String signup = '/signup';
  static const String verify = '/verify';
  static const String name = '/name';
  static const String dashboard = '/dashboard';
  static const String addMedicine = '/add_medicine'; // Renamed for consistency
  static const String viewAll = '/view_all'; // Renamed for consistency
    static const String caregiver = '/caregiver';
    static const String profile = '/profile';
  static const String newScreen =
      '/new_screen'; // If you actually have a new screen

  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (context) => const SplashScreen(),
    AppRoutes.signup: (context) => const SignupPage(),

    // Handle the verify route with either Firebase SMS or demo OTP arguments
    AppRoutes.verify: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final phoneNumber = args['phoneNumber'] as String?;
        final mode = args['mode'] as String? ?? 'firebase';
        if (phoneNumber == null) {
          return const SignupPage();
        }
        if (mode == 'demo') {
          final otp = args['otp'] as String?;
          final expiresAtMillis = args['expiresAt'] as int?;
          final validitySeconds = args['validity'] as int? ?? 120;
          if (otp != null && expiresAtMillis != null) {
            return VerificationPage(
              mode: VerificationMode.demo,
              phoneNumber: phoneNumber,
              otp: otp,
              expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMillis),
              validity: Duration(seconds: validitySeconds),
            );
          }
        } else {
          final verificationId = args['verificationId'] as String?;
          final resendToken = args['resendToken'] as int?;
          if (verificationId != null && verificationId.isNotEmpty) {
            return VerificationPage(
              mode: VerificationMode.firebase,
              phoneNumber: phoneNumber,
              verificationId: verificationId,
              resendToken: resendToken,
            );
          }
        }
      }
      return const SignupPage();
    },

    AppRoutes.name: (context) => const NamePage(),
    AppRoutes.dashboard: (context) => const DashboardScreen(),
    AppRoutes.addMedicine: (context) => const AddMedicineScreen(),
    AppRoutes.viewAll: (context) => const ViewAllMedicinesScreen(),
    AppRoutes.caregiver: (context) => const CaregiverScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
    // AppRoutes.newScreen: (context) => const NewScreenPage(), // Uncomment if you have this
  };
}
