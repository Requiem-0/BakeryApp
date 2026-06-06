import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/brandkit/app_colors.dart';

/// Top-anchored toast helper used in place of bottom snackbars.
///
/// Bottom snackbars overlap the primary CTAs on most of the app's screens
/// (Sign In, Place Order, Save Address) — the user can't read the message
/// without losing the button. These slide down from the top, sit above the
/// content for a few seconds, and are tap-to-dismiss.
///
/// Usage:
///   AppToast.error(context, "Couldn't sign in. Check your credentials.");
///   AppToast.success(context, 'Address saved!');
///   AppToast.info(context, 'Signed out.');
class AppToast {
  /// Default display duration. Long enough to read a one-line message,
  /// short enough not to linger when the user moves on.
  static const Duration _defaultDuration = Duration(milliseconds: 3200);

  static void error(BuildContext context, String message,
          {Duration? duration}) =>
      _show(context, message, _ToastKind.error,
          duration: duration ?? _defaultDuration);

  static void success(BuildContext context, String message,
          {Duration? duration}) =>
      _show(context, message, _ToastKind.success,
          duration: duration ?? _defaultDuration);

  static void info(BuildContext context, String message,
          {Duration? duration}) =>
      _show(context, message, _ToastKind.info,
          duration: duration ?? _defaultDuration);

  static void _show(
    BuildContext context,
    String message,
    _ToastKind kind, {
    required Duration duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastView(
        message: message,
        kind: kind,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

enum _ToastKind { error, success, info }

class _ToastView extends StatefulWidget {
  final String message;
  final _ToastKind kind;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastView({
    required this.message,
    required this.kind,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _dismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _dismissTimer?.cancel();
    try {
      await _controller.reverse();
    } catch (_) {
      // controller may have been disposed mid-reverse — safe to ignore.
    }
    if (mounted) widget.onDismiss();
  }

  ({Color background, Color foreground, IconData icon}) _palette(
      BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (widget.kind) {
      case _ToastKind.error:
        return (
          background: colors.error,
          foreground: colors.onError,
          icon: Icons.error_outline_rounded,
        );
      case _ToastKind.success:
        return (
          background: AppColors.sage,
          foreground: Colors.white,
          icon: Icons.check_circle_outline_rounded,
        );
      case _ToastKind.info:
        return (
          background: colors.primary,
          foreground: colors.onPrimary,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final palette = _palette(context);

    return Positioned(
      top: media.padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.background.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(palette.icon, color: palette.foreground, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
