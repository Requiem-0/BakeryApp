import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/api_category.dart';
import '../models/api_product.dart';

/// Wraps the /api/products/* endpoints. Stateless — returns ApiResult<T>.
///
/// Bearer token (for /recent-purchase) is auto-attached by ApiClient's
/// existing interceptor; callers don't pass JWTs explicitly.
class ProductRepository {
  final ApiClient _api;

  ProductRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// GET /api/products/
  ///
  /// Cursor-paginated. Pass [cursor] (the `nextCursor` from a prior page)
  /// to fetch the next batch; pass null for the first page.
  Future<ApiResult<ApiProductPage>> getAllProducts({String? cursor}) async {
    try {
      final res = await _api.get(
        '/products/',
        query: cursor != null && cursor.isNotEmpty ? {'cursor': cursor} : null,
      );
      return _parsePagedProducts(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/categories
  Future<ApiResult<List<ApiCategory>>> getCategories() async {
    try {
      final res = await _api.get('/products/categories');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response shape from /products/categories.',
        ));
      }
      final list = data['categories'];
      if (list is! List) {
        return ApiResult.success(const []);
      }
      return ApiResult.success(list
          .whereType<Map<String, dynamic>>()
          .map(ApiCategory.fromJson)
          .toList());
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/category/{categoryId}
  ///
  /// [categoryId] must be a valid MongoDB ObjectId — passing e.g. "1"
  /// causes the server to return 400 with "Invalid Category id".
  Future<ApiResult<List<ApiProduct>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final res = await _api.get('/products/category/$categoryId');
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/popularity
  ///
  /// Returns products sorted by `orderedCount` descending. Not paginated.
  Future<ApiResult<List<ApiProduct>>> getProductsByPopularity() async {
    try {
      final res = await _api.get('/products/popularity');
      return _parseProductList(res.data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/products/{id}
  ///
  /// Returns `ApiResult.success(null)` when the server replies 200 with
  /// `{"message":"Product not found","product":null}` — i.e. the request
  /// succeeded, the resource just doesn't exist. UI should treat that as
  /// a "not found" empty state, not an error.
  Future<ApiResult<ApiProduct?>> getProductById(String id) async {
    try {
      final res = await _api.get('/products/$id');
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

  /// GET /api/products/recent-purchase
  ///
  /// Requires the customer to be logged in. The Bearer token is attached
  /// automatically by ApiClient's interceptor — callers do not pass a JWT.
  /// If no token is stored, the server returns 401 and the existing 401
  /// interceptor flips AuthProvider to unauthenticated.
  Future<ApiResult<List<ApiProduct>>> getRecentPurchases() async {
    try {
      final res = await _api.get('/products/recent-purchase');
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
    final list = data['products'];
    if (list is! List) {
      return ApiResult.success(const []);
    }
    return ApiResult.success(list
        .whereType<Map<String, dynamic>>()
        .map(ApiProduct.fromJson)
        .toList());
  }

  ApiResult<ApiProductPage> _parsePagedProducts(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return ApiResult.failure(const ApiFailure(
        message:
            'Unexpected response shape — expected an object with "products" key.',
      ));
    }
    final rawList = data['products'];
    final products = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(ApiProduct.fromJson)
            .toList()
        : <ApiProduct>[];
    final cursor = data['nextCursor'] as String?;
    return ApiResult.success(
      ApiProductPage(products: products, nextCursor: cursor),
    );
  }
}
