/// Customer profile returned by GET /api/auth/me.
///
/// Fields here mirror the live API response exactly; nothing is invented.
/// If the backend later starts returning more fields (address, profile image,
/// emailVerified flag, etc.), add them here as nullable.
class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final int loyaltyPoints;
  final String? image;
  final String? address;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.loyaltyPoints,
    this.image,
    this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: (json['_id'] ?? json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        phone: (json['phone'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        role: (json['role'] ?? '') as String,
        loyaltyPoints: (json['loyaltyPoints'] as num?)?.toInt() ?? 0,
        image: json['image'] as String?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'loyaltyPoints': loyaltyPoints,
        if (image != null) 'image': image,
        if (address != null) 'address': address,
      };

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    int? loyaltyPoints,
    String? image,
    String? address,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        image: image ?? this.image,
        address: address ?? this.address,
      );
}
