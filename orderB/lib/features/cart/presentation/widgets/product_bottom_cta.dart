import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants.dart';

/// Glassmorphism-style floating bottom CTA for the Product Detail screen.
/// A frosted-glass card with a quantity stepper, animated price, and a
/// pulsing basket-icon checkout button.
class ProductBottomCta extends StatefulWidget {
  final int quantity;
  final double totalPrice;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onCheckout;

  const ProductBottomCta({
    super.key,
    required this.quantity,
    required this.totalPrice,
    required this.onDecrement,
    required this.onIncrement,
    required this.onCheckout,
  });

  @override
  State<ProductBottomCta> createState() => _ProductBottomCtaState();
}

class _ProductBottomCtaState extends State<ProductBottomCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.onSurface.withValues(alpha: 0.12),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Animated price (left) ─────────────────────────
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: anim, curve: Curves.easeOut)),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Text(
                            AppConstants.formatPrice(widget.totalPrice),
                            key: ValueKey(widget.totalPrice),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Stepper pill (center-right) ───────────────────
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepperButton(
                            icon: Icons.remove_rounded,
                            onTap: widget.onDecrement,
                            filled: false,
                          ),
                          SizedBox(
                            width: 40,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: Text(
                                '${widget.quantity}',
                                key: ValueKey(widget.quantity),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            onTap: widget.onIncrement,
                            filled: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Pulsing basket button ─────────────────────────
                    GestureDetector(
                      onTap: widget.onCheckout,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_basket_rounded,
                            color: cs.onPrimary,
                            size: 24,
                          ),
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

// ── Stepper button ────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? cs.primary : Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            if (filled)
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Icon(
          icon,
          size: 22,
          color: filled ? cs.onPrimary : cs.primary,
        ),
      ),
    );
  }
}
