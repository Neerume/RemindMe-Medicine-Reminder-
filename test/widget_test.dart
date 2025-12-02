import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Make sure this import matches your project name in pubspec.yaml
import 'package:remind_me/main.dart';

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // ✅ FIXED: Added 'initialRoute' parameter.
    // We pass '/' (or whatever your home route is) to satisfy the requirement.
    await tester.pumpWidget(const MyApp(initialRoute: '/'));

    // This checks if the app builds the main UI container successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
