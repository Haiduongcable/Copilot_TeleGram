import '../domain/app_notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications();
  Future<void> markAllRead();
  Future<void> markRead(String notificationId);
}
