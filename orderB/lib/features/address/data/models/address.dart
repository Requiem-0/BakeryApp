/// Saved delivery / pickup address.
class Address {
  final int id;
  final String label;
  final String address;
  final String icon;
  final String type; // 'Pickup' | 'Delivery'

  const Address({
    required this.id,
    required this.label,
    required this.address,
    required this.icon,
    required this.type,
  });
}
