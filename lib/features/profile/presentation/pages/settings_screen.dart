import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../../core/brandkit/theme_provider.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/service_icon.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_shared_widgets.dart';
import '../../../../core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showReactivateDialog(BuildContext context) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reactivate Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your account was deactivated. Enter your credentials to '
              'reactivate it.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email or Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(100, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      if (!context.mounted) return;
      AppToast.error(context, 'Please fill in both fields.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.reactivate(
      emailOrPhone: email,
      password: password,
    );
    if (!context.mounted) return;
    if (success) {
      AppToast.success(context, 'Account reactivated. Welcome back!');
    } else {
      AppToast.error(
          context, auth.errorMessage ?? 'Reactivation failed. Try again.');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your account will be permanently disabled and you will be '
          'signed out. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(100, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 44),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.deactivate();
    if (!context.mounted) return;
    if (ok) {
      AppToast.error(context, 'Account deleted.');
      context.go('/home');
    } else {
      AppToast.error(
          context, auth.errorMessage ?? 'Could not delete account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 8, Responsive.horizontalPadding(context), 20),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Settings', style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 0, Responsive.horizontalPadding(context), 40),
                children: [
                  const SectionLabel('APPEARANCE'),
                  const SizedBox(height: 8),
                  ToggleCard(children: [
                    ToggleRow(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark Mode',
                      sub: themeProv.isDark
                          ? 'On — using a dark theme'
                          : 'Off — using a light theme',
                      value: themeProv.isDark,
                      onChanged: (_) => themeProv.toggle(),
                      showDivider: false,
                    ),
                  ]),
                  // Authenticated users see account management (password, delete).
                  // Guests see "Reactivate Account" to restore a deactivated
                  // profile.
                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 16),
                    const SectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    ToggleCard(children: [
                      _buildLinkRow(
                        context,
                        Icons.lock_outline_rounded,
                        'Change Password',
                        null,
                        onTap: () =>
                            context.push('/profile/settings/change-password'),
                      ),
                      _buildLinkRow(
                        context,
                        Icons.person_off_outlined,
                        'Delete Account',
                        null,
                        destructive: true,
                        showDivider: false,
                        onTap: () => _confirmDeleteAccount(context),
                      ),
                    ]),
                  ] else ...[
                    const SizedBox(height: 16),
                    const SectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    ToggleCard(children: [
                      _buildLinkRow(
                        context,
                        Icons.replay_rounded,
                        'Reactivate Account',
                        null,
                        showDivider: false,
                        onTap: () => _showReactivateDialog(context),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  const SectionLabel('ABOUT'),
                  const SizedBox(height: 8),
                  ToggleCard(children: [
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snap) {
                        // Until the platform reply lands (typically one
                        // frame on native, slightly longer on web), show
                        // a blank value rather than flashing a stale
                        // hardcoded number — the row stays the same
                        // height because the trailing widget is always
                        // either a Text or a chevron.
                        return _buildLinkRow(
                          context,
                          Icons.info_outline_rounded,
                          'Version',
                          snap.data?.version ?? '…',
                          showDivider: false,
                        );
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkRow(BuildContext context, IconData icon, String label,
      String? valueText,
      {bool showDivider = true,
      bool destructive = false,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final tint =
        destructive ? theme.colorScheme.error : theme.colorScheme.primary;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: ServiceIcon(
            icon: icon,
            iconColor: tint,
            backgroundColor: tint.withValues(alpha: 0.1),
          ),
          title: Text(label,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: destructive ? tint : null,
                fontWeight: destructive ? FontWeight.w600 : null,
              )),
          trailing: valueText != null
              ? Text(valueText,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13))
              : Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline, size: 20),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }
}
