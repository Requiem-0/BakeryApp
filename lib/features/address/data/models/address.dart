import 'api_location.dart';

/// Saved delivery / pickup address.
class Address {
  final String id;
  final String label;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String landmark;
  final String icon;
  final String type; // 'Pickup' | 'Delivery'
  final bool isActive;

  const Address({
    required this.id,
    required this.label,
    this.phone = '',
    this.latitude = 0,
    this.longitude = 0,
    this.landmark = '',
    this.icon = '📍',
    this.type = 'Delivery',
    this.isActive = true,
    required this.address,
  });

  factory Address.fromApiLocation(ApiLocation loc) => Address(
        id: loc.id,
        label: loc.name,
        address: loc.address,
        phone: loc.phone,
        latitude: loc.latitude,
        longitude: loc.longitude,
        landmark: loc.landmark,
        isActive: loc.isActive,
        icon: '📍',
        type: 'Delivery',
      );

  /// Creates a minimal Address from a legacy demo entry (int id).
  factory Address.demo({
    required int id,
    required String label,
    required String address,
    required String icon,
    required String type,
  }) =>
      Address(
        id: id.toString(),
        label: label,
        address: address,
        icon: icon,
        type: type,
      );
}
