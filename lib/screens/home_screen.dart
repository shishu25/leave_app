import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/leave_data_service.dart';
import 'employee_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String companyName = 'Horizon & Co.';
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _admin = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final valid = await LeaveDataService.instance.signIn(
          id: _id.text.trim(), password: _password.text, isAdmin: _admin);
      if (!mounted) return;
      if (!valid) {
        setState(() => _error = 'Invalid ID or password.');
        return;
      }
      _password.clear();
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => _admin
              ? const AdminDashboardScreen()
              : const EmployeeDashboardScreen()));
      LeaveDataService.instance.signOut();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSizeOf(context) == ScreenSize.mobile;
    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 48),
        child: Column(children: [
          _TopBar(isMobile: isMobile),
          const SizedBox(height: 48),
          _Header(),
          const SizedBox(height: 32),
          Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Employee')),
                      ButtonSegment(value: true, label: Text('Admin')),
                    ],
                    selected: {_admin},
                    onSelectionChanged: _busy
                        ? null
                        : (value) => setState(() {
                              _admin = value.first;
                              _id.clear();
                              _password.clear();
                              _error = null;
                              _formKey.currentState?.reset();
                            }),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border)),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_admin ? 'Admin Login' : 'Employee Login',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: _id,
                                enabled: !_busy,
                                decoration: InputDecoration(
                                    labelText:
                                        _admin ? 'Admin ID' : 'Employee ID'),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter your ID.'
                                    : null),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _password,
                                enabled: !_busy,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Password'),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter your password.'
                                    : null,
                                onFieldSubmitted: (_) {
                                  if (!_busy) _signIn();
                                }),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(_error!,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            const SizedBox(height: 20),
                            ElevatedButton(
                                onPressed: _busy ? null : _signIn,
                                child: Text(_busy ? 'Signing in…' : 'Sign In')),
                          ],
                        )),
                  ),
                ]),
          )),
        ]),
      )),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isMobile;
  const _TopBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    const brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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

    const help = Text.rich(
      TextSpan(
        text: 'Need help? ',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        children: [
          TextSpan(
            text: 'Contact HR',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );

    if (isMobile) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [brand, SizedBox(height: 8), help],
      );
    }
    return const Row(
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
          child:
              const Icon(Icons.rotate_right, color: AppColors.ground, size: 26),
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
