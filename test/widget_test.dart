// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leave_app/main.dart';
import 'package:leave_app/screens/employee_dashboard_screen.dart';
import 'package:leave_app/screens/home_screen.dart';

void main() {
  // Use a wide surface so the responsive home layout renders its two login
  // cards side by side without overflowing the default 800x600 test window.
  void useWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Home screen renders login options', (WidgetTester tester) async {
    useWideSurface(tester);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const LeaveManagementApp());

    // The landing screen should show the company branding and both login cards.
    expect(find.text(HomeScreen.companyName), findsOneWidget);
    expect(find.text('Employee Login'), findsOneWidget);
    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Sign In'), findsNWidgets(2));
  });

  testWidgets('Employee sign-in opens the employee dashboard',
      (WidgetTester tester) async {
    useWideSurface(tester);

    await tester.pumpWidget(const LeaveManagementApp());

    // Tap the employee sign-in button (the first of the two "Sign In" buttons).
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    // Navigating should push the employee dashboard onto the stack.
    expect(find.byType(EmployeeDashboardScreen), findsOneWidget);
  });
}
