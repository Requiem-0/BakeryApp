import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/api_cart.dart';

/// Wraps the `/api/cart/*` endpoints.
///
/// All five endpoints require a valid Bearer token (attached by
/// [ApiClient]'s interceptor). All return the updated cart in some
/// shape — [ApiCart.fromAny] unwraps the three known envelopes so
/// callers always get a normalized [ApiCart].
class CartRepository {
  final ApiClient _api;

  CartRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// `GET /api/cart/my-cart` — server-side cart for the current user.
  /// Returns [ApiCart.empty] when the server has no cart yet for the
  /// user (e.g. brand-new account).
  Future<ApiResult<ApiCart>> fetchMyCart() async {
    try {
      final res = await _api.get('/cart/my-cart');
      return ApiResult.success(ApiCart.fromAny(res.data));
    } catch (e) {
      debugPrint('🚨 CartRepository.fetchMyCart: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  // ── Writes ────────────────────────────────────────────────────────────────

  /// `POST /api/cart/` — add (or increment) a single item. Server
  /// resolves prices itself, so we don't send `unitPrice`. [addons]
  /// maps addon `_id` → quantity.
  Future<ApiResult<ApiCart>> addItem({
    required String adminId,
    required String productId,
    String? variantItemId,
    int quantity = 1,
    Map<String, int> addons = const {},
  }) async {
    try {
      final res = await _api.post('/cart/', body: {
        'items': [
          {
            'adminId': adminId,
            'product': productId,
            if (variantItemId != null) 'variantItem': variantItemId,
            'quantity': quantity,
            'addons': addons.entries
                .map((e) => {'addon': e.key, 'quantity': e.value})
                .toList(),
            'discounts': const [],
          },
        ],
      });
      return ApiResult.success(ApiCart.fromAny(res.data));
    } catch (e) {
      debugPrint('🚨 CartRepository.addItem: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// `PUT /api/cart/` — set the absolute quantity of a single item by
  /// product `_id`. The server clamps to non-negative integers; passing
  /// 0 is equivalent to removing the line (use [deleteItem] for that).
  Future<ApiResult<ApiCart>> updateItem({
    required String productId,
    required int quantity,
  }) async {
    try {
      final res = await _api.dio.put('/cart/', data: {
        'items': [
          {'product': productId, 'quantity': quantity},
        ],
      });
      return ApiResult.success(ApiCart.fromAny(res.data));
    } catch (e) {
      debugPrint('🚨 CartRepository.updateItem: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// `DELETE /api/cart/{lineId}` — remove a single line by its server-
  /// assigned `_id` (the value of `CartItem.serverItemId`).
  Future<ApiResult<ApiCart>> deleteItem(String lineId) async {
    try {
      final res = await _api.delete('/cart/$lineId');
      return ApiResult.success(ApiCart.fromAny(res.data));
    } catch (e) {
      debugPrint('🚨 CartRepository.deleteItem: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// `DELETE /api/cart/` — bulk remove lines by their server-assigned
  /// `_id`s. Server returns 400 for an empty list; callers should guard
  /// against that.
  Future<ApiResult<ApiCart>> deleteItems(List<String> lineIds) async {
    try {
      final res = await _api.dio.delete('/cart/', data: {'items': lineIds});
      return ApiResult.success(ApiCart.fromAny(res.data));
    } catch (e) {
      debugPrint('🚨 CartRepository.deleteItems: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }
}
