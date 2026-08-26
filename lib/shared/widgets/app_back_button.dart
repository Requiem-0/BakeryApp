import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/brandkit/app_colors.dart';

class AppBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final bool isOverlay;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.isOverlay = false,
  });

  @override
  State<AppBackButton> createState() => _AppBackButtonState();
}

class _AppBackButtonState extends State<AppBackButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasBackground = widget.isOverlay || widget.backgroundColor != null;

    final effectiveBgColor = widget.backgroundColor ??
        (widget.isOverlay
            ? AppColors.beige.withValues(alpha: _isHovered ? 0.95 : 0.85)
            : Colors.transparent);

    final effectiveIconColor = widget.color ?? colors.primary;

    final double scale = _isPressed ? 0.92 : (_isHovered ? 1.05 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed ?? () => context.pop(),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              shape: BoxShape.circle,
              border: hasBackground
                  ? Border.all(
                      color: AppColors.softBrown.withValues(alpha: 0.25),
                      width: 0.8,
                    )
                  : null,
              boxShadow: hasBackground
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                        blurRadius: _isHovered ? 6 : 3,
                        offset: const Offset(0, 1.5),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.chevron_left_rounded,
              size: 22,
              color: effectiveIconColor,
            ),
          ),
        ),
      ),
    );
  }
}


