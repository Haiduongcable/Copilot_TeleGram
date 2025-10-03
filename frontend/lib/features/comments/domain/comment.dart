import 'package:equatable/equatable.dart';

import '../../profiles/domain/user.dart';

enum CommentStatus { published, edited, deleted }

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.parentId,
    this.status = CommentStatus.published,
    this.updatedAt,
    this.mentions = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      status: _statusFrom(json['status']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'] as String)
              : null,
      mentions: (json['mentions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(User.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final User author;
  final String body;
  final DateTime createdAt;
  final String? parentId;
  final CommentStatus status;
  final DateTime? updatedAt;
  final List<User> mentions;

  bool get isReply => parentId != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'parentId': parentId,
      'status': status.name,
      'updatedAt': updatedAt?.toIso8601String(),
      'mentions': mentions.map((user) => user.toJson()).toList(growable: false),
    };
  }

  Comment copyWith({
    String? body,
    CommentStatus? status,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id,
      author: author,
      body: body ?? this.body,
      createdAt: createdAt,
      parentId: parentId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      mentions: mentions,
    );
  }

  @override
  List<Object?> get props => [id, author, body, createdAt, parentId, status, updatedAt, mentions];
}

CommentStatus _statusFrom(dynamic value) {
  if (value is String) {
    return CommentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CommentStatus.published,
    );
  }
  return CommentStatus.published;
}
