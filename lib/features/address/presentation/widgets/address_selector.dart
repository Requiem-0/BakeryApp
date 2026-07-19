import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/brandkit/app_colors.dart';
import '../providers/address_provider.dart';

/// Address selector row in multiple variants.
enum AddressSelectorVariant { header, compact, full }

class AddressSelector extends StatelessWidget {
  final String selectedId;
  final VoidCallback onTap;
  final AddressSelectorVariant variant;

  const AddressSelector({
    super.key,
    required this.selectedId,
    required this.onTap,
    this.variant = AddressSelectorVariant.full,
  });

  @override
  Widget build(BuildContext context) {
    final addrProv = context.watch<AddressProvider>();
    final addr = addrProv.selected;
    final theme = Theme.of(context);
    final isHeader = variant == AddressSelectorVariant.header;
    final isCompact = variant == AddressSelectorVariant.compact;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : isHeader
                ? const EdgeInsets.symmetric(vertical: 4)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isCompact
            ? BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor),
              )
            : null,
        child: Row(
          children: [
            if (!isHeader) ...[
              Container(
                width: isCompact ? 32 : 34,
                height: isCompact ? 32 : 34,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text('📍', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(width: isCompact ? 8 : 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHeader)
                    Text(
                      'Pickup from ✦',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10, letterSpacing: 0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isHeader)
                    Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            addr.address.split(',').first,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            addr.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: isCompact ? 13 : 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _typeBadge(context, addr.type),
                      ],
                    ),
                  if (!isHeader)
                    Text(
                      addr.address,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (!isHeader) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(BuildContext context, String type) {
    final isPickup = type == 'Pickup';
    final color = isPickup ? AppColors.sage : AppColors.golden;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
      ),
    );
  }
}

/// Modal bottom sheet to select an address.
class AddressBottomSheet extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddNew;

  const AddressBottomSheet({
    super.key,
    required this.selectedId,
    required this.onSelect,
    required this.onAddNew,
  });

  /// Show the address selection bottom sheet.
  ///
  /// "Add new address" closes the sheet and pushes `/profile/addresses/add`
  /// by default. Pass [onAddNew] to override (e.g. open a modal flow
  /// instead of routing).
  static void show(
    BuildContext context, {
    required String selectedId,
    required ValueChanged<String> onSelect,
    VoidCallback? onAddNew,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddressBottomSheet(
        selectedId: selectedId,
        onSelect: onSelect,
        onAddNew: onAddNew ??
            () {
              Navigator.pop(context);
              context.push('/profile/addresses/add');
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final addrProv = context.watch<AddressProvider>();
    final addresses = addrProv.addresses;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Select Address',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          // Empty state — no point in showing just an "Add" button
          // with no context. Explain why the list is blank.
          //
          // SizedBox(width: infinity) forces the inner Column to take
          // the full row width — without it, the parent Column's
          // `crossAxisAlignment: start` pins this block to the left
          // edge of the sheet instead of centering it.
          if (addresses.isEmpty)
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 48, color: colors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text('No saved addresses yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      "Add one so we know where to bring your order.",
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ...addresses.map((addr) {
            final isSelected = addr.id == selectedId;
            return GestureDetector(
              onTap: () {
                onSelect(addr.id);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? theme.dividerColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? colors.primary : theme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.1)
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child:
                          const Text('📍', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr.label,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          Text(addr.address,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded,
                          color: AppColors.sage, size: 20),
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onAddNew,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.dividerColor,
                    width: 2,
                    style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded,
                      color: colors.onSurfaceVariant, size: 18),
                  const SizedBox(width: 8),
                  Text('Add new address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500)),
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
