import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/leave_models.dart';

/// Loads employee + leave data from the bundled mock_data.json asset.
///
/// This stands in for a real backend/API call. Swap the body of
/// [fetchDashboardData] for an http/dio call against your REST or
/// GraphQL endpoint when wiring up a real server — the rest of the
/// app only depends on this method's return shape.
class LeaveDataService {
  LeaveDataService._();
  static final LeaveDataService instance = LeaveDataService._();

  /// In-memory store of every employee record, keyed by employee id.
  /// Populated on first load and mutated when the admin approves/rejects.
  final Map<String, EmployeeRecord> _records = {};
  Admin? _admin;
  String _companyName = '';
  bool _loaded = false;

  final Map<String, String> _passwords = {};
  String? _adminPassword;
  bool _isAdmin = false;

  Future<bool> signIn(
      {required String id,
      required String password,
      required bool isAdmin}) async {
    await _ensureLoaded();
    signOut();
    if (isAdmin) {
      if (_admin!.id != id || _adminPassword != password) return false;
      _isAdmin = true;
    } else {
      if (!_passwords.containsKey(id) || _passwords[id] != password) {
        return false;
      }
      _currentEmployeeId = id;
    }
    return true;
  }

  void signOut() {
    _currentEmployeeId = null;
    _isAdmin = false;
  }

  Future<DashboardData> fetchDashboardData() async {
    await _ensureLoaded();
    final record = _records[_employeeIdFromConfig]!;
    return DashboardData(
      companyName: _companyName,
      employee: record.employee,
      applications: List<LeaveApplication>.from(record.applications)
        ..sort((a, b) => b.appliedOn.compareTo(a.appliedOn)),
    );
  }

  String get _employeeIdFromConfig {
    if (_currentEmployeeId == null) {
      throw StateError('Employee login required.');
    }
    return _currentEmployeeId!;
  }

  String? _currentEmployeeId;

  /// Loads and caches all employees + the admin profile from the asset.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    _companyName = json['companyName'] as String;
    _admin = Admin.fromJson(json['admin'] as Map<String, dynamic>);
    _adminPassword =
        (json['admin'] as Map<String, dynamic>)['password'] as String;

    final employees = json['employees'] as List<dynamic>;
    for (final entry in employees) {
      final map = entry as Map<String, dynamic>;
      final employee =
          Employee.fromJson(map['employee'] as Map<String, dynamic>);
      _passwords[employee.id] =
          (map['employee'] as Map<String, dynamic>)['password'] as String;
      final apps = (map['leaveApplications'] as List<dynamic>)
          .map((e) => LeaveApplication.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
      _records[employee.id] =
          EmployeeRecord(employee: employee, applications: apps);
    }
    _loaded = true;
  }

  /// Admin dashboard: the admin profile plus every employee record.
  Future<AdminDashboardData> fetchAdminDashboardData() async {
    await _ensureLoaded();
    if (!_isAdmin) throw StateError('Admin login required.');
    return AdminDashboardData(
      companyName: _companyName,
      admin: _admin!,
      employees: _records.values.toList(),
    );
  }

  /// Applies the admin's decision to a specific leave application. The
  /// updated status + remark are written back into that employee's record,
  /// so the employee sees it on their own dashboard — i.e. a rejection
  /// "updates the person's id" data too.
  Future<EmployeeRecord> resolveLeaveRequest({
    required String employeeId,
    required String applicationId,
    required LeaveStatus decision,
    String? adminRemark,
  }) async {
    await _ensureLoaded();
    if (!_isAdmin) throw StateError('Admin login required.');

    final record = _records[employeeId];
    if (record == null) {
      throw StateError('Unknown employee: $employeeId');
    }

    final updatedApps = record.applications.map((a) {
      if (a.id != applicationId) return a;
      return a.copyWith(status: decision, adminRemark: adminRemark);
    }).toList();

    final updated = record.copyWith(applications: updatedApps);
    _records[employeeId] = updated;
    return updated;
  }

  /// Simulates submitting a new leave application to the server.
  /// Returns the created record with status = pending.
  Future<LeaveApplication> submitLeaveApplication({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? documentName,
    String? medicalCertificateName,
    String? medicalCertificateData,
  }) async {
    await _ensureLoaded();
    final employeeId = _employeeIdFromConfig;
    if (reason
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => RegExp(r'[A-Za-z0-9\u0980-\u09FF]').hasMatch(word))
            .length <
        20) {
      throw ArgumentError('Please provide a reason of at least 20 words.');
    }
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date must follow start date.');
    }
    if (type == LeaveType.medical &&
        (medicalCertificateName == null ||
            medicalCertificateData == null ||
            medicalCertificateData.isEmpty)) {
      throw ArgumentError('A medical certificate is required.');
    }
    await Future.delayed(const Duration(milliseconds: 600));
    final app = LeaveApplication(
      id: 'LV-${DateTime.now().microsecondsSinceEpoch}',
      appliedOn: DateTime.now(),
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      documentName: documentName,
      medicalCertificateName: medicalCertificateName,
      medicalCertificateData: medicalCertificateData,
      status: LeaveStatus.pending,
    );

    // If loaded, attach to the current employee's record so the admin sees it.
    await _ensureLoaded();
    final id = employeeId;
    if (_records.containsKey(id)) {
      final existing = _records[id]!;
      _records[id] =
          existing.copyWith(applications: [app, ...existing.applications]);
    }
    return app;
  }
}

class DashboardData {
  final String companyName;
  final Employee employee;
  final List<LeaveApplication> applications;

  const DashboardData({
    required this.companyName,
    required this.employee,
    required this.applications,
  });

  int get pendingCount =>
      applications.where((a) => a.status == LeaveStatus.pending).length;
}
