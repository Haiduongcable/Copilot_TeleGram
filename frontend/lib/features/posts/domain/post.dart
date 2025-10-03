import 'package:equatable/equatable.dart';

import '../../comments/domain/comment.dart';
import '../../profiles/domain/user.dart';

enum PostVisibility { team, department }

enum PostAttachmentType { image, file }

class PostAttachment extends Equatable {
  const PostAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.thumbnailUrl,
    this.size,
    this.mimeType,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) {
    return PostAttachment(
      id: json['id']?.toString() ?? '',
      type: _attachmentTypeFrom(json['type'] as String? ?? ''),
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['thumbnail_url'] as String?,
      size: json['size'] as int? ?? (json['size'] is num ? (json['size'] as num).toInt() : null),
      mimeType: json['mimeType'] as String? ?? json['mime_type'] as String?,
    );
  }

  final String id;
  final PostAttachmentType type;
  final String url;
  final String name;
  final String? thumbnailUrl;
  final int? size;
  final String? mimeType;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'url': url,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'size': size,
      'mimeType': mimeType,
    };
  }

  @override
  List<Object?> get props => [id, type, url, name, thumbnailUrl, size, mimeType];
}

class Post extends Equatable {
  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.visibility,
    this.attachments = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.isPinned = false,
    this.department,
    this.commentsPreview = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      visibility: _visibilityFrom(json['visibility'] as String? ?? 'team'),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PostAttachment.fromJson)
          .toList(growable: false),
      likeCount: json['likeCount'] as int? ?? json['likes'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? json['comments'] as int? ?? 0,
      isLikedByMe: json['isLikedByMe'] as bool? ?? json['liked'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? json['pinned'] as bool? ?? false,
      department: json['department'] as String?,
      commentsPreview: (json['commentsPreview'] as List<dynamic>? ?? json['comments_preview'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList(growable: false),
    );
  }

  final String id;
  final User author;
  final String content;
  final DateTime createdAt;
  final PostVisibility visibility;
  final List<PostAttachment> attachments;
  final int likeCount;
  final int commentCount;
  final bool isLikedByMe;
  final bool isPinned;
  final String? department;
  final List<Comment> commentsPreview;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'visibility': visibility.name,
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(growable: false),
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLikedByMe': isLikedByMe,
      'isPinned': isPinned,
      'department': department,
      'commentsPreview': commentsPreview.map((comment) => comment.toJson()).toList(growable: false),
    };
  }

  Post copyWith({
    List<PostAttachment>? attachments,
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
    bool? isPinned,
    List<Comment>? commentsPreview,
  }) {
    return Post(
      id: id,
      author: author,
      content: content,
      createdAt: createdAt,
      visibility: visibility,
      attachments: attachments ?? this.attachments,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isPinned: isPinned ?? this.isPinned,
      department: department,
      commentsPreview: commentsPreview ?? this.commentsPreview,
    );
  }

  @override
  List<Object?> get props => [
        id,
        author,
        content,
        createdAt,
        visibility,
        attachments,
        likeCount,
        commentCount,
        isLikedByMe,
        isPinned,
        department,
        commentsPreview,
      ];
}

PostAttachmentType _attachmentTypeFrom(String value) {
  return PostAttachmentType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => PostAttachmentType.file,
  );
}

PostVisibility _visibilityFrom(String value) {
  return PostVisibility.values.firstWhere(
    (visibility) => visibility.name == value,
    orElse: () => PostVisibility.team,
  );
}
