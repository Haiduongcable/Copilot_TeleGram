import '../domain/app_notification.dart';
import '../../profiles/domain/user.dart';
import 'notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository() {
    _seed();
  }

  final _notifications = <AppNotification>[];

  void _seed() {
    final actor = User(
      id: 'actor-1',
      email: 'colleague@example.com',
      name: 'Colleague One',
      username: 'colleague1',
      department: 'Engineering',
      role: 'Engineer',
      statusMessage: 'Ready to chat',
    );
    for (var i = 0; i < 12; i++) {
      _notifications.add(
        AppNotification(
          id: 'notification-$i',
          type: NotificationType.values[i % NotificationType.values.length],
          title: 'Notification #$i',
          body: 'This is a sample notification body for item $i',
          createdAt: DateTime.now().subtract(Duration(minutes: i * 3)),
          actor: actor,
          status: i % 3 == 0 ? NotificationStatus.unread : NotificationStatus.read,
        ),
      );
    }
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_notifications);
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(status: NotificationStatus.read);
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _notifications.indexWhere((element) => element.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(status: NotificationStatus.read);
    }
  }
}
