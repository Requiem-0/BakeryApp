import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/address.dart';
import '../../data/repositories/location_repository.dart';

/// Manages delivery addresses backed by `/api/location/*`.
///
/// Server is the single source of truth — every mutation replaces the
/// in-memory list with whatever the server returned (each endpoint returns
/// the post-op full list). Selection lives on the server too, via the
/// `isActive` flag: [select] PATCHes the chosen entry with `isActive: true`
/// and the backend auto-deactivates the rest, so at most one entry is
/// ever active.
///
/// No local SharedPreferences caching of selection — the active address
/// survives across devices and reinstalls because the server holds it.
class AddressProvider extends ChangeNotifier {
  final LocationRepository _repo;
  List<Address> _addresses = [];
  bool _loading = false;
  String? _error;

  AddressProvider({
    ApiClient? apiClient,
    LocationRepository? locationRepository,
  }) : _repo = locationRepository ?? LocationRepository(apiClient: apiClient);

  // ── Public getters ────────────────────────────────────────────

  List<Address> get addresses => _addresses;
  bool get loading => _loading;
  String? get error => _error;

  /// Id of the currently-active address (the one with `isActive: true`).
  /// Falls back to the first address (or empty string) if none is marked
  /// active yet, so the UI can render before the user has set one.
  String get selectedId {
    for (final a in _addresses) {
      if (a.isActive) return a.id;
    }
    return _addresses.isNotEmpty ? _addresses.first.id : '';
  }

  /// The full active address record. Returns a placeholder when the list
  /// is empty so the UI never reads from null.
  Address get selected {
    for (final a in _addresses) {
      if (a.isActive) return a;
    }
    if (_addresses.isNotEmpty) return _addresses.first;
    return const Address(
      id: '',
      label: 'No address',
      address: 'Add a delivery address to continue',
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Fetches addresses from the server. Call after login or on
  /// pull-to-refresh. Safe to call when unauthenticated — the 401 just
  /// surfaces as an error and the list stays empty.
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    final result = await _repo.fetchLocations();
    if (result.isSuccess) {
      _addresses = result.data!.map(Address.fromApiLocation).toList();
      _error = null;
    } else {
      _error = result.failure?.message;
      debugPrint('🚨 AddressProvider.refresh failed: $_error');
    }
    _loading = false;
    notifyListeners();
  }

  /// Clears the address list. Call on logout so the next user doesn't see
  /// the previous user's saved addresses.
  void clear() {
    if (_addresses.isEmpty && _error == null) return;
    _addresses = [];
    _error = null;
    notifyListeners();
  }

  // ── Selection ─────────────────────────────────────────────────

  /// Marks the given address active server-side. Other addresses are
  /// auto-deactivated by the backend. Returns true on success.
  Future<bool> select(String id) async {
    final result = await _repo.updateLocation(
      locationId: id,
      isActive: true,
    );
    if (result.isSuccess) {
      _addresses = result.data!.map(Address.fromApiLocation).toList();
      _error = null;
      notifyListeners();
      return true;
    }
    _error = result.failure?.message;
    debugPrint('🚨 AddressProvider.select failed: $_error');
    notifyListeners();
    return false;
  }

  // ── CRUD ──────────────────────────────────────────────────────

  /// Creates a new address. Newly-added entries default to `isActive: true`
  /// (becoming the new default), matching what the UI expects after the
  /// user just typed in a fresh address.
  Future<bool> addAddress({
    required String name,
    required String phone,
    required String address,
    double latitude = 0,
    double longitude = 0,
    String landmark = '',
    bool isActive = true,
  }) async {
    final result = await _repo.createLocation(
      name: name,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      landmark: landmark,
      isActive: isActive,
    );
    if (result.isSuccess) {
      _addresses = result.data!.map(Address.fromApiLocation).toList();
      _error = null;
      notifyListeners();
      return true;
    }
    _error = result.failure?.message;
    debugPrint('🚨 AddressProvider.addAddress failed: $_error');
    notifyListeners();
    return false;
  }

  /// Updates an existing address. Pass only the fields that changed.
  Future<bool> updateAddress({
    required String id,
    String? name,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? landmark,
    bool? isActive,
  }) async {
    final result = await _repo.updateLocation(
      locationId: id,
      name: name,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      landmark: landmark,
      isActive: isActive,
    );
    if (result.isSuccess) {
      _addresses = result.data!.map(Address.fromApiLocation).toList();
      _error = null;
      notifyListeners();
      return true;
    }
    _error = result.failure?.message;
    debugPrint('🚨 AddressProvider.updateAddress failed: $_error');
    notifyListeners();
    return false;
  }

  /// Removes an address. The server returns the remaining list, so any
  /// in-memory references to the deleted id are dropped automatically.
  Future<bool> deleteAddress(String id) async {
    final result = await _repo.deleteLocation(id);
    if (result.isSuccess) {
      _addresses = result.data!.map(Address.fromApiLocation).toList();
      _error = null;
      notifyListeners();
      return true;
    }
    _error = result.failure?.message;
    debugPrint('🚨 AddressProvider.deleteAddress failed: $_error');
    notifyListeners();
    return false;
  }
}
