import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/json_helpers.dart';
import '../models/api_business.dart';

/// Wraps the /api/businesses/* endpoints. Stateless — returns ApiResult<T>.
class BusinessRepository {
  final ApiClient _api;

  BusinessRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// GET /api/businesses
  ///
  /// If all three of [latitude], [longitude], [distance] are provided, the
  /// server filters to businesses within that radius. The Swagger spec
  /// documents this as a JSON body on a GET request — unusual, but Dio
  /// supports it via the underlying `data:` parameter.
  Future<ApiResult<List<ApiBusiness>>> getAllBusinesses({
    double? latitude,
    double? longitude,
    double? distance,
  }) async {
    try {
      final hasGeo =
          latitude != null && longitude != null && distance != null;
      final res = hasGeo
          ? await _api.dio.get(
              '/businesses',
              data: {
                'latitude': latitude,
                'longitude': longitude,
                'distance': distance,
              },
            )
          : await _api.get('/businesses');
      return _parseBusinessList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/businesses/featured
  Future<ApiResult<List<ApiBusiness>>> getFeaturedBusinesses() async {
    try {
      final res = await _api.get('/businesses/featured');
      return _parseBusinessList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/businesses/{id}
  ///
  /// Returns `ApiResult.success(null)` when the server replies 200 with
  /// `{"business": []}` (its "not found" shape). UI should treat that as
  /// a not-found empty state, not an error.
  Future<ApiResult<ApiBusiness?>> getBusinessById(String id) async {
    try {
      final res = await _api.get('/businesses/$id');
      final data = res.data;
      if (data is! Map<String, dynamic>) return _shapeError();
      // Server wraps the result inconsistently:
      //   • found        → either {business: {...}}  or  {business: [{...}]}
      //   • not found    → {business: []}
      // Treat empty list / null as "not found"; pick the first object
      // otherwise.
      final business = data['business'];
      if (business is Map<String, dynamic>) {
        return ApiResult.success(ApiBusiness.fromJson(business));
      }
      if (business is List &&
          business.isNotEmpty &&
          business.first is Map<String, dynamic>) {
        return ApiResult.success(
          ApiBusiness.fromJson(business.first as Map<String, dynamic>),
        );
      }
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/businesses/owner/{ownerId}
  ///
  /// [ownerId] must be the admin's ObjectId, NOT the `owner` name string —
  /// passing e.g. "Stranger" returns 500 with a "Cast to ObjectId failed"
  /// error from the server.
  Future<ApiResult<ApiBusiness?>> getBusinessByOwner(String ownerId) async {
    try {
      final res = await _api.get('/businesses/owner/$ownerId');
      final data = res.data;
      if (data is! Map<String, dynamic>) return _shapeError();
      // Server wraps the result inconsistently:
      //   • found        → either {business: {...}}  or  {business: [{...}]}
      //   • not found    → {business: []}
      // Treat empty list / null as "not found"; pick the first object
      // otherwise.
      final business = data['business'];
      if (business is Map<String, dynamic>) {
        return ApiResult.success(ApiBusiness.fromJson(business));
      }
      if (business is List &&
          business.isNotEmpty &&
          business.first is Map<String, dynamic>) {
        return ApiResult.success(
          ApiBusiness.fromJson(business.first as Map<String, dynamic>),
        );
      }
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/businesses/location/{location}
  ///
  /// [location] is a free-text match against the business `address` field
  /// (case-insensitive substring on the server side, in practice).
  Future<ApiResult<List<ApiBusiness>>> getBusinessesByLocation(
    String location,
  ) async {
    try {
      final res = await _api.get(
        '/businesses/location/${Uri.encodeComponent(location)}',
      );
      return _parseBusinessList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/businesses/{id}/products
  ///
  /// Returns the business doc with its products array embedded in one
  /// response — caller doesn't need a second call to fetch the business.
  Future<ApiResult<ApiBusinessProducts>> getBusinessProducts(String id) async {
    try {
      final res = await _api.get('/businesses/$id/products');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message:
              'Unexpected response shape from /businesses/{id}/products.',
        ));
      }
      return ApiResult.success(ApiBusinessProducts.fromJson(data));
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }



  ApiResult<List<ApiBusiness>> _parseBusinessList(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return ApiResult.failure(const ApiFailure(
        message:
            'Unexpected response shape — expected an object with "businesses" key.',
      ));
    }
    return ApiResult.success(
      parseObjectList(data['businesses'], ApiBusiness.fromJson),
    );
  }

  ApiResult<ApiBusiness?> _shapeError() => ApiResult.failure(const ApiFailure(
        message:
            'Unexpected response shape — expected an object with "business" key.',
      ));
}
