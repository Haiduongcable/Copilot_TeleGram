import 'package:equatable/equatable.dart';

import '../../profiles/domain/user.dart';
import 'message.dart';

enum ConversationType { direct, group }

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.type,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.photoUrl,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      type: _conversationTypeFrom(json['type'] as String? ?? 'direct'),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(User.fromJson)
          .toList(growable: false),
      lastMessage: json['lastMessage'] is Map<String, dynamic>
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : json['last_message'] is Map<String, dynamic>
              ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
              : null,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? json['unread'] as int? ?? 0,
      isMuted: json['isMuted'] as bool? ?? json['muted'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? json['archived'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
    );
  }

  final String id;
  final String title;
  final ConversationType type;
  final List<User> participants;
  final Message? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final String? photoUrl;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'participants': participants.map((user) => user.toJson()).toList(growable: false),
      'lastMessage': lastMessage?.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isArchived': isArchived,
      'photoUrl': photoUrl,
    };
  }

  Conversation copyWith({
    Message? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
  }) {
    return Conversation(
      id: id,
      title: title,
      type: type,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: DateTime.now(),
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      photoUrl: photoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        participants,
        lastMessage,
        updatedAt,
        unreadCount,
        isMuted,
        isArchived,
        photoUrl,
      ];
}

ConversationType _conversationTypeFrom(String value) {
  return ConversationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ConversationType.direct,
  );
}
