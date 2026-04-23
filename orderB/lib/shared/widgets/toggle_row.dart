import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A settings/notification toggle row.
class ToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
  final bool showDivider;

  const ToggleRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.disabled = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: disabled || onChanged == null
                      ? null
                      : () => onChanged!(!value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: value ? AppColors.sage : theme.dividerColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      alignment:
                          value ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: colors.onSurface.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 0),
        ],
      ),
    );
  }
}

/// A profile/settings menu row with icon, labels, and chevron.
class ProfileMenuRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDivider;

  const ProfileMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        color: theme.textTheme.bodySmall?.color, size: 20),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 0),
        ],
      ),
    );
  }
}
