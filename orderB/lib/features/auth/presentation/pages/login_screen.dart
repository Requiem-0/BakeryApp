import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/brandkit/app_colors.dart';
import '../../../../core/constants.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../businesses/presentation/providers/business_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final emailOrPhone = _emailOrPhoneController.text.trim();
    final password = _passwordController.text;

    final ok = await authProvider.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );

    if (!mounted) return;

    if (ok) {
      _onLoginSuccess();
      return;
    }

    // Reactivation hook: when the backend rejects login because the account
    // is deactivated, the only way back in is via /auth/reactivate. Detect
    // the error message heuristically, prompt the user, then re-issue
    // login with the same credentials on confirm.
    final message = authProvider.errorMessage ?? 'Login failed';
    if (_looksLikeDeactivated(message)) {
      final confirmed = await _confirmReactivate();
      if (!mounted) return;
      if (confirmed != true) {
        AppToast.error(context, message);
        return;
      }
      final reactivated =
          await authProvider.reactivate(emailOrPhone: emailOrPhone);
      if (!mounted) return;
      if (!reactivated) {
        AppToast.error(context,
            authProvider.errorMessage ?? 'Could not reactivate account');
        return;
      }
      final retryOk = await authProvider.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      if (!mounted) return;
      if (retryOk) {
        AppToast.success(context, 'Welcome back!');
        _onLoginSuccess();
      } else {
        AppToast.error(context,
            authProvider.errorMessage ?? 'Login failed after reactivation');
      }
      return;
    }

    AppToast.error(context, message);
  }

  void _onLoginSuccess() {
    // Defer to the next frame so the auth provider's mid-notify settles
    // before we navigate — on Flutter Web, calling pop() from inside the
    // button tap (which is itself inside the listener-cascade frame) gets
    // silently swallowed by go_router.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
      // Verify on the next frame: if pop was swallowed (location is still
      // /login), force-route to /home so the user isn't stranded.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final after = GoRouterState.of(context).uri.toString();
        if (after.startsWith('/login')) {
          context.go('/home');
        }
      });
    });
  }

  bool _looksLikeDeactivated(String message) {
    return message.toLowerCase().contains('deactivat');
  }

  Future<bool?> _confirmReactivate() {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account deactivated'),
        content: const Text(
          'This account has been deactivated. Reactivate it and sign in?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessProvider = context.watch<BusinessProvider>();
    final authProvider = context.watch<AuthProvider>();
    final business = businessProvider.current;

    // Eyebrow text — the live business name in caps, falling back to the
    // configured app name during the brief window before the business
    // endpoint resolves.
    final eyebrow =
        (business?.businessName.trim().isNotEmpty == true
                ? business!.businessName
                : AppConstants.appName)
            .toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button — only when there's something to pop back to
                // (i.e. user landed here by tapping an auth-gated action,
                // not on a cold start where /login is the root).
                if (Navigator.of(context).canPop()) ...[
                  const AppBackButton(),
                  const SizedBox(height: 24),
                ] else
                  const SizedBox(height: 8),

                // Business-name eyebrow — small uppercase line in the
                // brand primary, mirroring the design reference.
                Text(
                  eyebrow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  'Sign In',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 14),

                // Subtitle
                Text(
                  'Enter your details to continue\nyour premium experience.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : AppColors.textLight,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 44),

                // Email field label
                Text(
                  'EMAIL OR PHONE NUMBER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailOrPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'name@example.com or phone',
                    suffixIcon: Icon(
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

                const SizedBox(height: 28),

                // Password field label
                Text(
                  'PASSWORD',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark ? Colors.grey[400] : AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      style: const ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(Colors.transparent),
                        minimumSize: WidgetStatePropertyAll(Size(40, 40)),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Forgot password — right-aligned, no extra padding so the
                // tap target sits flush with the field above.
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 36),

                // Sign In Button
                PrimaryButton(
                  label: 'SIGN IN →',
                  onTap: _handleLogin,
                  isLoading: authProvider.isBusy,
                ),

                const SizedBox(height: 40),

                // Sign Up helper link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : AppColors.textLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        'Sign Up',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
