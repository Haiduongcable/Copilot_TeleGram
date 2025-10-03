import 'package:dio/dio.dart';

import '../../../flavors/flavor_config.dart';
import '../../posts/domain/post.dart';
import 'feed_repository.dart';

class RestFeedRepository implements FeedRepository {
  RestFeedRepository(this._dio) : _config = FlavorConfig.instance;

  final Dio _dio;
  final FlavorConfig _config;

  String get _feedPath => _config.apiEndpoints.feed;

  @override
  Future<({List<Post> posts, FeedCursor nextCursor})> fetchFeed({FeedCursor cursor, int limit = 20}) async {
    final response = await _dio.get<dynamic>(
      _feedPath,
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    final payload = response.data;
    List<dynamic> rawPosts;
    String? nextCursor;

    if (payload is List) {
      rawPosts = payload;
      nextCursor = response.headers.map['x-next-cursor']?.first;
    } else if (payload is Map<String, dynamic>) {
      rawPosts = payload['items'] as List<dynamic>? ?? [];
      nextCursor = payload['nextCursor'] as String? ?? payload['next_cursor'] as String?;
    } else {
      rawPosts = const [];
      nextCursor = null;
    }

    final posts = rawPosts
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList(growable: false);

    return (posts: posts, nextCursor: nextCursor);
  }

  @override
  Future<Post> createPost({required String content}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _feedPath,
      data: {'content': content},
    );
    final body = response.data ?? <String, dynamic>{};
    final postJson = body['post'] as Map<String, dynamic>? ?? body;
    return Post.fromJson(postJson);
  }

  @override
  Future<void> deletePost(String postId) async {
    await _dio.delete('$_feedPath/$postId');
  }

  @override
  Future<Post> toggleReaction({required String postId}) async {
    final response = await _dio.post<Map<String, dynamic>>('$_feedPath/$postId/reactions');
    final body = response.data ?? <String, dynamic>{};
    final postJson = body['post'] as Map<String, dynamic>? ?? body;
    return Post.fromJson(postJson);
  }
}
