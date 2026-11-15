import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'employee_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String companyName = 'Horizon & Co.';

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final isMobile = size == ScreenSize.mobile;

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 48,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(isMobile: isMobile),
                SizedBox(height: isMobile ? 48 : 72),
                _Header(),
                const SizedBox(height: 40),
                isMobile
                    ? Column(
                        children: [
                          _EmployeeLoginCard(
                              onSignIn: () => _goToDashboard(context)),
                          const SizedBox(height: 20),
                          _AdminLoginCard(
                              onSignIn: () => _goToAdminDashboard(context)),
                        ],
                      )
                    : Center(
                        child: Wrap(
                          spacing: 28,
                          runSpacing: 28,
                          alignment: WrapAlignment.center,
                          children: [
                            SizedBox(
                              width: 320,
                              child: _EmployeeLoginCard(
                                onSignIn: () => _goToDashboard(context),
                              ),
                            ),
                            SizedBox(
                              width: 320,
                              child: _AdminLoginCard(
                                onSignIn: () => _goToAdminDashboard(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 56),
                Text(
                  '© $companyName · All leave data is private and role-protected',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textFaint),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()),
    );
  }

  void _goToAdminDashboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isMobile;
  const _TopBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.badge_outlined, size: 22, color: AppColors.primary),
        SizedBox(width: 10),
        Text(
          'LEAVE PORTAL',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final help = const Text.rich(
      TextSpan(
        text: 'Need help? ',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        children: [
          TextSpan(
            text: 'Contact HR',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [brand, const SizedBox(height: 8), help],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [brand, help],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.rotate_right, color: AppColors.ground, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          HomeScreen.companyName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'Office Leave Management',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _EmployeeLoginCard extends StatelessWidget {
  final VoidCallback onSignIn;
  const _EmployeeLoginCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return _LoginCard(
      iconBg: AppColors.primarySoft,
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      title: 'Employee Login',
      idLabel: 'Employee ID',
      idHint: 'e.g. EMP-0245',
      buttonChild: ElevatedButton(
        onPressed: onSignIn,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        child: const Text('Sign In'),
      ),
    );
  }
}

class _AdminLoginCard extends StatelessWidget {
  final VoidCallback onSignIn;
  const _AdminLoginCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return _LoginCard(
      iconBg: AppColors.accentSoft,
      icon: Icons.admin_panel_settings_outlined,
      iconColor: AppColors.accent,
      title: 'Admin Login',
      idLabel: 'Admin Email',
      idHint: 'admin@company.com',
      buttonChild: OutlinedButton(
        onPressed: onSignIn,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        child: const Text('Sign In'),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String idLabel;
  final String idHint;
  final Widget buttonChild;

  const _LoginCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.idLabel,
    required this.idHint,
    required this.buttonChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          Text(idLabel,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(decoration: InputDecoration(hintText: idHint)),
          const SizedBox(height: 14),
          const Text('Password',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const TextField(obscureText: true, decoration: InputDecoration(hintText: '••••••••')),
          const SizedBox(height: 18),
          buttonChild,
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?', style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}
