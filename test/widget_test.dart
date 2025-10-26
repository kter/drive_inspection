// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drive_inspection/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DriveInspectionApp());

    // Allow initial frame to render
    await tester.pump();

    // The app should build successfully and contain a MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // The app should show the permission checking UI
    // (We can't test actual sensor functionality in unit tests)
    expect(find.text('Checking permissions...'), findsOneWidget);
  });
}
