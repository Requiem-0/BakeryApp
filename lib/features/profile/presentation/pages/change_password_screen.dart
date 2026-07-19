import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/responsive.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Password updated');
      context.pop();
    } else {
      AppToast.error(
          context, auth.errorMessage ?? 'Could not change password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 8, Responsive.horizontalPadding(context), 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Change Password',
                      style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 0, Responsive.horizontalPadding(context), 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PasswordField(
                        label: 'CURRENT PASSWORD',
                        controller: _oldCtrl,
                        obscure: _obscureOld,
                        onToggle: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Enter your current password'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _PasswordField(
                        label: 'NEW PASSWORD',
                        controller: _newCtrl,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter a new password';
                          }
                          if (v.length < 6) {
                            return 'Must be at least 6 characters';
                          }
                          if (v == _oldCtrl.text) {
                            return 'New password must differ from current';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _PasswordField(
                        label: 'CONFIRM NEW PASSWORD',
                        controller: _confirmCtrl,
                        obscure: _obscureConfirm,
                        onToggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirm your new password';
                          }
                          if (v != _newCtrl.text) {
                            return "Passwords don't match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Update Password',
                        isLoading: auth.isBusy,
                        onTap: _submit,
                      ),
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

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.outline,
              ),
              onPressed: onToggle,
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                minimumSize: WidgetStatePropertyAll(Size(40, 40)),
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
