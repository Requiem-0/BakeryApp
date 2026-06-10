import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../address/presentation/providers/address_provider.dart';

class _EmptyAddresses extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAddresses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No saved addresses',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address so we know where to bring your order.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text('Add address'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                side: BorderSide(color: theme.dividerColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addresses = context.watch<AddressProvider>().addresses;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Saved Addresses', style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<AddressProvider>().refresh(),
                child: addresses.isEmpty
                  ? ListView(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _EmptyAddresses(
                          onAdd: () =>
                              context.push('/profile/addresses/add'),
                        ),
                      ],
                    )
                  : ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  ...addresses.map((a) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: theme.cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side:
                            BorderSide(color: theme.dividerColor, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.location_on_rounded,
                              size: 22, color: theme.colorScheme.primary),
                        ),
                        title: Row(
                          children: [
                            Text(a.label,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: a.type == 'Pickup'
                                    ? theme.colorScheme.primary
                                        .withValues(alpha: 0.12)
                                    : theme.colorScheme.secondary
                                        .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(a.type,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: a.type == 'Pickup'
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(a.address,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12)),
                        ),
                        trailing: Icon(Icons.more_vert_rounded,
                            color: theme.colorScheme.outline, size: 20),
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/profile/addresses/add'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: theme.dividerColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add New Address',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
