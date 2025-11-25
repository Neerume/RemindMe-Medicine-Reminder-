import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ✅ FIXED: Changed 'remindme' to 'remind_me' to match your pubspec.yaml project name
import 'package:remind_me/main.dart';

void main() {
  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // NOTE: I removed the "Counter" logic (finding '0' and '+' icon)
    // because your Medicine Reminder app likely doesn't have them.

    // Instead, this checks if the app builds the main UI container successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
