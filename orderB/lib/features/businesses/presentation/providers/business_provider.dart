import 'package:flutter/foundation.dart';

import '../../../catalogue/data/models/api_product.dart';
import '../../data/models/api_business.dart';
import '../../data/repositories/business_repository.dart';

enum BusinessLoadState { idle, loading, ready, error }

/// Single source of truth for business data. Three independent state slots
/// (all/featured/selected) so a screen that shows e.g. a featured carousel
/// AND a full list AND a selected business detail can render fine-grained
/// loading/error UI per slot without one breaking the others.
class BusinessProvider extends ChangeNotifier {
  final BusinessRepository _repo;

  BusinessProvider({required BusinessRepository repository})
      : _repo = repository;

  // ── All businesses slot ──────────────────────────────────────────────────
  List<ApiBusiness> _businesses = const [];
  BusinessLoadState _businessesState = BusinessLoadState.idle;
  String? _businessesError;

  List<ApiBusiness> get businesses => _businesses;
  BusinessLoadState get businessesState => _businessesState;
  String? get businessesError => _businessesError;

  // ── Featured slot ────────────────────────────────────────────────────────
  List<ApiBusiness> _featured = const [];
  BusinessLoadState _featuredState = BusinessLoadState.idle;
  String? _featuredError;

  List<ApiBusiness> get featured => _featured;
  BusinessLoadState get featuredState => _featuredState;
  String? get featuredError => _featuredError;

  // ── Current business slot (the one this app instance represents) ────────
  // Loaded once on bootstrap from [AppConstants.bakeryBusinessId] so UI can
  // read businessName / address / logo / currency etc. from a single source
  // instead of hardcoding them. Distinct from [_selectedBusiness] which is
  // for "user tapped into a business to browse" flows.
  ApiBusiness? _currentBusiness;
  BusinessLoadState _currentState = BusinessLoadState.idle;
  String? _currentError;

  ApiBusiness? get current => _currentBusiness;
  BusinessLoadState get currentState => _currentState;
  String? get currentError => _currentError;

  // ── Selected business slot (for detail / "browse this business") ─────────
  ApiBusiness? _selectedBusiness;
  List<ApiProduct> _selectedProducts = const [];
  BusinessLoadState _selectedState = BusinessLoadState.idle;
  String? _selectedError;

  ApiBusiness? get selectedBusiness => _selectedBusiness;
  List<ApiProduct> get selectedProducts => _selectedProducts;
  BusinessLoadState get selectedState => _selectedState;
  String? get selectedError => _selectedError;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  /// Loads the business this app represents. Pass null to skip (used in
  /// tests or multi-business builds). Other slots (all/featured) stay
  /// idle — the screens that surface them trigger their own loads to
  /// avoid hammering the API at startup before UI needs the data.
  Future<void> bootstrap({String? currentBusinessId}) async {
    if (currentBusinessId != null && currentBusinessId.isNotEmpty) {
      await loadCurrent(currentBusinessId);
    }
  }

  // ── Current business ─────────────────────────────────────────────────────
  /// Fetches the business identified by [id] and stores it in [current].
  /// UI reads `businessName`, `address`, `logo`, etc. from there instead of
  /// hardcoding. Safe to re-call (e.g. after a config change that swaps
  /// the bakery id) — replaces the stored business.
  Future<void> loadCurrent(String id) async {
    _currentState = BusinessLoadState.loading;
    _currentError = null;
    notifyListeners();
    final result = await _repo.getBusinessById(id);
    if (result.isSuccess && result.data != null) {
      _currentBusiness = result.data;
      _currentState = BusinessLoadState.ready;
      debugPrint(
          '🏢 BusinessProvider: loaded "${result.data!.businessName}" — '
          'logo=${result.data!.logo ?? "(null)"}');
    } else {
      _currentError = result.failure?.message ?? 'Failed to load business.';
      _currentState = BusinessLoadState.error;
    }
    notifyListeners();
  }

  // ── All businesses ───────────────────────────────────────────────────────
  /// Pass [latitude]/[longitude]/[distance] together to filter by radius.
  /// Omit them for the full list.
  Future<void> loadAll({
    double? latitude,
    double? longitude,
    double? distance,
  }) async {
    _businessesState = BusinessLoadState.loading;
    _businessesError = null;
    notifyListeners();
    final result = await _repo.getAllBusinesses(
      latitude: latitude,
      longitude: longitude,
      distance: distance,
    );
    if (result.isSuccess) {
      _businesses = result.data ?? const [];
      _businessesState = BusinessLoadState.ready;
    } else {
      _businessesError =
          result.failure?.message ?? 'Failed to load businesses.';
      _businessesState = BusinessLoadState.error;
    }
    notifyListeners();
  }

  // ── Featured ─────────────────────────────────────────────────────────────
  Future<void> loadFeatured() async {
    _featuredState = BusinessLoadState.loading;
    _featuredError = null;
    notifyListeners();
    final result = await _repo.getFeaturedBusinesses();
    if (result.isSuccess) {
      _featured = result.data ?? const [];
      _featuredState = BusinessLoadState.ready;
    } else {
      _featuredError =
          result.failure?.message ?? 'Failed to load featured businesses.';
      _featuredState = BusinessLoadState.error;
    }
    notifyListeners();
  }

  // ── Location filter ──────────────────────────────────────────────────────
  /// Replaces the all-businesses slot with location-filtered results.
  Future<void> loadByLocation(String location) async {
    final trimmed = location.trim();
    if (trimmed.isEmpty) {
      _businesses = const [];
      _businessesError = null;
      _businessesState = BusinessLoadState.ready;
      notifyListeners();
      return;
    }
    _businessesState = BusinessLoadState.loading;
    _businessesError = null;
    notifyListeners();
    final result = await _repo.getBusinessesByLocation(trimmed);
    if (result.isSuccess) {
      _businesses = result.data ?? const [];
      _businessesState = BusinessLoadState.ready;
    } else {
      _businessesError =
          result.failure?.message ?? 'Failed to load businesses.';
      _businessesState = BusinessLoadState.error;
    }
    notifyListeners();
  }

  // ── Single business lookups (do not mutate list slot) ────────────────────
  /// One-shot lookup by id. Returns null on failure or when the server
  /// says not-found.
  Future<ApiBusiness?> getBusiness(String id) async {
    final result = await _repo.getBusinessById(id);
    if (result.isFailure) return null;
    return result.data;
  }

  /// One-shot lookup by admin/owner ObjectId. NOT the owner-name string —
  /// passing a non-ObjectId triggers a server 500.
  Future<ApiBusiness?> getBusinessByOwner(String ownerId) async {
    final result = await _repo.getBusinessByOwner(ownerId);
    if (result.isFailure) return null;
    return result.data;
  }

  // ── Selected business + its products ─────────────────────────────────────
  /// Fetches /businesses/{id}/products and stores both the business and
  /// its products in the "selected" slot. Used when the user taps into a
  /// business to browse its catalog.
  Future<void> selectBusiness(String id) async {
    _selectedState = BusinessLoadState.loading;
    _selectedError = null;
    notifyListeners();
    final result = await _repo.getBusinessProducts(id);
    if (result.isSuccess && result.data != null) {
      _selectedBusiness = result.data!.business;
      _selectedProducts = result.data!.products;
      _selectedState = BusinessLoadState.ready;
    } else {
      _selectedError =
          result.failure?.message ?? 'Failed to load business products.';
      _selectedState = BusinessLoadState.error;
    }
    notifyListeners();
  }

  /// Clears the selected slot. Call when leaving the business-detail screen
  /// so a re-entry starts fresh and the previous business's products don't
  /// flash briefly while the new fetch runs.
  void clearSelected() {
    _selectedBusiness = null;
    _selectedProducts = const [];
    _selectedState = BusinessLoadState.idle;
    _selectedError = null;
    notifyListeners();
  }
}
