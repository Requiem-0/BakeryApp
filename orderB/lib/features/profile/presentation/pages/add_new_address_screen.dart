import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../address/data/location_service.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../widgets/profile_shared_widgets.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({super.key});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _labelCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();

  final _locationService = LocationService();
  bool _locating = false;
  bool _saving = false;
  PickedLocation? _pinned;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  /// Asks the OS for the user's current GPS position, reverse-geocodes it
  /// into a street-style address, and drops the result into the street
  /// field. User can still edit it afterwards.
  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final result = await _locationService.fetchCurrent();
    if (!mounted) return;
    if (result == null) {
      setState(() => _locating = false);
      AppToast.error(
        context,
        "Couldn't get your location. Check that GPS is on and the app has location permission.",
      );
      return;
    }
    setState(() {
      _pinned = result;
      _streetCtrl.text = result.address;
      _locating = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final addrStr = [
      _streetCtrl.text.trim(),
      _cityCtrl.text.trim(),
      _postcodeCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');

    final landmark = _landmarkCtrl.text.trim();

    if (_labelCtrl.text.trim().isEmpty || addrStr.isEmpty) {
      AppToast.error(context, 'Please fill in label and street address.');
      return;
    }

    setState(() => _saving = true);
    final prov = context.read<AddressProvider>();
    final ok = await prov.addAddress(
      name: _labelCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: addrStr,
      landmark: landmark,
      latitude: _pinned?.latitude ?? 0,
      longitude: _pinned?.longitude ?? 0,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppToast.success(context, 'Address saved!');
      context.pop();
    } else {
      AppToast.error(context, prov.error ?? 'Failed to save address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('New Address', style: theme.textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _locationBlock(theme),
                    const SizedBox(height: 20),
                    const FieldLabel('LABEL'),
                    _field(_labelCtrl, hint: 'Home, Office...'),
                    const SizedBox(height: 14),
                    const FieldLabel('PHONE'),
                    _field(_phoneCtrl,
                        hint: 'Phone', type: TextInputType.phone),
                    const SizedBox(height: 14),
                    const FieldLabel('STREET ADDRESS'),
                    _field(_streetCtrl, hint: 'Street address'),
                    const SizedBox(height: 14),
                    const FieldLabel('CITY'),
                    _field(_cityCtrl, hint: 'City'),
                    const SizedBox(height: 14),
                    const FieldLabel('POSTCODE'),
                    _field(_postcodeCtrl, hint: 'Postcode'),
                    const SizedBox(height: 14),
                    const FieldLabel('LANDMARK (optional)'),
                    _field(_landmarkCtrl, hint: 'Landmark (optional)'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: PrimaryButton(
                label: 'Save Address',
                onTap: _saving ? null : _save,
                isLoading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl,
      {required String hint, TextInputType? type}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
      ),
    );
  }

  /// "Use my current location" trigger before a fix is captured, swapped
  /// out for an orange "Location pinned" summary card once GPS resolves.
  Widget _locationBlock(ThemeData theme) {
    if (_pinned == null) {
      return GestureDetector(
        onTap: _locating ? null : _useCurrentLocation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _locating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : Icon(Icons.my_location_rounded,
                        color: theme.colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _locating
                          ? 'Getting your location...'
                          : 'Use my current location',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text('Auto-fills the street address below',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline, size: 20),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Location pinned',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    )),
                const SizedBox(height: 2),
                Text(_pinned!.address,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                // Coordinates surface so the customer can sanity-check
                // when the resolved address looks wrong — paste these
                // into Google Maps to see what the phone actually
                // reported. If they're off, GPS hasn't locked yet (or
                // a VPN is interfering); tap the refresh icon to retry.
                Text(
                  '${_pinned!.latitude.toStringAsFixed(5)}, '
                  '${_pinned!.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.outline,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Re-locate',
            icon: Icon(Icons.refresh_rounded,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
            onPressed: _locating ? null : _useCurrentLocation,
          ),
        ],
      ),
    );
  }
}
