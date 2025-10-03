import '../domain/feed_state.dart';
import '../../posts/domain/post.dart';

typedef FeedCursor = String?;

abstract class FeedRepository {
  Future<({List<Post> posts, FeedCursor nextCursor})> fetchFeed({FeedCursor cursor, int limit = 20});
  Future<Post> createPost({required String content});
  Future<Post> toggleReaction({required String postId});
  Future<void> deletePost(String postId);
}
