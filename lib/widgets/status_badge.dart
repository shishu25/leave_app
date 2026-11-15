import 'package:flutter/material.dart';
import '../models/leave_models.dart';
import '../theme/app_theme.dart';

/// Small pill showing Pending / Approved / Rejected.
class StatusBadge extends StatelessWidget {
  final LeaveStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      LeaveStatus.approved => (AppColors.successSoft, AppColors.success, 'Approved'),
      LeaveStatus.rejected => (AppColors.dangerSoft, AppColors.danger, 'Rejected'),
      LeaveStatus.pending => (AppColors.warningSoft, AppColors.warning, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
