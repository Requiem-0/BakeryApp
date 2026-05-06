import 'package:flutter/foundation.dart';

import '../../../../core/network/api_result.dart';
import '../../data/models/api_category.dart';
import '../../data/models/api_product.dart';
import '../../data/repositories/product_repository.dart';

enum CatalogueLoadState { idle, loading, ready, error }

/// Single source of truth for catalogue data (categories + products + recent
/// purchases). UI binds to its public state and calls the public methods.
///
/// Three independent state slots — categories, products, recentPurchases —
/// each with their own load state + error so screens that show all three
/// concurrently (e.g. home) can render fine-grained skeleton/error UI.
///
/// The products slot also tracks a forward cursor for the cursor-paginated
/// /products/ endpoint. Category-filter and search loads reset the cursor
/// (those endpoints aren't paginated).
class CatalogueProvider extends ChangeNotifier {
  final ProductRepository _repo;

  CatalogueProvider({required ProductRepository repository})
      : _repo = repository;

  // ── Categories slot ──────────────────────────────────────────────────────
  List<ApiCategory> _categories = const [];
  CatalogueLoadState _categoriesState = CatalogueLoadState.idle;
  String? _categoriesError;

  List<ApiCategory> get categories => _categories;
  CatalogueLoadState get categoriesState => _categoriesState;
  String? get categoriesError => _categoriesError;

  // ── Products slot (filtered by selectedCategoryId or searchKeyword) ──────
  List<ApiProduct> _products = const [];
  CatalogueLoadState _productsState = CatalogueLoadState.idle;
  String? _productsError;
  String? _selectedCategoryId;
  String _searchKeyword = '';
  String? _productsCursor;
  bool _isLoadingMore = false;

  List<ApiProduct> get products => _products;
  CatalogueLoadState get productsState => _productsState;
  String? get productsError => _productsError;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchKeyword => _searchKeyword;

  /// True only when /products/ has a `nextCursor` from the most recent load.
  /// Always false after a category-filter or search load (those aren't
  /// paginated).
  bool get hasMoreProducts =>
      _productsCursor != null && _productsCursor!.isNotEmpty;

  /// True while a [loadMoreProducts] call is in flight, so UI can show a
  /// trailing spinner without flashing the main `productsState` to loading.
  bool get isLoadingMoreProducts => _isLoadingMore;

  // ── Recent purchases slot ────────────────────────────────────────────────
  List<ApiProduct> _recentPurchases = const [];
  CatalogueLoadState _recentPurchasesState = CatalogueLoadState.idle;
  String? _recentPurchasesError;

  List<ApiProduct> get recentPurchases => _recentPurchases;
  CatalogueLoadState get recentPurchasesState => _recentPurchasesState;
  String? get recentPurchasesError => _recentPurchasesError;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  /// Called once on app start. Loads categories so the UI has filters
  /// available immediately. Does not preload products — UI decides which
  /// view to fetch (a category, search results, etc.).
  Future<void> bootstrap() async {
    await loadCategories();
  }

  // ── Categories ───────────────────────────────────────────────────────────
  Future<void> loadCategories() async {
    _categoriesState = CatalogueLoadState.loading;
    _categoriesError = null;
    notifyListeners();
    final result = await _repo.getCategories();
    if (result.isSuccess) {
      _categories = result.data ?? const [];
      _categoriesState = CatalogueLoadState.ready;
    } else {
      _categoriesError =
          result.failure?.message ?? 'Failed to load categories.';
      _categoriesState = CatalogueLoadState.error;
    }
    notifyListeners();
  }

  // ── Products ─────────────────────────────────────────────────────────────
  /// Loads the first page of /products/. Subsequent pages via [loadMoreProducts].
  Future<void> loadAllProducts() async {
    _searchKeyword = '';
    _selectedCategoryId = null;
    _productsCursor = null;
    _productsState = CatalogueLoadState.loading;
    _productsError = null;
    notifyListeners();

    final result = await _repo.getAllProducts();
    _applyPagedResult(result, append: false);
  }

  /// Fetches the next page using the stored cursor and appends to the
  /// products list. Safe to call when [hasMoreProducts] is false — it
  /// simply no-ops.
  Future<void> loadMoreProducts() async {
    if (!hasMoreProducts || _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final result = await _repo.getAllProducts(cursor: _productsCursor);
    _applyPagedResult(result, append: true);
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Loads /products/popularity (not paginated).
  Future<void> loadProductsByPopularity() async {
    _searchKeyword = '';
    _selectedCategoryId = null;
    _productsCursor = null;
    await _runProductLoad(_repo.getProductsByPopularity);
  }

  /// Pass `null` to clear the filter and fall back to /products/ (paginated).
  Future<void> selectCategory(String? categoryId) async {
    _searchKeyword = '';
    _selectedCategoryId = categoryId;
    if (categoryId == null) {
      await loadAllProducts();
      return;
    }
    _productsCursor = null;
    await _runProductLoad(() => _repo.getProductsByCategory(categoryId));
  }

  /// Empty/whitespace-only keyword clears the products list rather than
  /// hitting the search endpoint with nothing.
  Future<void> search(String keyword) async {
    final trimmed = keyword.trim();
    _searchKeyword = trimmed;
    _selectedCategoryId = null;
    _productsCursor = null;
    if (trimmed.isEmpty) {
      _products = const [];
      _productsError = null;
      _productsState = CatalogueLoadState.ready;
      notifyListeners();
      return;
    }
    await _runProductLoad(() => _repo.searchProducts(trimmed));
  }

  /// One-shot fetch — does not mutate the list slot. Use for product detail
  /// screens. Returns null on failure or when the server says not-found.
  Future<ApiProduct?> getProduct(String id) async {
    final result = await _repo.getProductById(id);
    if (result.isFailure) return null;
    return result.data;
  }

  // ── Bid email ────────────────────────────────────────────────────────────
  Future<bool> sendBidEmail({
    required String adminId,
    required String description,
    required num bidAmount,
  }) async {
    final result = await _repo.sendBidEmail(
      adminId: adminId,
      description: description,
      bidAmount: bidAmount,
    );
    return result.isSuccess;
  }

  // ── Recent purchases (auth required) ─────────────────────────────────────
  Future<void> loadRecentPurchases() async {
    _recentPurchasesState = CatalogueLoadState.loading;
    _recentPurchasesError = null;
    notifyListeners();
    final result = await _repo.getRecentPurchases();
    if (result.isSuccess) {
      _recentPurchases = result.data ?? const [];
      _recentPurchasesState = CatalogueLoadState.ready;
    } else {
      _recentPurchasesError =
          result.failure?.message ?? 'Failed to load recent purchases.';
      _recentPurchasesState = CatalogueLoadState.error;
    }
    notifyListeners();
  }

  /// Clears the recent-purchases slot. Call from AuthProvider's logout flow
  /// so the next user doesn't see the previous one's purchase history.
  void clearRecentPurchases() {
    _recentPurchases = const [];
    _recentPurchasesState = CatalogueLoadState.idle;
    _recentPurchasesError = null;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Used by non-paginated product loads (category filter, search, popularity).
  Future<void> _runProductLoad(
    Future<ApiResult<List<ApiProduct>>> Function() call,
  ) async {
    _productsState = CatalogueLoadState.loading;
    _productsError = null;
    notifyListeners();
    final result = await call();
    if (result.isSuccess) {
      _products = result.data ?? const [];
      _productsState = CatalogueLoadState.ready;
    } else {
      _productsError = result.failure?.message ?? 'Failed to load products.';
      _productsState = CatalogueLoadState.error;
    }
    notifyListeners();
  }

  /// Applies a paged result from /products/. When [append] is true, new
  /// products are concatenated; otherwise the list is replaced.
  void _applyPagedResult(ApiResult<ApiProductPage> result,
      {required bool append}) {
    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      _products =
          append ? [..._products, ...page.products] : page.products;
      _productsCursor = page.nextCursor;
      _productsState = CatalogueLoadState.ready;
      _productsError = null;
    } else {
      // For load-more failures, keep the existing list and just surface the
      // error — UI can show a retry banner without losing what's loaded.
      if (!append) {
        _products = const [];
      }
      _productsCursor = null;
      _productsError = result.failure?.message ?? 'Failed to load products.';
      _productsState = CatalogueLoadState.error;
    }
  }
}
