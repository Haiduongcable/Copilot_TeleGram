import 'package:equatable/equatable.dart';

import '../../profiles/domain/user.dart';

enum MessageStatus { sending, sent, delivered, read }

enum MessageType { text, image, file }

class Message extends Equatable {
  const Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.createdAt,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.replyTo,
    this.attachments = const [],
    this.editedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? json['conversation_id']?.toString() ?? '',
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      body: json['body'] as String? ?? json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: _messageTypeFrom(json['type'] as String? ?? 'text'),
      status: _messageStatusFrom(json['status']),
      replyTo: json['replyTo'] != null
          ? Message.fromJson(json['replyTo'] as Map<String, dynamic>)
          : json['reply_to'] != null
              ? Message.fromJson(json['reply_to'] as Map<String, dynamic>)
              : null,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((attachment) => attachment.toString())
          .toList(growable: false),
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'] as String)
          : json['edited_at'] != null
              ? DateTime.tryParse(json['edited_at'] as String)
              : null,
    );
  }

  final String id;
  final String conversationId;
  final User sender;
  final String body;
  final DateTime createdAt;
  final MessageType type;
  final MessageStatus status;
  final Message? replyTo;
  final List<String> attachments;
  final DateTime? editedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender.toJson(),
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'replyTo': replyTo?.toJson(),
      'attachments': attachments,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    MessageStatus? status,
    DateTime? editedAt,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      sender: sender,
      body: body,
      createdAt: createdAt,
      type: type,
      status: status ?? this.status,
      replyTo: replyTo,
      attachments: attachments,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        sender,
        body,
        createdAt,
        type,
        status,
        replyTo,
        attachments,
        editedAt,
      ];
}

MessageType _messageTypeFrom(String value) {
  return MessageType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => MessageType.text,
  );
}

MessageStatus _messageStatusFrom(dynamic value) {
  if (value is String) {
    return MessageStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MessageStatus.sent,
    );
  }
  return MessageStatus.sent;
}
