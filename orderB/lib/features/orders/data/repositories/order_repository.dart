import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/json_helpers.dart';
import '../models/order.dart';

/// Wraps the /api/ticket/* family of endpoints.
class OrderRepository {
  final ApiClient _api;

  OrderRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  /// GET /api/ticket/
  /// Fetches all tickets/orders for the logged-in customer.
  Future<ApiResult<List<Order>>> fetchTickets() async {
    try {
      final res = await _api.get('/ticket/');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response format from /ticket/.',
        ));
      }
      return ApiResult.success(
        parseObjectList(data['tickets'], Order.fromJson),
      );
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/ticket/my-orders
  /// Retrieves custom simplified order history for the logged-in customer.
  Future<ApiResult<List<Order>>> fetchMyOrders() async {
    try {
      final res = await _api.get('/ticket/my-orders');
      final data = res.data;
      if (data is! List) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected list response format from /ticket/my-orders.',
        ));
      }
      return ApiResult.success(
        data.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// GET /api/ticket/{order_id}
  /// Fetches the full detailed ticket metadata.
  Future<ApiResult<Order>> fetchTicketDetails(String orderId) async {
    try {
      final res = await _api.get('/ticket/$orderId');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected ticket details response shape.',
        ));
      }
      return ApiResult.success(Order.fromJson(data));
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// POST /api/ticket/
  /// Creates a live checkout ticket/order on the backend.
  ///
  /// Payment is **cash-on-delivery only** for now — every order goes out
  /// with `paymentMethod: 'cod'` and `paidStatus: 'pending'`. Online
  /// payment (Fonepay) + tracking will plug in later; the parameters
  /// stay overrideable so the wire-up will be one extra arg, not a
  /// repo rewrite. [deliveryTime] is also overrideable so a scheduled-
  /// pickup picker can pass a slot; absent that, we send the customer's
  /// current local time as an ASAP request.
  Future<ApiResult<Map<String, dynamic>>> createTicket({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required String ticketName,
    required String deliveryLocation,
    String paymentMethod = 'cod',
    String paidStatus = 'pending',
    Map<String, dynamic>? deliveryTime,
  }) async {
    try {
      final now = DateTime.now();
      final body = {
        'businessId': businessId,
        'items': items,
        'ticketName': ticketName,
        'deliveryLocation': deliveryLocation,
        'deliveryTime': deliveryTime ?? _defaultDeliveryTime(now),
        'paidStatus': paidStatus,
        'paymentMethod': paymentMethod,
      };

      final res = await _api.post('/ticket/', body: body);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected ticket response from backend.',
        ));
      }
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// Picks the ASAP slot from the current local time. Backend only
  /// accepts a fixed preset enum (`morning | afternoon | evening |
  /// night`) — no `asap` value — so we map the hour to whichever
  /// bucket the customer is in right now.
  Map<String, dynamic> _defaultDeliveryTime(DateTime now) {
    final h = now.hour;
    final preset = h >= 5 && h < 12
        ? 'morning'
        : h >= 12 && h < 17
            ? 'afternoon'
            : h >= 17 && h < 21
                ? 'evening'
                : 'night';
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return {
      'preset': preset,
      'start': '$hh:$mm',
      'date': now.toIso8601String().split('T').first,
    };
  }

  /// POST /api/ticket/table-request
  /// Creates a dine-in table request (requires table session or table user role).
  Future<ApiResult<Map<String, dynamic>>> sendTableRequest({
    required String businessId,
    required List<Map<String, dynamic>> items,
    required String requestType,
  }) async {
    try {
      final body = {
        'businessId': businessId,
        'items': items,
        'requestType': requestType, // water | waiter | food | bill
      };
      final res = await _api.post('/ticket/table-request', body: body);
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected table request response.',
        ));
      }
      return ApiResult.success(data);
    } catch (e) {
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }
}
