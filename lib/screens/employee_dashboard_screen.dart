import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leave_models.dart';
import '../theme/app_theme.dart';
import '../utils/leave_data_service.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/status_badge.dart';
import '../widgets/summary_card.dart';
import 'request_leave_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LeaveDataService.instance.fetchDashboardData();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _openRequestForm() async {
    final data = _data;
    if (data == null) return;
    final newApp = await Navigator.of(context).push<LeaveApplication>(
      MaterialPageRoute(
        builder: (_) => const RequestLeaveScreen(),
        fullscreenDialog: true,
      ),
    );
    if (newApp != null) {
      setState(() {
        _data = DashboardData(
          companyName: data.companyName,
          employee: data.employee,
          applications: [newApp, ...data.applications],
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application submitted — status: Pending')),
        );
      }
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

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(companyName: data.companyName, isMobile: isMobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 48,
                  vertical: isMobile ? 20 : 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileCard(
                        employee: data.employee,
                        isMobile: isMobile,
                        onRequestLeave: _openRequestForm,
                      ),
                      const SizedBox(height: 28),
                      ResponsiveGrid(
                        desktopColumns: 4,
                        tabletColumns: 2,
                        mobileColumns: 1,
                        children: [
                          SummaryCard(
                            icon: Icons.event_note_outlined,
                            iconBg: AppColors.primarySoft,
                            iconColor: AppColors.primary,
                            label: 'General Leave Balance',
                            value: '${data.employee.generalLeaveBalance}',
                            unit: 'days',
                          ),
                          SummaryCard(
                            icon: Icons.health_and_safety_outlined,
                            iconBg: AppColors.accentSoft,
                            iconColor: AppColors.accent,
                            label: 'Sick / Medical Balance',
                            value: '${data.employee.sickLeaveBalance}',
                            unit: 'days',
                          ),
                          SummaryCard(
                            icon: Icons.hourglass_empty,
                            iconBg: AppColors.warningSoft,
                            iconColor: AppColors.warning,
                            label: 'Pending Requests',
                            value: '${data.pendingCount}',
                          ),
                          SummaryCard(
                            icon: Icons.check_circle_outline,
                            iconBg: AppColors.successSoft,
                            iconColor: AppColors.success,
                            label: 'Total Approved (YTD)',
                            value: '${data.employee.totalApprovedDays}',
                            unit: 'days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _HistorySection(
                        applications: data.applications,
                        isMobile: isMobile,
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

class _TopBar extends StatelessWidget {
  final String companyName;
  final bool isMobile;
  const _TopBar({required this.companyName, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    isMobile ? 'Leave Portal' : '$companyName · Leave Portal',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.home_outlined, size: 16, color: AppColors.primary),
                label: const Text('Home', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.logout, size: 16, color: AppColors.accentDark),
                label: const Text('Logout',
                    style: TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Employee employee;
  final bool isMobile;
  final VoidCallback onRequestLeave;

  const _ProfileCard({
    required this.employee,
    required this.isMobile,
    required this.onRequestLeave,
  });

  @override
  Widget build(BuildContext context) {
    final avatarAndInfo = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: AppColors.primary,
          child: Text(
            employee.initials,
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(employee.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('${employee.designation} · ${employee.department}',
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 14,
                runSpacing: 2,
                children: [
                  Text('Dept. Head: ${employee.departmentHead}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(employee.phone, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(employee.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final requestButton = ElevatedButton.icon(
      onPressed: onRequestLeave,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Request New Leave'),
    );

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                avatarAndInfo,
                const SizedBox(height: 18),
                requestButton,
              ],
            )
          : Row(
              children: [
                Expanded(child: avatarAndInfo),
                const SizedBox(width: 20),
                requestButton,
              ],
            ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<LeaveApplication> applications;
  final bool isMobile;

  const _HistorySection({required this.applications, required this.isMobile});

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
            child: const Text(
              'Leave Application History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          if (isMobile)
            Column(
              children: applications
                  .map((a) => _HistoryCard(application: a))
                  .toList(),
            )
          else
            _HistoryTable(applications: applications),
        ],
      ),
    );
  }
}

class _HistoryTable extends StatelessWidget {
  final List<LeaveApplication> applications;
  const _HistoryTable({required this.applications});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.ground),
        columns: const [
          DataColumn(label: _HeaderText('Applied')),
          DataColumn(label: _HeaderText('Type')),
          DataColumn(label: _HeaderText('Duration')),
          DataColumn(label: _HeaderText('Reason')),
          DataColumn(label: _HeaderText('Document')),
          DataColumn(label: _HeaderText('Status')),
        ],
        rows: applications.map((a) {
          return DataRow(cells: [
            DataCell(Text(dateFmt.format(a.appliedOn), style: const TextStyle(color: AppColors.textPrimary))),
            DataCell(Text(leaveTypeToString(a.type).replaceAll(' Leave', ''),
                style: const TextStyle(color: AppColors.textPrimary))),
            DataCell(Text(
                '${dateFmt.format(a.startDate)} – ${dateFmt.format(a.endDate)} (${a.durationInDays}d)',
                style: const TextStyle(color: AppColors.textPrimary))),
            DataCell(SizedBox(
              width: 220,
              child: Text(a.reason, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
            )),
            DataCell(a.documentName != null
                ? Text(a.documentName!, style: const TextStyle(color: AppColors.primary, fontSize: 13))
                : const Text('—', style: TextStyle(color: AppColors.textMuted))),
            DataCell(StatusBadge(status: a.status)),
          ]);
        }).toList(),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final LeaveApplication application;
  const _HistoryCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leaveTypeToString(application.type),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14)),
              StatusBadge(status: application.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${dateFmt.format(application.startDate)} – ${dateFmt.format(application.endDate)} (${application.durationInDays}d)',
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(application.reason, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('Applied ${dateFmt.format(application.appliedOn)}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          if (application.documentName != null) ...[
            const SizedBox(height: 4),
            Text(application.documentName!,
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
