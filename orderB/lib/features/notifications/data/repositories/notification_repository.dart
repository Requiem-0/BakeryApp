import 'package:flutter/foundation.dart';
import '../../../../core/errors/api_failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/api_notification.dart';

/// Wraps the `/api/notification/*` family of endpoints.
///
/// Three operations: fetch the list, mark-everything-read in one go, and
/// patch the per-notification flags (read / important / archived).
class NotificationRepository {
  final ApiClient _api;

  NotificationRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  /// GET /api/notification/  — all notifications for the logged-in user.
  ///
  /// Server response: `{ status, data: { notifications: [...] } }`.
  Future<ApiResult<List<ApiNotification>>> fetchNotifications() async {
    try {
      final res = await _api.get('/notification/');
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        return ApiResult.failure(const ApiFailure(
          message: 'Unexpected response shape from /notification/.',
        ));
      }
      final inner = data['data'];
      final raw = inner is Map<String, dynamic> ? inner['notifications'] : null;
      if (raw is List) {
        return ApiResult.success(
          raw
              .whereType<Map<String, dynamic>>()
              .map(ApiNotification.fromJson)
              .toList(),
        );
      }
      return ApiResult.success(const []);
    } catch (e) {
      debugPrint('🚨 NotificationRepository.fetchNotifications: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// PATCH /api/notification/mark-as-read  — flips `isRead: true` on every
  /// notification for the logged-in user in one server hop.
  Future<ApiResult<void>> markAllAsRead() async {
    try {
      await _api.patch('/notification/mark-as-read');
      return ApiResult.success(null);
    } catch (e) {
      debugPrint('🚨 NotificationRepository.markAllAsRead: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }

  /// PATCH /api/notification/{id}/status  — update one or more flags on
  /// a single notification. Only the fields you pass are sent; nulls are
  /// omitted so a partial update doesn't clobber unrelated flags.
  Future<ApiResult<void>> updateStatus({
    required String notificationId,
    bool? isRead,
    bool? isImportant,
    bool? isArchived,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isRead != null) body['isRead'] = isRead;
      if (isImportant != null) body['isImportant'] = isImportant;
      if (isArchived != null) body['isArchived'] = isArchived;
      await _api.patch('/notification/$notificationId/status', body: body);
      return ApiResult.success(null);
    } catch (e) {
      debugPrint('🚨 NotificationRepository.updateStatus: $e');
      return ApiResult.failure(ApiClient.parseError(e));
    }
  }
}
