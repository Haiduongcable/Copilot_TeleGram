import 'package:dio/dio.dart';

import '../../../flavors/flavor_config.dart';
import '../domain/app_notification.dart';
import 'notifications_repository.dart';

class RestNotificationsRepository implements NotificationsRepository {
  RestNotificationsRepository(this._dio) : _config = FlavorConfig.instance;

  final Dio _dio;
  final FlavorConfig _config;

  String get _notificationsPath => _config.apiEndpoints.notifications;

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _dio.get<dynamic>(_notificationsPath);
    final payload = response.data;
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic>
            ? payload['notifications'] as List<dynamic>? ?? payload['items'] as List<dynamic>? ?? []
            : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markAllRead() async {
    await _dio.post('$_notificationsPath/mark-all-read');
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _dio.post('$_notificationsPath/$notificationId/read');
  }
}
