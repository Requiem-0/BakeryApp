import '../../../../core/utils/json_helpers.dart';

/// Tax configuration for a business, as returned by
/// `GET /api/businesses/{businessId}/tax/getall`.
///
/// The endpoint wraps the payload in `{status: "success", data: {tax: [{...}]}}`.
/// Callers should unwrap that outer envelope before calling
/// [ApiTaxConfig.fromJson] — see `BusinessRepository.getTaxConfig`.
///
/// Structure:
///   • [taxes] — flat tax rules (Vat, Service, etc.) that stack additively.
///   • [groupedTaxes] — nested groups; not used yet but preserved so
///     future admin configs don't get silently dropped on parse.
///   • [settings] — mode + addon-tax toggle. See [ApiTaxSettings].
///
/// [totalEnabledRate] is the sum of every enabled rule's `rate`. Use that
/// as the single percentage the cart applies to taxable line totals.
class ApiTaxConfig {
  final String? id;
  final String? adminId;
  final List<ApiTaxRule> taxes;
  final List<dynamic> groupedTaxes;
  final ApiTaxSettings settings;

  const ApiTaxConfig({
    this.id,
    this.adminId,
    required this.taxes,
    this.groupedTaxes = const [],
    required this.settings,
  });

  factory ApiTaxConfig.fromJson(Map<String, dynamic> json) => ApiTaxConfig(
        id: json['_id'] as String?,
        adminId: json['adminId'] as String?,
        taxes: parseObjectList(json['taxes'], ApiTaxRule.fromJson),
        groupedTaxes:
            json['groupedTaxes'] is List ? (json['groupedTaxes'] as List) : const [],
        settings: json['taxSettings'] is Map<String, dynamic>
            ? ApiTaxSettings.fromJson(json['taxSettings'] as Map<String, dynamic>)
            : const ApiTaxSettings(),
      );

  /// Sum of all enabled tax rates as a percentage. e.g. one VAT rule at
  /// 13 and one Service rule at 10 → 23.0. Zero when every rule is
  /// disabled or the taxes array is empty.
  double get totalEnabledRate {
    double total = 0;
    for (final t in taxes) {
      if (!t.isEnabled) continue;
      total += t.rate.toDouble();
    }
    return total;
  }

  /// True when there's at least one enabled non-zero rule the cart
  /// should surface a Tax line for.
  bool get hasActiveTax => totalEnabledRate > 0;
}

/// One row inside [ApiTaxConfig.taxes]. Currently only VAT is used in
/// practice, but the shape supports arbitrary named tax rules.
class ApiTaxRule {
  final String? id;
  final String name;
  final num rate;
  final bool isEnabled;

  const ApiTaxRule({
    this.id,
    required this.name,
    required this.rate,
    required this.isEnabled,
  });

  factory ApiTaxRule.fromJson(Map<String, dynamic> json) => ApiTaxRule(
        id: json['_id'] as String?,
        name: (json['name'] ?? '') as String,
        rate: (json['rate'] as num?) ?? 0,
        isEnabled: (json['isEnabled'] as bool?) ?? false,
      );
}

/// Global tax knobs the admin flips once and every future ticket inherits.
///
///   • [mode] — `"exclusive"` (tax added on top of the receipt total)
///     vs `"inclusive"` (tax already baked into product prices).
///   • [isAddonTaxEnabled] — whether add-on line items get taxed too.
///     When false the cart should tax the base product price only.
class ApiTaxSettings {
  final String mode;
  final bool isAddonTaxEnabled;

  const ApiTaxSettings({
    this.mode = 'exclusive',
    this.isAddonTaxEnabled = false,
  });

  factory ApiTaxSettings.fromJson(Map<String, dynamic> json) => ApiTaxSettings(
        mode: (json['mode'] as String?) ?? 'exclusive',
        isAddonTaxEnabled: (json['isAddonTaxEnabled'] as bool?) ?? false,
      );

  bool get isInclusive => mode == 'inclusive';
  bool get isExclusive => !isInclusive;
}
