/// Status of a submitted leave application.
enum LeaveStatus { pending, approved, rejected }

LeaveStatus leaveStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'approved':
      return LeaveStatus.approved;
    case 'rejected':
      return LeaveStatus.rejected;
    default:
      return LeaveStatus.pending;
  }
}

String leaveStatusToString(LeaveStatus status) {
  switch (status) {
    case LeaveStatus.approved:
      return 'Approved';
    case LeaveStatus.rejected:
      return 'Rejected';
    case LeaveStatus.pending:
      return 'Pending';
  }
}

/// Leave type: General or Medical/Sick.
enum LeaveType { general, medical }

LeaveType leaveTypeFromString(String value) {
  return value.toLowerCase().contains('med')
      ? LeaveType.medical
      : LeaveType.general;
}

String leaveTypeToString(LeaveType type) {
  return type == LeaveType.medical ? 'Medical / Sick Leave' : 'General Leave';
}

/// The logged-in employee's profile + leave balances.
class Employee {
  final String id;
  final String fullName;
  final String initials;
  final String designation;
  final String department;
  final String departmentHead;
  final String phone;
  final String email;
  final int generalLeaveBalance;
  final int sickLeaveBalance;
  final int totalApprovedDays;

  const Employee({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.designation,
    required this.department,
    required this.departmentHead,
    required this.phone,
    required this.email,
    required this.generalLeaveBalance,
    required this.sickLeaveBalance,
    required this.totalApprovedDays,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      initials: json['initials'] as String,
      designation: json['designation'] as String,
      department: json['department'] as String,
      departmentHead: json['departmentHead'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      generalLeaveBalance: json['generalLeaveBalance'] as int,
      sickLeaveBalance: json['sickLeaveBalance'] as int,
      totalApprovedDays: json['totalApprovedDays'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'initials': initials,
        'designation': designation,
        'department': department,
        'departmentHead': departmentHead,
        'phone': phone,
        'email': email,
        'generalLeaveBalance': generalLeaveBalance,
        'sickLeaveBalance': sickLeaveBalance,
        'totalApprovedDays': totalApprovedDays,
      };
}

/// A single leave application record.
class LeaveApplication {
  final String id;
  final DateTime appliedOn;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? documentName;
  final String? documentUrl;
  final LeaveStatus status;
  final String? adminRemark;

  const LeaveApplication({
    required this.id,
    required this.appliedOn,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentName,
    this.documentUrl,
    required this.status,
    this.adminRemark,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'] as String,
      appliedOn: DateTime.parse(json['appliedOn'] as String),
      type: leaveTypeFromString(json['type'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      reason: json['reason'] as String,
      documentName: json['documentName'] as String?,
      documentUrl: json['documentUrl'] as String?,
      status: leaveStatusFromString(json['status'] as String),
      adminRemark: json['adminRemark'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appliedOn': appliedOn.toIso8601String(),
        'type': leaveTypeToString(type),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
        'documentName': documentName,
        'documentUrl': documentUrl,
        'status': leaveStatusToString(status),
        'adminRemark': adminRemark,
      };

  LeaveApplication copyWith({
    LeaveStatus? status,
    String? adminRemark,
  }) {
    return LeaveApplication(
      id: id,
      appliedOn: appliedOn,
      type: type,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      documentName: documentName,
      documentUrl: documentUrl,
      status: status ?? this.status,
      adminRemark: adminRemark ?? this.adminRemark,
    );
  }
}

/// The logged-in administrator's profile.
class Admin {
  final String id;
  final String fullName;
  final String initials;
  final String designation;
  final String email;

  const Admin({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.designation,
    required this.email,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      initials: json['initials'] as String,
      designation: json['designation'] as String,
      email: json['email'] as String,
    );
  }
}

/// One employee together with their full leave history — the shape the
/// admin panel works with for every person in the company.
class EmployeeRecord {
  final Employee employee;
  final List<LeaveApplication> applications;

  const EmployeeRecord({
    required this.employee,
    required this.applications,
  });

  /// The pending application this employee is currently waiting on, if any.
  LeaveApplication? get currentPending {
    for (final a in applications) {
      if (a.status == LeaveStatus.pending) return a;
    }
    return null;
  }

  /// Everything already decided (approved or rejected), newest first —
  /// this is the employee's "previous history".
  List<LeaveApplication> get history {
    final list = applications
        .where((a) => a.status != LeaveStatus.pending)
        .toList()
      ..sort((a, b) => b.appliedOn.compareTo(a.appliedOn));
    return list;
  }

  EmployeeRecord copyWith({List<LeaveApplication>? applications}) {
    return EmployeeRecord(
      employee: employee,
      applications: applications ?? this.applications,
    );
  }
}

/// Everything the admin dashboard needs: the admin profile, the company
/// name, and every employee record in the company.
class AdminDashboardData {
  final String companyName;
  final Admin admin;
  final List<EmployeeRecord> employees;

  const AdminDashboardData({
    required this.companyName,
    required this.admin,
    required this.employees,
  });

  /// Employees that currently have a pending request awaiting a decision.
  List<EmployeeRecord> get pendingEmployees =>
      employees.where((e) => e.currentPending != null).toList();

  int get totalPending => pendingEmployees.length;
}
