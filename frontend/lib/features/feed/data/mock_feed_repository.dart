import 'dart:math';

import '../../comments/domain/comment.dart';
import '../../profiles/domain/user.dart';
import '../../posts/domain/post.dart';
import 'feed_repository.dart';

class MockFeedRepository implements FeedRepository {
  MockFeedRepository() {
    _seedData();
  }

  final List<Post> _posts = [];
  final _random = Random();

  void _seedData() {
    final users = List.generate(
      8,
      (index) => User(
        id: 'user-$index',
        email: 'user$index@example.com',
        name: 'User $index',
        username: 'user$index',
        department: index % 2 == 0 ? 'Engineering' : 'Design',
        role: index % 2 == 0 ? 'Developer' : 'Designer',
        statusMessage: index % 3 == 0 ? 'In a meeting' : 'Available',
        lastSeen: DateTime.now().subtract(Duration(minutes: index * 7)),
        isAdmin: index == 0,
      ),
    );

    for (var i = 0; i < 20; i++) {
      final author = users[_random.nextInt(users.length)];
      _posts.add(
        Post(
          id: 'post-$i',
          author: author,
          content: 'This is a sample post #$i from \\${author.name}. We can support markdown-lite formatting and @mentions.',
          createdAt: DateTime.now().subtract(Duration(hours: i)),
          visibility: PostVisibility.team,
          likeCount: _random.nextInt(52),
          commentCount: _random.nextInt(14),
          isLikedByMe: i % 3 == 0,
          attachments: i % 4 == 0
              ? [
                  PostAttachment(
                    id: 'att-$i',
                    name: 'architecture_v$i.png',
                    type: PostAttachmentType.image,
                    url: 'https://picsum.photos/seed/$i/600/400',
                    thumbnailUrl: 'https://picsum.photos/seed/$i/300/200',
                    size: 540000,
                  ),
                ]
              : const [],
          commentsPreview: [
            if (i % 2 == 0)
              Comment(
                id: 'comment-${i}a',
                author: users[(i + 1) % users.length],
                body: 'Great update! Looking forward to testing this.',
                createdAt: DateTime.now().subtract(Duration(hours: i, minutes: 15)),
              ),
          ],
        ),
      );
    }
  }

  @override
  Future<({List<Post> posts, FeedCursor nextCursor})> fetchFeed({FeedCursor cursor, int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, _posts.length);
    final nextCursor = end >= _posts.length ? null : end.toString();
    final slice = _posts.sublist(start, end);
    return (posts: slice, nextCursor: nextCursor);
  }

  @override
  Future<Post> createPost({required String content}) async {
    final post = Post(
      id: 'post-${_posts.length + 1}',
      author: _posts.first.author,
      content: content,
      createdAt: DateTime.now(),
      visibility: PostVisibility.team,
    );
    _posts.insert(0, post);
    return post;
  }

  @override
  Future<void> deletePost(String postId) async {
    _posts.removeWhere((post) => post.id == postId);
  }

  @override
  Future<Post> toggleReaction({required String postId}) async {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      throw StateError('Post not found');
    }
    final post = _posts[index];
    final updated = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    _posts[index] = updated;
    return updated;
  }
}
