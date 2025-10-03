import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../flavors/flavor_config.dart';
import '../data/mock_notifications_repository.dart';
import '../data/notifications_repository.dart';
import '../data/rest_notifications_repository.dart';
import 'app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final config = FlavorConfig.instance;
  if (config.isFeatureEnabled('useMockData')) {
    return MockNotificationsRepository();
  }
  final dio = ref.watch(dioProvider);
  return RestNotificationsRepository(dio);
});

final notificationsControllerProvider = StateNotifierProvider<NotificationsController, AsyncValue<List<AppNotification>>>(
  (ref) {
    final repository = ref.watch(notificationsRepositoryProvider);
    return NotificationsController(repository)..load();
  },
);

class NotificationsController extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsController(this._repository) : super(const AsyncValue.loading());

  final NotificationsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.fetchNotifications();
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      await load();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _repository.markRead(notificationId);
      await load();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
