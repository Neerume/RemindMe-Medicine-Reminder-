import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// ✅ Import timezone packages for notifications
import 'package:timezone/data/latest.dart' as tz;

// ✅ Correct package imports
import 'package:remind_me/routes.dart';
import 'package:remind_me/services/notification_service.dart';
import 'View/alarm_screen.dart';

// 1. CREATE GLOBAL NAVIGATOR KEY (Required for Notification Navigation)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    // UPDATED: Pass the navigatorKey to the service so it can change screens
    await NotificationService.init(navigatorKey);
    debugPrint("✅ Notification Service Initialized");
  } catch (e) {
    debugPrint("⚠️ Notification Init Error: $e");
  }

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

      // 2. ASSIGN THE NAVIGATOR KEY HERE
      navigatorKey: navigatorKey,

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
      initialRoute: AppRoutes.splash,

      // UPDATED: We merge your existing routes with the new Alarm route
      routes: {
        ...AppRoutes.routes,
        '/alarm': (context) => const AlarmScreen(), // Ensure this route exists
      },

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
