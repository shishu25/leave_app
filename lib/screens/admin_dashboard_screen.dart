import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_models.dart';
import '../theme/app_theme.dart';
import '../utils/leave_data_service.dart';
import '../widgets/status_badge.dart';

/// Admin panel: reviews every pending leave request across the company.
/// Selecting a request opens a detail view showing that person's previous
/// leave history alongside the current request, with Approve / Reject actions.
/// The decision is written back to the employee's record via the data service.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminDashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LeaveDataService.instance.fetchAdminDashboardData();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _openRequest(EmployeeRecord record, LeaveApplication application) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminReviewScreen(
          record: record,
          application: application,
        ),
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _data == null) {
      return const Scaffold(
        backgroundColor: AppColors.ground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final data = _data!;
    final isMobile = screenSizeOf(context) == ScreenSize.mobile;
    final pending = data.pendingEmployees;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            _AdminTopBar(admin: data.admin, companyName: data.companyName),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 48,
                  vertical: isMobile ? 20 : 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AdminSummary(data: data),
                      const SizedBox(height: 28),
                      _PendingSection(
                        employees: pending,
                        isMobile: isMobile,
                        onTap: _openRequest,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final Admin admin;
  final String companyName;
  const _AdminTopBar({required this.admin, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.accent,
        border: Border(bottom: BorderSide(color: AppColors.accentDark)),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, size: 22, color: AppColors.ground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$companyName · Admin Panel',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ground,
                letterSpacing: 0.3,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.ground,
            child: Text(
              admin.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              admin.fullName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.logout, size: 16, color: AppColors.ground),
            label: const Text(
              'Logout',
              style: TextStyle(color: AppColors.ground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSummary extends StatelessWidget {
  final AdminDashboardData data;
  const _AdminSummary({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.employees.length;
    final pending = data.totalPending;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pending_actions, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${data.admin.fullName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${data.admin.designation} · ${data.companyName}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatPill(label: 'Total Employees', value: '$total')),
              const SizedBox(width: 14),
              Expanded(child: _StatPill(label: 'Pending Requests', value: '$pending', highlight: true)),
              const SizedBox(width: 14),
              Expanded(
                child: _StatPill(
                  label: 'Reviewed',
                  value: '${data.employees.where((e) => e.currentPending == null).length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _StatPill({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.warningSoft : AppColors.ground,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: highlight ? AppColors.warning : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: highlight ? AppColors.warning : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PendingSection extends StatelessWidget {
  final List<EmployeeRecord> employees;
  final bool isMobile;
  final void Function(EmployeeRecord, LeaveApplication) onTap;

  const _PendingSection({
    required this.employees,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Text(
                  'Pending Leave Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    '${employees.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (employees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'No pending requests. All caught up!',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            )
          else
            Column(
              children: employees.map((record) {
                final app = record.currentPending!;
                return _PendingRow(
                  record: record,
                  application: app,
                  isMobile: isMobile,
                  onTap: () => onTap(record, app),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final EmployeeRecord record;
  final LeaveApplication application;
  final bool isMobile;
  final VoidCallback onTap;

  const _PendingRow({
    required this.record,
    required this.application,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d');
    final emp = record.employee;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                emp.initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${emp.designation} · ${emp.department}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${leaveTypeToString(application.type).replaceAll(' Leave', '')} · '
          '${dateFmt.format(application.startDate)} – ${dateFmt.format(application.endDate)} '
          '(${application.durationInDays}d)',
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          application.reason,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Review →', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    StatusBadge(status: application.status),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Review →', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Detail / review screen for a single pending request. Shows the employee's
/// profile, the current request, and their previous leave history, so the
/// admin can decide with full context. Approve / Reject writes back to the
/// employee's record.
class AdminReviewScreen extends StatefulWidget {
  final EmployeeRecord record;
  final LeaveApplication application;

  const AdminReviewScreen({
    super.key,
    required this.record,
    required this.application,
  });

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final TextEditingController _remarkController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _decide(LeaveStatus decision) async {
    setState(() => _submitting = true);
    final remark = _remarkController.text.trim();
    await LeaveDataService.instance.resolveLeaveRequest(
      employeeId: widget.record.employee.id,
      applicationId: widget.application.id,
      decision: decision,
      adminRemark: remark.isEmpty
          ? (decision == LeaveStatus.approved
              ? 'Approved by administrator.'
              : 'Rejected by administrator.')
          : remark,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          decision == LeaveStatus.approved
              ? 'Leave approved for ${widget.record.employee.fullName}.'
              : 'Leave rejected for ${widget.record.employee.fullName}.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSizeOf(context) == ScreenSize.mobile;
    final emp = widget.record.employee;
    final app = widget.application;

    return Scaffold(
      backgroundColor: AppColors.ground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Review Leave Request',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmployeeHeader(employee: emp),
                  const SizedBox(height: 20),
                  _CurrentRequestCard(application: app),
                  const SizedBox(height: 20),
                  _HistoryCard(history: widget.record.history),
                  const SizedBox(height: 20),
                  _DecisionCard(submission: _remarkController),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _decide(LeaveStatus.rejected),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _decide(LeaveStatus.approved),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ground),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  final Employee employee;
  const _EmployeeHeader({required this.employee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              employee.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ground,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${employee.designation} · ${employee.department}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Text('ID: ${employee.id}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(employee.email,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text('General: ${employee.generalLeaveBalance}d · Sick: ${employee.sickLeaveBalance}d',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentRequestCard extends StatelessWidget {
  final LeaveApplication application;
  const _CurrentRequestCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return _SectionCard(
      title: 'Current Request',
      icon: Icons.event_note_outlined,
      iconColor: AppColors.warning,
      iconBg: AppColors.warningSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                leaveTypeToString(application.type),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: application.status),
            ],
          ),
          const SizedBox(height: 10),
          _kv('Request ID', application.id),
          _kv('Applied on', dateFmt.format(application.appliedOn)),
          _kv(
            'Duration',
            '${dateFmt.format(application.startDate)} – ${dateFmt.format(application.endDate)} '
                '(${application.durationInDays} days)',
          ),
          _kv('Reason', application.reason),
          if (application.documentName != null) _kv('Document', application.documentName!),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final List<LeaveApplication> history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return _SectionCard(
      title: 'Previous Leave History',
      icon: Icons.history,
      iconColor: AppColors.primary,
      iconBg: AppColors.primarySoft,
      child: history.isEmpty
          ? const Text(
              'No previous leave records for this employee.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            )
          : Column(
              children: history.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.ground,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${leaveTypeToString(a.type)} · '
                              '${dateFmt.format(a.startDate)} – ${dateFmt.format(a.endDate)} '
                              '(${a.durationInDays}d)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(a.reason,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (a.adminRemark != null && a.adminRemark!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Admin: ${a.adminRemark}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textMuted)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(status: a.status),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  final TextEditingController submission;
  const _DecisionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Admin Remark',
      icon: Icons.rate_review_outlined,
      iconColor: AppColors.accent,
      iconBg: AppColors.accentSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This note is saved with the decision and shown to the employee.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: submission,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add a remark (optional)…'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

Widget _kv(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}
