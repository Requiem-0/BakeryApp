import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Full-width gradient primary CTA button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final gradient = theme.extension<AppThemeExtension>()?.primaryGradient;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: colors.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onPrimary,
                  letterSpacing: 0.5,
                )),
      ),
    );
  }
}

/// Outline secondary button.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SecondaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: colors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
