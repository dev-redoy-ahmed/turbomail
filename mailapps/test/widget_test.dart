// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turbomail/main.dart';
import 'package:turbomail/providers/email_provider.dart';

void main() {
  testWidgets('TurboMail app smoke test', (WidgetTester tester) async {
    // Create a test EmailProvider
    final emailProvider = EmailProvider();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(TurboMailApp(emailProvider: emailProvider));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
