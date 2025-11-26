import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart';
// ✅ Import timezone packages for notifications
import 'package:timezone/data/latest.dart' as tz;

// ✅ Correct package imports (Fixes the "remindme" error)
import 'package:remind_me/routes.dart';
import 'package:remind_me/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized");
  } catch (e) {
    debugPrint("⚠️ Firebase Warning: $e");
  }

  // 2. Initialize Timezone Database (Required for Local Notifications)
  // This must run before NotificationService.init()
  tz.initializeTimeZones();

  // 3. Initialize Notification Service
  try {
    await NotificationService.init();
    debugPrint("✅ Notification Service Initialized");
  } catch (e) {
    debugPrint("⚠️ Notification Init Error: $e");
  }

=======
import 'routes.dart';
import 'services/app_navigator.dart';
import 'services/invite_link_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InviteLinkService.instance.initialize();
>>>>>>> 9be36d7 (made some changes in the caregiver sync and connection files)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Defines the primary brand color used in your other screens (Pastel Pink/Red)
    const primaryColor = Color(0xffFF9FA0);

    return MaterialApp(
      title: 'RemindMe',
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD

      // ---------------------- APP THEME ----------------------
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',

        // Define color scheme based on your specific branding color
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: const Color(0xffE8E9FF),
        ),

        // Standardize App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor:
              Colors.transparent, // Removes auto-tint in Material 3
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Standardize Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Standardize Input Fields (TextFormFields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xffE8E9FF).withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),

      // ---------------------- ROUTING ----------------------
=======
      navigatorKey: AppNavigator.key,
>>>>>>> 9be36d7 (made some changes in the caregiver sync and connection files)
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,

      // Error handling for unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(child: Text("Route not found: ${settings.name}")),
          ),
        );
      },
    );
  }
}
