import 'package:flutter/foundation.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

enum OrderLoadState { idle, loading, ready, error }

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repo;

  OrderProvider({required OrderRepository repository}) : _repo = repository;

  List<Order> _orders = const [];
  OrderLoadState _state = OrderLoadState.idle;
  String? _errorMessage;

  List<Order> get orders => _orders;
  OrderLoadState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == OrderLoadState.loading;

  /// Loads both general tickets and simplified order history from /my-orders
  /// and merges them, prioritizing unique orders sorted by most recent date.
  Future<void> fetchOrders() async {
    _state = OrderLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    // Call /ticket/my-orders for simplified history
    final historyResult = await _repo.fetchMyOrders();
    
    // Call general /ticket/ for comprehensive tickets
    final ticketsResult = await _repo.fetchTickets();

    if (historyResult.isSuccess || ticketsResult.isSuccess) {
      final List<Order> fetchedHistory = historyResult.data ?? const [];
      final List<Order> fetchedTickets = ticketsResult.data ?? const [];

      // Merge results avoiding duplicate Order IDs
      final Map<String, Order> uniqueOrders = {};
      
      for (final order in fetchedHistory) {
        uniqueOrders[order.id] = order;
      }
      for (final order in fetchedTickets) {
        // Tickets might have richer details (expanded product data), so override
        uniqueOrders[order.id] = order;
      }

      // Drop ghost tickets whose product references were not populated
      // (all items fell back to the generic "Item" name with zero total).
      _orders = uniqueOrders.values.where((o) => o.isValid).toList();
      
      // Sort: place newest orders at the top (null dates fall back to the end)
      _orders.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return 0;
      });

      _state = OrderLoadState.ready;
    } else {
      _errorMessage = historyResult.failure?.message ?? 
                      ticketsResult.failure?.message ?? 
                      'Failed to load order history.';
      _state = OrderLoadState.error;
    }
    
    notifyListeners();
  }

  /// Drops all cached orders + error state. Called on logout so the next
  /// user (or guest browse) doesn't see the previous user's history.
  void clear() {
    if (_orders.isEmpty && _errorMessage == null) return;
    _orders = const [];
    _errorMessage = null;
    _state = OrderLoadState.idle;
    notifyListeners();
  }

  /// The backend's `_id` for the most recently placed order, set by
  /// [placeLiveOrder] on success. The success screen reads this so it
  /// can show a stable, server-trackable order reference instead of
  /// a synthetic client-side number.
  String? _lastPlacedOrderId;
  String? get lastPlacedOrderId => _lastPlacedOrderId;

  /// Places a live ticket checkout on the backend.
  ///
  /// [paymentMethod] and [paidStatus] default to the COD flow ('cod' /
  /// 'pending') — callers only need to pass them when wiring up another
  /// payment provider (Fonepay etc).
  Future<bool> placeLiveOrder({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required String ticketName,
    required String deliveryLocation,
    String paymentMethod = 'cod',
    String paidStatus = 'pending',
  }) async {
    _state = OrderLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repo.createTicket(
      businessId: businessId,
      items: items,
      ticketName: ticketName,
      deliveryLocation: deliveryLocation,
      paymentMethod: paymentMethod,
      paidStatus: paidStatus,
    );

    if (result.isSuccess) {
      _state = OrderLoadState.ready;
      _lastPlacedOrderId = _extractTicketId(result.data);
      // Fetch fresh order history asynchronously
      fetchOrders().catchError((e, st) {
        debugPrint('🚨 OrderProvider: fetchOrders after placeLiveOrder failed: $e\n$st');
      });
      return true;
    } else {
      _errorMessage = result.failure?.message ?? 'Failed to place order.';
      _state = OrderLoadState.error;
      notifyListeners();
      return false;
    }
  }

  /// Defensive extractor — the `/ticket/` POST response shape isn't
  /// 100% locked down across rebuzzpos environments. Tries the common
  /// places before giving up. Returns null when no usable ID is found.
  String? _extractTicketId(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = <dynamic>[
      data['_id'],
      data['ticketId'],
      data['orderId'],
      (data['ticket'] is Map) ? data['ticket']['_id'] : null,
      (data['order'] is Map) ? data['order']['_id'] : null,
      (data['response'] is Map) ? data['response']['_id'] : null,
    ];
    for (final c in candidates) {
      if (c is String && c.isNotEmpty) return c;
    }
    return null;
  }

  /// Sends a dine-in table request
  Future<bool> requestTableService({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required String requestType,
  }) async {
    final result = await _repo.sendTableRequest(
      businessId: businessId,
      items: items,
      requestType: requestType,
    );
    return result.isSuccess;
  }

  /// Clears the orders state (useful on logout)
  void clearOrders() {
    _orders = const [];
    _state = OrderLoadState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
