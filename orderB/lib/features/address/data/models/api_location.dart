class ApiLocation {
  final String id;
  final String name;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String landmark;
  final bool isActive;

  const ApiLocation({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.landmark,
    required this.isActive,
  });

  factory ApiLocation.fromJson(Map<String, dynamic> json) => ApiLocation(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        latitude: _toDouble(json['latitude']),
        longitude: _toDouble(json['longitude']),
        landmark: (json['landmark'] ?? '').toString(),
        isActive: json['isActive'] == true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'isActive': isActive,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
