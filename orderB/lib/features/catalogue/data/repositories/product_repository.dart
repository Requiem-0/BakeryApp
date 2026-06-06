import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/json_helpers.dart';
import '../models/api_category.dart';
import '../models/api_product.dart';

/// Wraps the product endpoints. Stateless — returns ApiResult<T>.
///
/// When [businessId] is set, all catalogue calls go through the
/// `/api/businesses/{id}/products/*` family (scopes results to just that
/// business). When null, falls back to the global `/api/products/*`
/// endpoints — useful for diagnostic builds or a future multi-business UI.
///
/// Bearer token (for /recent-purchase) is auto-attached by ApiClient's
/// existing interceptor; callers don't pass JWTs explicitly.
class ProductRepository {
  final ApiClient _api;
  final String? _businessId;

  ProductRepository({ApiClient? apiClient, String? businessId})
      : _api = apiClient ?? ApiClient(),
        _businessId = businessId;

  /// `/businesses/{id}/products` when scoped, `/products` otherwise.
  String get _productsBase => _businessId != null
      ? '/businesses/$_businessId/products'
      : '/products';

  /// GET /api/products/  (global) or /api/businesses/{id}/products (scoped).
  ///
  /// Global is cursor-paginated; scoped returns all products in one shot
  /// (no `nextCursor` in that response — [ApiProductPage.hasMore] reads as
  /// false on the scoped path, so [loadMoreProducts] becomes a no-op).
  Future<ApiResult<ApiProductPage>> getAllProducts({String? cursor}) async {
    try {
      // Global path keeps the trailing slash; scoped path does not.
      final path = _businessId != null ? _productsBase : '/products/';
      final res = await _api.get(
        path,
        query: cursor != null && cursor.isNotEmpty ? {'cursor': cursor} : null,
      );
      return _parsePagedProducts(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/categories  (global) or
  /// /api/businesses/{id}/products/categories  (scoped).
  Future<ApiResult<List<ApiCategory>>> getCategories() async {
    try {
      final res = await _api.get('$_productsBase/categories');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response shape from /products/categories.',
        ));
      }
      return ApiResult.success(
        parseObjectList(data['categories'], ApiCategory.fromJson),
      );
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/category/{categoryId}  (global) or
  /// /api/businesses/{id}/products/category/{categoryId}  (scoped).
  ///
  /// [categoryId] must be a valid MongoDB ObjectId — passing e.g. "1"
  /// causes the server to return 400 with "Invalid Category id".
  Future<ApiResult<List<ApiProduct>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final res = await _api.get('$_productsBase/category/$categoryId');
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/popularity  (global) or
  /// /api/businesses/{id}/products/popularity  (scoped).
  ///
  /// Returns products sorted by `orderedCount` descending. Not paginated.
  Future<ApiResult<List<ApiProduct>>> getProductsByPopularity() async {
    try {
      final res = await _api.get('$_productsBase/popularity');
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/{id}  (global) or
  /// /api/businesses/{businessId}/products/{id}  (scoped).
  ///
  /// Returns `ApiResult.success(null)` when the server replies 200 with
  /// `product: null` — i.e. the request succeeded, the resource just
  /// doesn't exist (the scoped endpoint also returns this shape when the
  /// product belongs to a different business). UI should treat that as a
  /// "not found" empty state, not an error.
  Future<ApiResult<ApiProduct?>> getProductById(String id) async {
    try {
      final res = await _api.get('$_productsBase/$id');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response shape from /products/{id}.',
        ));
      }
      final product = data['product'];
      if (product is Map<String, dynamic>) {
        return ApiResult.success(ApiProduct.fromJson(product));
      }
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/search/{keyword}
  ///
  /// No business-scoped equivalent on the backend — this always hits the
  /// global search and returns results from every business on the
  /// platform. Callers running in scoped mode should filter the result
  /// list to products whose `adminId` matches the bakery (or do
  /// client-side filtering on the already-loaded scoped list instead).
  Future<ApiResult<List<ApiProduct>>> searchProducts(String keyword) async {
    try {
      final res = await _api.get(
        '/products/search/${Uri.encodeComponent(keyword)}',
      );
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// POST /api/products/sendMail — bid/inquiry email to admin.
  Future<ApiResult<void>> sendBidEmail({
    required String adminId,
    required String description,
    required num bidAmount,
  }) async {
    try {
      await _api.post('/products/sendMail', body: {
        'adminId': adminId,
        'description': description,
        'bidAmount': bidAmount,
      });
      return ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/recent-purchase  (global) or
  /// /api/businesses/{businessId}/products/recent-purchase  (scoped).
  ///
  /// Requires the customer to be logged in. The Bearer token is attached
  /// automatically by ApiClient's interceptor — callers do not pass a JWT.
  /// If no token is stored, the server returns 401/403 and the existing
  /// 401 interceptor flips AuthProvider to unauthenticated.
  Future<ApiResult<List<ApiProduct>>> getRecentPurchases() async {
    try {
      final res = await _api.get('$_productsBase/recent-purchase');
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ApiResult<List<ApiProduct>> _parseProductList(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return ApiResult.failure(const ApiFailure(
        message:
            'Unexpected response shape — expected an object with "products" key.',
      ));
    }
    return ApiResult.success(
      parseObjectList(data['products'], ApiProduct.fromJson),
    );
  }

  ApiResult<ApiProductPage> _parsePagedProducts(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return ApiResult.failure(const ApiFailure(
        message:
            'Unexpected response shape — expected an object with "products" key.',
      ));
    }
    return ApiResult.success(ApiProductPage(
      products: parseObjectList(data['products'], ApiProduct.fromJson),
      nextCursor: data['nextCursor'] as String?,
    ));
  }
}
