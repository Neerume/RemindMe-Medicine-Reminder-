import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:remind_me/routes.dart';
import 'package:remind_me/services/notification_service.dart';
import 'View/alarm_screen.dart';

// GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized");
  } catch (e) {
    debugPrint("⚠️ Firebase Warning: $e");
  }

  // 2. Timezone
  tz.initializeTimeZones();

  // 3. Init Notifications
  await NotificationService.init(navigatorKey);

  // 4. CHECK IF LAUNCHED VIA NOTIFICATION (Lock Screen Logic)
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  String initialRoute = AppRoutes.splash;
  Object? initialArgs;

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
    if (payload != null) {
      debugPrint("🚀 App Launched via Alarm: $payload");
      initialRoute = '/alarm';
      initialArgs = payload;
    }
  }

  runApp(MyApp(initialRoute: initialRoute, initialArgs: initialArgs));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final Object? initialArgs;

  const MyApp({
    super.key,
    required this.initialRoute,
    this.initialArgs,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xffFF9FA0);

    return MaterialApp(
      title: 'RemindMe',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: const Color(0xffE8E9FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),

      // SET INITIAL ROUTE LOGIC
      initialRoute: initialRoute,

      // DEFINE ROUTES
      onGenerateRoute: (settings) {
        // If the app launches directly to Alarm, pass arguments
        if (settings.name == '/alarm') {
          // Use args passed in main() if available, otherwise use settings.arguments
          final args = settings.arguments ?? initialArgs;
          return MaterialPageRoute(
            builder: (context) => const AlarmScreen(),
            settings: RouteSettings(name: '/alarm', arguments: args),
          );
        }

        // Standard Routes
        if (AppRoutes.routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: AppRoutes.routes[settings.name]!,
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
