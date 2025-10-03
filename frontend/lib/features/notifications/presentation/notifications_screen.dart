import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../widgets/app_avatar.dart';

import '../domain/app_notification.dart';
import '../domain/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const routePath = '/home/notifications';
  static const routeName = 'notifications';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: controller.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load notifications: $error')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = items[index];
            return _NotificationTile(notification: notification);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.reaction:
        return Icons.favorite_border;
      case NotificationType.comment:
        return Icons.mode_comment_outlined;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.invitation:
        return Icons.group_add_outlined;
      case NotificationType.admin:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isUnread = notification.status == NotificationStatus.unread;

    return Card(
      elevation: isUnread ? 1 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: AppAvatar(
          initials: notification.actor?.name ?? notification.title,
          radius: 22,
          statusColor: isUnread ? colors.primary : null,
        ),
        title: Text(notification.title,
            style: TextStyle(
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400)),
        subtitle: Text(
            '${notification.body ?? ''}\n${timeago.format(notification.createdAt)}'),
        isThreeLine: true,
        onTap: () => ref
            .read(notificationsControllerProvider.notifier)
            .markRead(notification.id),
      ),
    );
  }
}
