import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/brandkit/app_colors.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetToken() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final target = _emailController.text.trim();
    
    // Determine if it looks like an email or a phone
    final isEmail = target.contains('@');
    final ok = await authProvider.sendResetToken(
      email: isEmail ? target : null,
      phone: !isEmail ? target : null,
    );

    if (mounted) {
      if (ok) {
        AppToast.success(
            context, 'Reset token sent successfully! Check your inbox.');
        // Navigate to the reset screen
        context.push('/reset-password');
      } else {
        AppToast.error(context,
            authProvider.errorMessage ?? 'Failed to send reset token');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  AppBackButton(),
                  Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot Password',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Enter your email address or phone number to receive a verification token to reset your password.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : AppColors.textLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 44),
                      
                      Text(
                        'EMAIL OR PHONE NUMBER',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'name@example.com or phone',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            color: isDark ? Colors.grey[400] : AppColors.textLight,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email or phone number';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Send Reset Token',
                        onTap: _handleSendResetToken,
                        isLoading: authProvider.isBusy,
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
