import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../notifications/data/models/api_notification.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../core/utils/responsive.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<NotificationProvider>();
    final items = prov.items;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 8, Responsive.horizontalPadding(context), 20),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Notifications',
                        style: theme.textTheme.headlineLarge),
                  ),
                  if (prov.hasUnread)
                    TextButton(
                      onPressed: prov.markAllAsRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Mark all read',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          )),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: prov.refresh,
                child: _NotificationsBody(prov: prov, items: items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  final NotificationProvider prov;
  final List<ApiNotification> items;
  const _NotificationsBody({required this.prov, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (prov.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      // Keep it scrollable so RefreshIndicator still works.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 80, Responsive.horizontalPadding(context), 24),
        children: [
          const Center(child: Text('🔔', style: TextStyle(fontSize: 56))),
          const SizedBox(height: 12),
          Center(
            child: Text("You're all caught up",
                style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('New notifications will show up here.',
                style: theme.textTheme.bodySmall),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 0, Responsive.horizontalPadding(context), 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _NotificationCard(
        notification: items[i],
        onTap: () => prov.markAsRead(items[i].id),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final ApiNotification notification;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = notification;
    final isUnread = !n.isRead;
    final iconInfo = _iconFor(n.type, theme);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor,
            width: isUnread ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconInfo.$2.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconInfo.$1, color: iconInfo.$2, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            )),
                      ),
                      Text(_relativeTime(n.createdAt),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 11)),
                    ],
                  ),
                  if (n.message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(n.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        )),
                  ],
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picks a (icon, tint) pair based on the notification's `type` field.
/// Falls through to a generic bell icon when no keyword matches.
(IconData, Color) _iconFor(String type, ThemeData theme) {
  final t = type.toLowerCase();
  if (t.contains('order')) {
    return (Icons.shopping_bag_rounded, theme.colorScheme.primary);
  }
  if (t.contains('promo') || t.contains('offer') || t.contains('deal')) {
    return (Icons.local_offer_rounded, theme.colorScheme.secondary);
  }
  if (t.contains('point') || t.contains('loyalty') || t.contains('reward')) {
    return (Icons.stars_rounded, Colors.amber.shade700);
  }
  return (Icons.notifications_rounded, theme.colorScheme.tertiary);
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}
