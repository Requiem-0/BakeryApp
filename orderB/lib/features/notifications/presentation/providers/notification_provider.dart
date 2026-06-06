import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/api_notification.dart';
import '../../data/repositories/notification_repository.dart';

/// Owns notification state for the app session.
///
/// Server is authoritative — refresh pulls the full list, every mutation
/// is followed by a re-read of the affected flag from the server response.
/// Local mutations are optimistic (UI updates immediately, rolls back on
/// API failure) so taps feel snappy.
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo;

  List<ApiNotification> _items = [];
  bool _loading = false;
  String? _error;

  NotificationProvider({
    ApiClient? apiClient,
    NotificationRepository? repository,
  }) : _repo = repository ?? NotificationRepository(apiClient: apiClient);

  // ── Getters ───────────────────────────────────────────────────

  List<ApiNotification> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  /// Count of notifications the user hasn't read yet. Drives the bell
  /// badge on the home header (and anywhere else that wants an indicator).
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Pulls the full notification list. Call after login or on
  /// pull-to-refresh. Safe to call unauthenticated — a 401 just surfaces
  /// as an error and the list stays empty.
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    final result = await _repo.fetchNotifications();
    if (result.isSuccess) {
      _items = result.data!;
      _error = null;
    } else {
      _error = result.failure?.message;
      debugPrint('🚨 NotificationProvider.refresh failed: $_error');
    }
    _loading = false;
    notifyListeners();
  }

  /// Clears local state. Call on logout so the next user doesn't see the
  /// previous user's notifications during the brief window before refresh.
  void clear() {
    if (_items.isEmpty && _error == null) return;
    _items = [];
    _error = null;
    notifyListeners();
  }

  // ── Mutations ────────────────────────────────────────────────

  /// Flips `isRead: true` on every notification server-side. UI updates
  /// optimistically; on failure the list is re-fetched to recover.
  Future<bool> markAllAsRead() async {
    if (_items.isEmpty || !hasUnread) return true;
    final snapshot = List<ApiNotification>.from(_items);
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    final result = await _repo.markAllAsRead();
    if (result.isSuccess) return true;
    _error = result.failure?.message;
    _items = snapshot;
    debugPrint('🚨 NotificationProvider.markAllAsRead failed: $_error');
    notifyListeners();
    return false;
  }

  /// Update one or more flags on a single notification (read / important
  /// / archived). Pass only what should change.
  Future<bool> updateStatus(
    String id, {
    bool? isRead,
    bool? isImportant,
    bool? isArchived,
  }) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0) return false;
    final original = _items[idx];
    _items[idx] = original.copyWith(
      isRead: isRead,
      isImportant: isImportant,
      isArchived: isArchived,
    );
    notifyListeners();

    final result = await _repo.updateStatus(
      notificationId: id,
      isRead: isRead,
      isImportant: isImportant,
      isArchived: isArchived,
    );
    if (result.isSuccess) return true;
    _error = result.failure?.message;
    _items[idx] = original;
    debugPrint('🚨 NotificationProvider.updateStatus failed: $_error');
    notifyListeners();
    return false;
  }

  /// Convenience wrapper — tapping a notification typically just marks it
  /// read. Bails out (no API call) if it's already read or unknown.
  Future<bool> markAsRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx < 0 || _items[idx].isRead) return Future.value(true);
    return updateStatus(id, isRead: true);
  }
}
