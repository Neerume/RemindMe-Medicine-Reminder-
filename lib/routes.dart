import 'package:flutter/material.dart';
import 'View/splash_screen.dart';
import 'View/signup.dart';
import 'View/verification.dart';
import 'View/name.dart';
import 'View/dashboard_screen.dart';
import 'View/add_medicine_screen.dart';
import 'View/view_all_medicine.dart';
import 'View/caregiver_screen.dart';
import 'View/profile_screen.dart';

class AppRoutes {
  // -------------------- ROUTE NAMES --------------------
  static const String splash = '/';
  static const String signup = '/signup';
  static const String verify = '/verify';
  static const String name = '/name';
  static const String dashboard = '/dashboard';
  static const String addMedicine = '/add_medicine';
  static const String viewAll = '/view_all';
  static const String caregiver = '/caregiver';
  static const String profile = '/profile';

  // -------------------- ROUTES --------------------
  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.splash: (context) => const SplashScreen(),
    AppRoutes.signup: (context) => const SignupPage(),

    // Verification page expects arguments: phoneNumber, otp, expiresAt
    AppRoutes.verify: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final phoneNumber = args['phoneNumber'] as String?;
        final otp = args['otp'] as String?;
        final expiresAt = args['expiresAt'] as int?;

        if (phoneNumber != null && otp != null && expiresAt != null) {
          return VerificationPage(
            phoneNumber: phoneNumber,
            otp: otp,
            expiresAt: expiresAt,
          );
        }
      }
      // Fallback to signup if arguments are missing
      return const SignupPage();
    },

    AppRoutes.name: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return NamePage(phoneNumber: args);
      }
      // fallback if phone number is missing
      return const SignupPage();
    },
    AppRoutes.dashboard: (context) => const DashboardScreen(),
    AppRoutes.addMedicine: (context) => const AddMedicineScreen(),
    AppRoutes.viewAll: (context) => const ViewAllMedicinesScreen(),
    AppRoutes.caregiver: (context) => const CaregiverScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
  };
}
