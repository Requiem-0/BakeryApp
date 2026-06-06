import '../../../catalogue/data/models/api_product.dart';
import '../../../../core/utils/json_helpers.dart';

/// Business as returned by /api/businesses/* endpoints.
///
/// Field shapes vary across endpoints — list endpoints return some fields
/// only when they're set on the document, location/products endpoints
/// return the raw Mongo doc (with `lat`, `long`, `accurateLocation`, `__v`)
/// while the main list endpoint adds a populated `adminId` object and
/// optional `logo`. The model just accepts everything as optional except
/// the always-present id/name/address/owner/type fields.
class ApiBusiness {
  final String id;
  final String businessName;
  final String address;
  final String owner;
  final String businessType;
  final bool isFeatured;
  final bool showInOrdering;

  /// PAN number is a number on the server (not a string). Optional —
  /// some test businesses don't have it.
  final num? panNumber;

  final String? phoneNumber;
  final String? logo;

  /// Geo coordinates — present only on the raw doc shape returned by
  /// /location/{location} and /{id}/products.
  final double? lat;
  final double? long;

  /// Human-readable refinement of [address] (e.g. "Nayabazar"). Optional.
  final String? accurateLocation;

  /// Populated as a full object on /api/businesses + /featured, but comes
  /// back as a raw ObjectId string on /location and /{id}/products. The
  /// [ApiBusinessAdmin.fromAny] factory handles both.
  final ApiBusinessAdmin admin;

  /// Flat service charge the business adds to every order (e.g. baking
  /// fee, packaging, etc.). Optional — older docs don't have it; treat
  /// null as 0. CartProvider reads this to set the per-cart fee instead
  /// of hardcoding it.
  final num? orderChargePerOrder;

  const ApiBusiness({
    required this.id,
    required this.businessName,
    required this.address,
    required this.owner,
    required this.businessType,
    required this.isFeatured,
    required this.showInOrdering,
    required this.admin,
    this.panNumber,
    this.phoneNumber,
    this.logo,
    this.lat,
    this.long,
    this.accurateLocation,
    this.orderChargePerOrder,
  });

  factory ApiBusiness.fromJson(Map<String, dynamic> json) => ApiBusiness(
        id: (json['_id'] ?? json['id'] ?? '') as String,
        businessName: (json['businessName'] ?? '') as String,
        address: (json['address'] ?? '') as String,
        owner: (json['owner'] ?? '') as String,
        businessType: (json['businessType'] ?? '') as String,
        isFeatured: (json['isFeatured'] as bool?) ?? false,
        showInOrdering: (json['showInOrdering'] as bool?) ?? false,
        panNumber: json['panNumber'] as num?,
        phoneNumber: json['phoneNumber'] as String?,
        logo: json['logo'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        long: (json['long'] as num?)?.toDouble(),
        accurateLocation: json['accurateLocation'] as String?,
        admin: ApiBusinessAdmin.fromAny(json['adminId']),
        orderChargePerOrder: json['orderChargePerOrder'] as num?,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'businessName': businessName,
        'address': address,
        'owner': owner,
        'businessType': businessType,
        'isFeatured': isFeatured,
        'showInOrdering': showInOrdering,
        if (panNumber != null) 'panNumber': panNumber,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (logo != null) 'logo': logo,
        if (lat != null) 'lat': lat,
        if (long != null) 'long': long,
        if (accurateLocation != null) 'accurateLocation': accurateLocation,
        if (orderChargePerOrder != null)
          'orderChargePerOrder': orderChargePerOrder,
        'adminId': admin.isHydrated ? admin.toJson() : admin.id,
      };
}

/// The admin/owner record nested under `adminId`. Comes back two ways:
///   1. Raw ObjectId string:  "68ad60e2a5bc4acafdbb65d1"
///   2. Populated object:     { _id, name, email, phone, currency }
///
/// `fromAny` accepts either; consumers always get the same Dart shape and
/// can check [isHydrated] to know which one they're holding.
class ApiBusinessAdmin {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? currency;

  const ApiBusinessAdmin({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.currency,
  });

  factory ApiBusinessAdmin.fromAny(dynamic value) {
    if (value is String) {
      return ApiBusinessAdmin(id: value);
    }
    if (value is Map<String, dynamic>) {
      return ApiBusinessAdmin(
        id: (value['_id'] ?? value['id'] ?? '') as String,
        name: value['name'] as String?,
        email: value['email'] as String?,
        phone: value['phone'] as String?,
        currency: value['currency'] as String?,
      );
    }
    return const ApiBusinessAdmin(id: '');
  }

  /// True when the full record is loaded (came back as an object, not a
  /// raw ID string). UI uses this to decide whether to fetch /auth/{adminId}
  /// to enrich the display.
  bool get isHydrated => name != null;

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (currency != null) 'currency': currency,
      };
}

/// Wrapper for /api/businesses/{id}/products — the server returns the
/// business document with an embedded `products` array, so callers get
/// both pieces back from one call without re-fetching the business.
class ApiBusinessProducts {
  final ApiBusiness business;
  final List<ApiProduct> products;

  const ApiBusinessProducts({required this.business, required this.products});

  factory ApiBusinessProducts.fromJson(Map<String, dynamic> json) =>
      ApiBusinessProducts(
        business: ApiBusiness.fromJson(json),
        products: parseObjectList(json['products'], ApiProduct.fromJson),
      );
}
