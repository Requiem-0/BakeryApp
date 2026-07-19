import 'package:flutter/material.dart';

/// Small uppercased eyebrow text used above grouped form fields and
/// settings sections (e.g. "ACCOUNT INFO", "APPEARANCE").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(letterSpacing: 1, fontSize: 11),
    );
  }
}

/// Tighter eyebrow used directly above a single form field (sits below
/// the field's containing card padding, not above a whole section).
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}

/// Card container the Settings screen wraps grouped rows in. Just a
/// rounded bordered box with horizontal padding — children render as a
/// Column inside.
class ToggleCard extends StatelessWidget {
  final List<Widget> children;
  const ToggleCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }
}

/// Settings row with a leading icon-tile, primary label, optional
/// subtitle, and trailing Material Switch. [showDivider] paints a thin
/// hairline below the row — opt out for the last row in a card.
class ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const ToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          value: value,
          onChanged: onChanged,
          activeThumbColor: theme.cardColor,
          activeTrackColor: theme.colorScheme.primary,
          inactiveThumbColor: theme.cardColor,
          inactiveTrackColor: theme.dividerColor,
          title: Text(label, style: theme.textTheme.bodyLarge),
          subtitle: sub != null
              ? Text(sub!,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12))
              : null,
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }
}
