import 'package:equatable/equatable.dart';

import '../../profiles/domain/user.dart';

enum NotificationType {
  message,
  reaction,
  comment,
  mention,
  invitation,
  admin,
}

enum NotificationStatus { unread, read }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.status = NotificationStatus.unread,
    this.actor,
    this.targetId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: _notificationTypeFrom(json['type'] as String? ?? 'message'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      status: _notificationStatusFrom(json['status']),
      actor: json['actor'] is Map<String, dynamic> ? User.fromJson(json['actor'] as Map<String, dynamic>) : null,
      targetId: json['targetId']?.toString() ?? json['target_id']?.toString(),
    );
  }

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationStatus status;
  final User? actor;
  final String? targetId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'actor': actor?.toJson(),
      'targetId': targetId,
    };
  }

  AppNotification copyWith({NotificationStatus? status}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      status: status ?? this.status,
      actor: actor,
      targetId: targetId,
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, createdAt, status, actor, targetId];
}

NotificationType _notificationTypeFrom(String value) {
  return NotificationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => NotificationType.message,
  );
}

NotificationStatus _notificationStatusFrom(dynamic value) {
  if (value is String) {
    return NotificationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => NotificationStatus.unread,
    );
  }
  return NotificationStatus.unread;
}
