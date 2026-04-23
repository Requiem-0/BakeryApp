import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_decorations.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

/// App-level bottom navigation bar with 4 tabs.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cartCount = context.watch<CartProvider>().totalCount;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: AppDecorations.sheetShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Favourites',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                activeColor: colors.error,
              ),
              _NavItemCart(
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                badge: cartCount,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = index == currentIndex;
    final color = isActive
        ? (activeColor ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : null,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemCart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isActive = index == currentIndex;
    final color = isActive ? colors.primary : colors.onSurfaceVariant;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isActive
                    ? Icons.shopping_bag_rounded
                    : Icons.shopping_bag_outlined,
                color: color,
                size: 24,
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badge',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onError,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Cart',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : null,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
