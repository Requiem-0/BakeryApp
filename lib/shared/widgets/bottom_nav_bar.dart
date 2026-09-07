import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/brandkit/app_decorations.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

/// App-level bottom navigation bar with 4 tabs.
///
/// Active tab reveals its label to the right of the icon inside a
/// rounded pill; inactive tabs stay icon-only. Every property that
/// changes on activation — pill padding, pill colour, icon colour,
/// label width, label opacity — is driven by ONE tween per tab so
/// they move as a single motion instead of separate implicit
/// animations landing at slightly different times.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Shared timing across every tab so all four transitions land in
  /// sync when the user hops between them.
  static const Duration _transitionDuration = Duration(milliseconds: 360);
  static const Curve _transitionCurve = Curves.easeInOutCubicEmphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cartCount = context.select<CartProvider, int>((c) => c.totalCount);

    void handleTap(int index) {
      HapticFeedback.selectionClick();
      onTap(index);
    }

    // Floating pill layout — SafeArea sits OUTSIDE the visible
    // capsule so the safe-area inset becomes margin below the pill
    // (not padding inside it). The pill floats above the bottom
    // gesture area with a soft shadow instead of the old
    // edge-to-edge rectangle.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            // 999 collapses to height/2 at render time, guaranteeing
            // a full pill regardless of exact tab-row height.
            borderRadius: BorderRadius.circular(999),
            // Two-layer shadow — a soft wide one for lift, a tight
            // one below for contact. Reads as a card floating above
            // the page rather than a bar bolted to the bottom.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            // Hairline border catches ambient light on the pill's
            // top edge so it doesn't look like a flat sticker in
            // dark mode.
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            // spaceAround lets each tab keep its intrinsic width — the
            // active tab is naturally wider (icon + label), inactive
            // tabs are just an icon. The row redistributes free space
            // as the active pill grows, so the shift reads as motion.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: handleTap,
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Faves',
                index: 1,
                currentIndex: currentIndex,
                onTap: handleTap,
                activeColor: colors.error,
              ),
              _NavItemCart(
                index: 2,
                currentIndex: currentIndex,
                onTap: handleTap,
                badge: cartCount,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
                onTap: handleTap,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// One nav tab. A single [TweenAnimationBuilder] drives every visual
/// change on activation via a shared `t: 0→1` factor, so pill,
/// label, and colours all move together on one clock. Icon-glyph
/// swap (outline↔filled) stays on [AnimatedSwitcher] because those
/// are discrete widgets, not a lerpable property.
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? activeColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.activeColor,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.index == widget.currentIndex;
    final activeTint =
        widget.activeColor ?? theme.colorScheme.primary;
    final inactiveTint = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: _AnimatedTab(
          isActive: isActive,
          activeTint: activeTint,
          inactiveTint: inactiveTint,
          builder: (t, iconColor) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedIcon(
                isActive: isActive,
                icon: widget.icon,
                activeIcon: widget.activeIcon,
                color: iconColor,
              ),
              _RevealedLabel(
                t: t,
                label: widget.label,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart tab. Same shape as [_NavItem] but adds a wiggle when the
/// count grows and a scale-fading badge on the icon.
class _NavItemCart extends StatefulWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badge;

  const _NavItemCart({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.badge,
  });

  @override
  State<_NavItemCart> createState() => _NavItemCartState();
}

class _NavItemCartState extends State<_NavItemCart>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _wiggleCtrl;

  @override
  void initState() {
    super.initState();
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void didUpdateWidget(covariant _NavItemCart old) {
    super.didUpdateWidget(old);
    if (widget.badge > old.badge) {
      _wiggleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wiggleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isActive = widget.index == widget.currentIndex;
    final activeTint = colors.primary;
    final inactiveTint = colors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: _AnimatedTab(
          isActive: isActive,
          activeTint: activeTint,
          inactiveTint: inactiveTint,
          builder: (t, iconColor) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Wiggle: damped sine rotation on count-grew.
                  // Amplitude dropped from 0.35 to 0.22 rad so the
                  // motion reads as a nudge, not a shake.
                  AnimatedBuilder(
                    animation: _wiggleCtrl,
                    builder: (context, child) {
                      final v = _wiggleCtrl.value;
                      final angle = v == 0
                          ? 0.0
                          : math.sin(v * math.pi * 3) * (1 - v) * 0.22;
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: _AnimatedIcon(
                      isActive: isActive,
                      icon: Icons.shopping_bag_outlined,
                      activeIcon: Icons.shopping_bag_rounded,
                      color: iconColor,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -8,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: widget.badge <= 0
                          ? const SizedBox.shrink(key: ValueKey('none'))
                          : _CartBadge(count: widget.badge),
                    ),
                  ),
                ],
              ),
              _RevealedLabel(
                t: t,
                label: 'Cart',
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared "pill grows around an icon and its label" animation shell.
/// A single [TweenAnimationBuilder] drives `t: 0→1` from inactive to
/// active state (and back), and every visual that changes on
/// activation reads off of `t` — pill padding, pill background alpha,
/// and the icon colour handed to the child builder. Guarantees every
/// animated property lands on the same frame.
class _AnimatedTab extends StatelessWidget {
  final bool isActive;
  final Color activeTint;
  final Color inactiveTint;

  /// Builder receives the current `t` (0 → 1) and the interpolated
  /// icon colour, so the tab body renders in perfect sync with the
  /// pill it's sitting in.
  final Widget Function(double t, Color iconColor) builder;

  const _AnimatedTab({
    required this.isActive,
    required this.activeTint,
    required this.inactiveTint,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppBottomNavBar._transitionDuration,
      curve: AppBottomNavBar._transitionCurve,
      tween: Tween(end: isActive ? 1.0 : 0.0),
      builder: (context, t, _) {
        // Every property below reads off the same `t`, so there's
        // no chance of the pill finishing before the label or the
        // colour lagging behind the geometry.
        final iconColor = Color.lerp(inactiveTint, activeTint, t)!;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 + 2 * t, // 12 → 14
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: activeTint.withValues(alpha: 0.14 * t),
            borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
          ),
          child: builder(t, iconColor),
        );
      },
    );
  }
}

/// Label slot to the right of the icon. Width factor and opacity are
/// both driven by the shared `t` so the label emerges from behind
/// the icon in one motion instead of appearing before the pill has
/// finished growing.
class _RevealedLabel extends StatelessWidget {
  final double t;
  final String label;
  final Color color;

  const _RevealedLabel({
    required this.t,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // widthFactor 0 collapses the slot to nothing; heightFactor MUST
    // be non-null too, otherwise Align tries to fill parent height
    // and pulls the pill into a vertical strip.
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: t,
        heightFactor: 1.0,
        child: Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Opacity(
            // Fade later than the width so the label doesn't peek
            // out through a half-open pill.
            opacity: Curves.easeIn.transform(t),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon-glyph swap between outline and filled. AnimatedSwitcher only
/// fires when the key flips (isActive change) — the smooth colour
/// lerp is handled outside via the shared tween.
class _AnimatedIcon extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  const _AnimatedIcon({
    required this.isActive,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      // Fade only — the pop-scale competed with the pill's growth.
      // The colour lerp already carries the "coming alive" signal.
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Icon(
        isActive ? activeIcon : icon,
        key: ValueKey(isActive),
        color: color,
        size: 22,
      ),
    );
  }
}

/// Red pill on the cart icon. Widens for double-digit counts and
/// caps at "9+" so nothing overflows a small circle.
class _CartBadge extends StatelessWidget {
  final int count;

  const _CartBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = count > 9 ? '9+' : '$count';
    final double width = count > 9 ? 22 : 18;

    return Container(
      key: ValueKey(label),
      constraints: BoxConstraints(minWidth: width, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.error,
        borderRadius: BorderRadius.circular(AppDecorations.radiusPill),
        border: Border.all(
          color: theme.scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onError,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.0,
        ),
      ),
    );
  }
}
