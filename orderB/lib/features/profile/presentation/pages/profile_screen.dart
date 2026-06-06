import 'package:flutter/material.dart';
import '../../../../core/brandkit/app_theme.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/service_icon.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../orders/data/models/placed_order.dart';

/// Builds an onTap that pushes [path] for authed users, or `/login` for
/// guests. After login, [LoginScreen] pops back so the tile they tapped
/// is one tap away from working.
VoidCallback _pushOrLogin(BuildContext context, bool isAuth, String path) =>
    () => context.push(isAuth ? path : '/login');

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated;

    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Active orders only matter when we have a logged-in user; for guests
    // the OrderProvider is empty anyway, but skipping the read keeps the
    // build clean.
    final orderProv = context.watch<OrderProvider>();
    const terminalStatuses = [
      'delivered', 'picked up', 'cancelled', 'completed',
    ];
    final activeOrders = isAuth
        ? orderProv.orders
            .where((o) => !terminalStatuses.contains(o.status.toLowerCase()))
            .toList()
        : const [];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          Text('My Profile', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 20),

          // Profile card. Authed users tap into edit; guests get routed
          // to /login via the same helper so the row stays interactive.
          GestureDetector(
            onTap: _pushOrLogin(context, isAuth, '/profile/edit'),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(initials,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 28)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name,
                            style: Theme.of(context).textTheme.headlineLarge),
                        if (isAuth)
                          Text(email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Menu sections — same shape for guests and authed users. The
          // auth-only tiles (My Orders, Saved Addresses, Notifications, ...)
          // route through `pushOrLogin`, which sends guests to /login and
          // pops them back here once they sign in.
          const _SectionHeader(label: 'ORDERS & HISTORY'),
          const SizedBox(height: 8),
          if (activeOrders.isNotEmpty) ...[
            _MenuTile(
                icon: Icons.near_me_rounded,
                label: 'Track Order',
                sub: '${activeOrders.length} active',
                onTap: () {
                  if (activeOrders.length == 1) {
                    context.push(
                      '/checkout/success/tracking',
                      extra: PlacedOrder.fromOrder(activeOrders.first),
                    );
                  } else {
                    context.push('/profile/orders');
                  }
                }),
            const SizedBox(height: 4),
          ],
          _MenuTile(
              icon: Icons.receipt_long_rounded,
              label: 'My Orders',
              sub: isAuth && orderProv.orders.isNotEmpty
                  ? '${orderProv.orders.length} recent'
                  : 'View past orders',
              onTap: _pushOrLogin(context, isAuth, '/profile/orders')),
          _MenuTile(
              icon: Icons.favorite_rounded,
              label: 'Favourites',
              sub: 'Saved items',
              onTap: () => context.push('/profile/favourites')),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'ACCOUNT'),
          const SizedBox(height: 8),
          _MenuTile(
              icon: Icons.location_on_rounded,
              label: 'Saved Addresses',
              sub: 'Manage delivery locations',
              onTap: _pushOrLogin(context, isAuth, '/profile/addresses')),
          _MenuTile(
              icon: Icons.credit_card_rounded,
              label: 'Payment Methods',
              sub: 'Cards & digital wallets',
              onTap: _pushOrLogin(context, isAuth, '/profile/payments')),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'PREFERENCES'),
          const SizedBox(height: 8),
          _MenuTile(
              icon: Icons.notifications_rounded,
              label: 'Notifications',
              sub: 'Push & email settings',
              onTap: _pushOrLogin(context, isAuth, '/profile/notifications')),
          _MenuTile(
              icon: Icons.settings_rounded,
              label: 'Settings',
              sub: 'App preferences',
              onTap: () => context.push('/profile/settings')),
          const SizedBox(height: 20),

          // Bottom CTA — Sign Out for authed users, Sign In for guests.
          if (isAuth)
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await context.read<AuthProvider>().logout();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text('Sign Out',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        )),
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/login'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text('Sign In',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        )),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(letterSpacing: 1, fontSize: 11));
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;

  const _MenuTile(
      {required this.icon, required this.label, this.sub, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ServiceIcon(
              icon: icon,
              size: 44,
              iconColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyLarge),
                  if (sub != null)
                    Text(sub!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20),
          ],
        ),
      ),
    );
  }
}
