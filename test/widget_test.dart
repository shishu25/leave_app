import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leave_app/main.dart';
import 'package:leave_app/screens/employee_dashboard_screen.dart';
import 'package:leave_app/screens/admin_dashboard_screen.dart';
import 'package:leave_app/utils/leave_data_service.dart';
import 'package:leave_app/models/leave_models.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  void useWideSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Role buttons display one login form at a time', (tester) async {
    useWideSurface(tester);
    await tester.pumpWidget(const LeaveManagementApp());
    expect(find.text('Employee Login'), findsOneWidget);
    expect(find.text('Admin Login'), findsNothing);
    expect(find.text('Sign In'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Employee Login'), findsNothing);
  });

  testWidgets('Login requires valid credentials', (tester) async {
    useWideSurface(tester);
    await tester.pumpWidget(const LeaveManagementApp());
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your ID.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'EMP-0312');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Sign In'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Invalid ID or password.'), findsOneWidget);
    expect(find.byType(EmployeeDashboardScreen), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(1), 'Employee@123');
    await tester.tap(find.text('Sign In'));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byType(EmployeeDashboardScreen), findsOneWidget);
    expect(find.textContaining('Tanvir'), findsWidgets);
  });

  testWidgets('Admin search opens the matching employee and leave history',
      (tester) async {
    useWideSurface(tester);
    await LeaveDataService.instance
        .signIn(id: 'ADM-0001', password: 'Admin@123', isAdmin: true);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const AdminDashboardScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nUsRaT');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('Nusrat Jahan · EMP-0245'), findsOneWidget);
    expect(find.text('Previous Leave History'), findsOneWidget);
    expect(find.text('Review request →'), findsOneWidget);
    LeaveDataService.instance.signOut();
  });

  test(
      'Medical leave requires 20 characters and a certificate, retained on review',
      () async {
    final service = LeaveDataService.instance;
    expect(
        await service.signIn(
            id: 'EMP-0312', password: 'Employee@123', isAdmin: true),
        isFalse);
    expect(
        await service.signIn(
            id: 'EMP-0312', password: 'Employee@123', isAdmin: false),
        isTrue);
    final start = DateTime(2026, 12, 1);
    // Twenty non-whitespace characters after trimming.
    final validReason = List.filled(20, 'a').join();
    Future<LeaveApplication> submit(String text, {String? certificate}) =>
        service.submitLeaveApplication(
            type: LeaveType.medical,
            startDate: start,
            endDate: start,
            reason: text,
            medicalCertificateName:
                certificate == null ? null : 'certificate.pdf',
            medicalCertificateData: certificate);
    await expectLater(submit('Too short'), throwsArgumentError);
    await expectLater(
        submit(List.filled(19, 'a').join(),
            certificate: 'data:application/pdf;base64,JVBERi0='),
        throwsArgumentError);
    await expectLater(submit(validReason), throwsArgumentError);
    const certificate = 'data:application/pdf;base64,JVBERi0=';
    final application = await submit(validReason, certificate: certificate);
    service.signOut();
    await expectLater(service.fetchDashboardData(), throwsStateError);
    expect(
        await service.signIn(
            id: 'ADM-0001', password: 'Admin@123', isAdmin: true),
        isTrue);
    final data = await service.fetchAdminDashboardData();
    final record =
        data.employees.singleWhere((r) => r.employee.id == 'EMP-0312');
    expect(record.applications.first.medicalCertificateData, certificate);
    final updated = await service.resolveLeaveRequest(
        employeeId: record.employee.id,
        applicationId: application.id,
        decision: LeaveStatus.approved);
    expect(updated.applications.first.medicalCertificateData, certificate);
    expect(updated.applications.first.status, LeaveStatus.approved);
    service.signOut();
  });
}
