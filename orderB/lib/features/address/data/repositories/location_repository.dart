import 'package:flutter/foundation.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/api_location.dart';

/// Wraps the /api/location/* family of endpoints.
///
/// Every endpoint returns the **same wrapper shape** — a single customer-
/// locations document with a nested `locations` array:
///
///   { "_id": "...", "customerId": "...", "locations": [...], "__v": 1 }
///
/// Mutations (create / update / delete) respond with the post-operation
/// full list, so all methods here return `List<ApiLocation>` (the unwrapped
/// inner array) and callers can replace their in-memory state wholesale.
class LocationRepository {
  final ApiClient _api;

  LocationRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  /// GET /api/location/  — locations for the logged-in user.
  Future<ApiResult<List<ApiLocation>>> fetchLocations() async {
    try {
      final res = await _api.get('/location/');
      return _parse(res.data);
    } catch (e) {
      debugPrint('🚨 LocationRepository.fetchLocations: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/location/{customerId}  — locations for a specific customer.
  Future<ApiResult<List<ApiLocation>>> fetchLocationsByCustomer(
      String customerId) async {
    try {
      final res = await _api.get('/location/$customerId');
      return _parse(res.data);
    } catch (e) {
      debugPrint('🚨 LocationRepository.fetchLocationsByCustomer: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// POST /api/location/  — add a new delivery location.
  ///
  /// Sending `isActive: true` deactivates the previously-active location
  /// server-side; at most one entry is active at any time.
  Future<ApiResult<List<ApiLocation>>> createLocation({
    required String name,
    required String phone,
    required String address,
    double latitude = 0,
    double longitude = 0,
    String landmark = '',
    bool isActive = true,
  }) async {
    try {
      // The backend's Joi validator rejects empty strings even on fields
      // that are conceptually optional (e.g. `landmark`). Omit them
      // entirely when blank so the validator treats them as absent.
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'isActive': isActive,
      };
      final landmarkTrimmed = landmark.trim();
      if (landmarkTrimmed.isNotEmpty) body['landmark'] = landmarkTrimmed;

      final res = await _api.post('/location/', body: body);
      return _parse(res.data);
    } catch (e) {
      debugPrint('🚨 LocationRepository.createLocation: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// PATCH /api/location/{locationId}  — update fields. Only the fields you
  /// pass are sent. Patching with `isActive: true` makes the entry the
  /// default and deactivates the rest.
  Future<ApiResult<List<ApiLocation>>> updateLocation({
    required String locationId,
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? landmark,
    bool? isActive,
  }) async {
    try {
      // Skip null AND empty strings — the backend's Joi rules reject empty
      // values on fields like `landmark` even when conceptually optional.
      // Treating empty as "don't touch this field" is what the rest of the
      // app expects from a PATCH anyway.
      final body = <String, dynamic>{};
      void putStr(String key, String? value) {
        if (value != null && value.trim().isNotEmpty) {
          body[key] = value.trim();
        }
      }

      putStr('name', name);
      putStr('phone', phone);
      putStr('address', address);
      putStr('landmark', landmark);
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      if (isActive != null) body['isActive'] = isActive;

      final res = await _api.patch('/location/$locationId', body: body);
      return _parse(res.data);
    } catch (e) {
      debugPrint('🚨 LocationRepository.updateLocation: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// DELETE /api/location/{locationId}  — remove an entry.
  Future<ApiResult<List<ApiLocation>>> deleteLocation(String locationId) async {
    try {
      final res = await _api.delete('/location/$locationId');
      return _parse(res.data);
    } catch (e) {
      debugPrint('🚨 LocationRepository.deleteLocation: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Unwraps the wrapper shape down to the nested `locations` array.
  /// Returns success(empty list) when the customer has no locations yet
  /// (server replies 200 with `"locations": []`).
  ApiResult<List<ApiLocation>> _parse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return ApiResult.failure(const ApiFailure(
        message: 'Unexpected response shape from /location/*.',
      ));
    }
    final raw = data['locations'];
    if (raw is List) {
      return ApiResult.success(
        raw
            .whereType<Map<String, dynamic>>()
            .map(ApiLocation.fromJson)
            .toList(),
      );
    }
    return ApiResult.success(const []);
  }
}
