import 'package:flutter/material.dart';
import '../../../../shared/widgets/loyalty_card.dart';
import '../../../../core/theme/app_theme.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/service_icon.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          Text('My Profile', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 20),

          // Profile card
          GestureDetector(
            onTap: () => context.push('/profile/edit'),
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
                    child: Text(user.initials,
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
                      children: [
                        Text(user.name,
                            style: Theme.of(context).textTheme.headlineLarge),
                        Text(user.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('🥐 ${user.membershipTier}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      fontSize: 11)),
                        ),
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
          const SizedBox(height: 16),

          // Loyalty card
          const LoyaltyCard(),
          const SizedBox(height: 24),

          // Menu sections
          const _SectionHeader(label: 'ORDERS & HISTORY'),
          const SizedBox(height: 8),
          _MenuTile(
              icon: '📦',
              label: 'My Orders',
              sub: '4 recent orders',
              onTap: () => context.push('/profile/orders')),
          _MenuTile(
              icon: '❤️',
              label: 'Favourites',
              sub: 'Saved items',
              onTap: () => context.push('/profile/favourites')),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'ACCOUNT'),
          const SizedBox(height: 8),
          _MenuTile(
              icon: '📍',
              label: 'Saved Addresses',
              sub: 'Manage delivery locations',
              onTap: () => context.push('/profile/addresses')),
          _MenuTile(
              icon: '💳',
              label: 'Payment Methods',
              sub: 'Cards & digital wallets',
              onTap: () => context.push('/profile/payments')),
          const SizedBox(height: 16),
          const _SectionHeader(label: 'PREFERENCES'),
          const SizedBox(height: 8),
          _MenuTile(
              icon: '🔔',
              label: 'Notifications',
              sub: 'Push & email settings',
              onTap: () => context.push('/profile/notifications')),
          _MenuTile(
              icon: '⚙️',
              label: 'Settings',
              sub: 'App preferences',
              onTap: () => context.push('/profile/settings')),
          const SizedBox(height: 20),

          // Sign out
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go('/home');
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
              child: Row(
                children: [
                  ServiceIcon(
                    icon: '👋',
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                  ),
                  const SizedBox(width: 14),
                  Text('Sign Out',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ),
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
  final String icon;
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
