import 'package:flutter/material.dart';

/// Global navigator key so background services (like invite links)
/// can trigger navigation without needing BuildContext access.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
}

