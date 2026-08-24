import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/api_tax.dart';
import '../providers/business_provider.dart';

/// Transparency sheet — customer-tappable breakdown of the business's
/// tax configuration. Reads live from [BusinessProvider.taxConfig] so
/// there's no manual sync between the sheet and the cart's actual math.
///
/// Opens from every surface that shows a Tax total (cart summary,
/// checkout receipt, order invoice, product detail's VAT chip). All
/// entry points route through [TaxPolicySheet.show] so the same design
/// lands everywhere.
///
/// Renders nothing when there's no active tax rule — callers should
/// gate the info trigger on `BusinessProvider.taxConfig?.hasActiveTax`,
/// but if they don't the sheet degrades to a "No tax configured"
/// message rather than throwing.
class TaxPolicySheet extends StatelessWidget {
  const TaxPolicySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const TaxPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final config = context.select<BusinessProvider, ApiTaxConfig?>(
        (b) => b.taxConfig);

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
            // Drag handle — mirrors the AddressBottomSheet pattern so
            // every modal in the app is dismissible the same way.
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

            // Header row: icon + title + close.
            Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: colors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Store Tax Policy',
                  style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: colors.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 20),

            if (config == null || !config.hasActiveTax) ...[
              // Cold-open safety net — the entry points gate on
              // hasActiveTax, but if the config unloads between the
              // trigger and the sheet mounting we render this instead
              // of a half-empty sheet.
              Text('No tax is currently applied to your order.',
                  style: theme.textTheme.bodyMedium),
            ] else ...[
              // Tax Mode row — an inline label + brand-primary chip so
              // the customer can tell at a glance whether they should
              // expect an added line or a baked-in charge. "Tax Added
              // at Checkout" vs "Included in Price" is the same
              // language most Nepali receipts use.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Tax Mode:',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  _ModeChip(inclusive: config.settings.isInclusive),
                ],
              ),
              const SizedBox(height: 14),

              // Add-on tax disclosure. "Tax exempt" reads friendlier
              // than "not taxed" and matches the wording the mock uses.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    config.settings.isAddonTaxEnabled
                        ? Icons.check_circle_outline_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      config.settings.isAddonTaxEnabled
                          ? 'Add-ons: Taxed (rate applies to add-ons too)'
                          : 'Add-ons: Tax exempt (No tax on add-ons)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Active taxes list — each enabled rule with its rate.
              // Skips disabled rules; on this endpoint the flag reliably
              // reflects "rule active" (verified against tax config
              // in POS admin), unlike the discount rules where the
              // same field is essentially always false.
              Text(
                'Active Taxes:',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...config.taxes
                  .where((t) => t.isEnabled)
                  .map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.name,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${_formatRate(t.rate.toDouble())}%',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatRate(double rate) =>
      rate % 1 == 0 ? rate.toStringAsFixed(0) : rate.toString();
}

/// Small pill next to "Tax Mode:". Uses the brand primary at a low
/// opacity so it reads as a category tag rather than a call to action.
class _ModeChip extends StatelessWidget {
  final bool inclusive;

  const _ModeChip({required this.inclusive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        inclusive ? 'Included in Price' : 'Tax Added at Checkout',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
