import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../features/catalogue/data/datasources/catalogue_local_datasource.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/service_icon.dart';

// ── Edit Profile ──────────────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _selectedDiet = 'None';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Edit Profile',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.tertiary
                              ]),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            alignment: Alignment.center,
                            child: Text(user.initials,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                        color: Colors.white, fontSize: 32)),
                          ),
                          const SizedBox(height: 8),
                          Text('Change photo',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel('FULL NAME'),
                    _FieldInput(hint: user.name),
                    const SizedBox(height: 14),
                    const _FieldLabel('EMAIL'),
                    _FieldInput(hint: user.email),
                    const SizedBox(height: 14),
                    const _FieldLabel('PHONE'),
                    _FieldInput(hint: user.phone),
                    const SizedBox(height: 14),
                    const _FieldLabel('BIRTHDAY'),
                    _FieldInput(
                        hint: user.birthday,
                        suffixIcon: Icons.calendar_today_outlined),
                    const SizedBox(height: 14),
                    const _FieldLabel('BIO'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Theme.of(context).dividerColor, width: 1.5),
                      ),
                      child: TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Pastry enthusiast and weekend baker...',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('DIETARY PREFERENCE'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CatalogueLocalDatasource.dietaryPreferenceOptions.map((d) {
                        final active = d == _selectedDiet;
                        return ChoiceChip(
                          label: Text(d),
                          selected: active,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedDiet = d);
                          },
                          backgroundColor: Theme.of(context).dividerColor,
                          selectedColor:
                              Theme.of(context).colorScheme.onSurface,
                          showCheckmark: false,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          labelStyle: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: active
                                    ? Theme.of(context).colorScheme.onTertiary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                fontSize: 13,
                              ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                  label: 'Save Changes', onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 11, letterSpacing: 0.5)),
    );
  }
}

class _FieldInput extends StatelessWidget {
  final String hint;
  final IconData? suffixIcon;

  const _FieldInput({required this.hint, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(hint,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ),
          if (suffixIcon != null)
            Icon(suffixIcon,
                color: Theme.of(context).colorScheme.outline, size: 18),
        ],
      ),
    );
  }
}

// ── Saved Addresses ──────────────────────────────────────────────────────────

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Text('Saved Addresses',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  ...CatalogueLocalDatasource.savedAddresses.map((a) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).cardColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: Theme.of(context).dividerColor, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(a.icon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        title: Row(
                          children: [
                            Text(a.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: a.type == 'Pickup'
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12)
                                    : Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                a.type,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: a.type == 'Pickup'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            a.address,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 12),
                          ),
                        ),
                        trailing: Icon(Icons.more_vert_rounded,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20),
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/profile/addresses/add'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add New Address',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Methods ──────────────────────────────────────────────────────────

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Text('Payment Methods',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  // Card
                  const _PaymentCard(
                    icon: '💳',
                    label: 'Visa ending in 4289',
                    sub: 'Expires 09/27',
                    isDefault: true,
                  ),
                  const SizedBox(height: 10),
                  const _PaymentCard(
                    icon: '🍎',
                    label: 'Apple Pay',
                    sub: 'Express checkout',
                  ),
                  const SizedBox(height: 10),
                  const _PaymentCard(
                    icon: '🅿️',
                    label: 'PayPal',
                    sub: 'sophie@email.com',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add Payment Method',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final bool isDefault;

  const _PaymentCard(
      {required this.icon,
      required this.label,
      required this.sub,
      this.isDefault = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ServiceIcon(
          icon: icon,
          size: 48,
          iconSize: 22,
          borderRadius: 16,
        ),
        title: Row(
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            if (isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('Default',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12)),
        ),
        trailing: Icon(Icons.more_vert_rounded,
            color: Theme.of(context).colorScheme.outline, size: 20),
      ),
    );
  }
}

// ── Notifications ──────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Text('Notifications',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  const _SectionLabel('TODAY'),
                  const SizedBox(height: 8),
                  _buildNotificationCard(
                    context,
                    icon: Icons.shopping_bag_rounded,
                    iconColor: Theme.of(context).colorScheme.primary,
                    title: 'Order Ready for Pickup',
                    message:
                        'Your order #BAK-1942 is freshly baked and ready to be picked up at the store.',
                    time: '10m ago',
                    isUnread: true,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    context,
                    icon: Icons.cake_rounded,
                    iconColor: Theme.of(context).colorScheme.tertiary,
                    title: 'New Seasonal Item',
                    message:
                        'Our signature Strawberry Shortcake is back for a limited time! 🍓',
                    time: '2h ago',
                    isUnread: true,
                  ),
                  const SizedBox(height: 24),
                  const _SectionLabel('THIS WEEK'),
                  const SizedBox(height: 8),
                  _buildNotificationCard(
                    context,
                    icon: Icons.stars_rounded,
                    iconColor: Colors.amber.shade700,
                    title: 'Points Earned!',
                    message:
                        'You earned 50 loyalty points from your last order. You now have 320 points.',
                    time: '1d ago',
                    isUnread: false,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationCard(
                    context,
                    icon: Icons.local_offer_rounded,
                    iconColor: Theme.of(context).colorScheme.secondary,
                    title: 'Weekend Promo',
                    message:
                        'Get 20% off all whole cakes this weekend. Use code SWEET20 at checkout.',
                    time: '3d ago',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          if (isUnread)
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Text(
                      time,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
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
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Settings ──────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  Text('Settings',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  const _SectionLabel('APPEARANCE'),
                  const SizedBox(height: 8),
                  _ToggleCard(children: [
                    _buildToggle(
                        '🌙', 'Dark Mode', null, themeProv.isDark,
                        (_) => themeProv.toggle()),
                    _buildToggle('📱', 'Haptic Feedback', null, _haptics,
                        (v) => setState(() => _haptics = v),
                        showDivider: false),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionLabel('DATA'),
                  const SizedBox(height: 8),
                  _ToggleCard(children: [
                    _buildLinkRow('🗑️', 'Clear Cache', '2.3 MB'),
                    _buildLinkRow('📊', 'Data & Privacy', null,
                        showDivider: false),
                  ]),
                  const SizedBox(height: 16),
                  const _SectionLabel('ABOUT'),
                  const SizedBox(height: 8),
                  _ToggleCard(children: [
                    _buildLinkRow('✨', 'Version', '2.1.0'),
                    _buildLinkRow('📋', 'Terms of Service', null),
                    _buildLinkRow('🔒', 'Privacy Policy', null,
                        showDivider: false),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String icon, String label, String? sub, bool value,
      ValueChanged<bool> onChanged,
      {bool showDivider = true, bool disabled = false}) {
    return _ToggleRow(
      icon: icon,
      label: label,
      sub: sub,
      value: value,
      onChanged: onChanged,
      showDivider: showDivider,
      disabled: disabled,
    );
  }

  Widget _buildLinkRow(String icon, String label, String? valueText,
      {bool showDivider = true, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          leading: ServiceIcon(
            icon: icon,
          ),
          title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          trailing: valueText != null
              ? Text(valueText,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 13))
              : Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline, size: 20),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }
}

// ── Add New Address ──────────────────────────────────────────────────────────

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('New Address',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Map placeholder
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🗺️', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text('Tap to set location',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildLbl(context, 'LABEL'),
                    _buildInp(context, hint: 'e.g. Home, Office'),
                    const SizedBox(height: 14),
                    _buildLbl(context, 'STREET ADDRESS'),
                    _buildInp(context, hint: '123 Baker Street'),
                    const SizedBox(height: 14),
                    _buildLbl(context, 'CITY'),
                    _buildInp(context, hint: 'London'),
                    const SizedBox(height: 14),
                    _buildLbl(context, 'POSTCODE'),
                    _buildInp(context, hint: 'W1F 0TH'),
                    const SizedBox(height: 20),
                    _buildLbl(context, 'ADDRESS TYPE'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text('🏠 Delivery',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onTertiary,
                                        fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text('🏪 Pickup',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                  label: 'Save Address', onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLbl(BuildContext context, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontSize: 11, letterSpacing: 0.5)));

  Widget _buildInp(BuildContext context, {required String hint}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
        ),
        child: Text(hint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
      );
}

// ── Shared private ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(letterSpacing: 1, fontSize: 11));
  }
}

class _ToggleCard extends StatelessWidget {
  final List<Widget> children;

  const _ToggleCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String icon;
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final bool disabled;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
          value: value,
          onChanged: disabled ? null : onChanged,
          activeThumbColor: Theme.of(context).cardColor,
          activeTrackColor: Theme.of(context).colorScheme.primary,
          inactiveThumbColor: Theme.of(context).cardColor,
          inactiveTrackColor: Theme.of(context).dividerColor,
          title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          subtitle: sub != null
              ? Text(sub!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12))
              : null,
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }
}
