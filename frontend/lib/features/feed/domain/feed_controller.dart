import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../flavors/flavor_config.dart';
import '../data/feed_repository.dart';
import '../data/mock_feed_repository.dart';
import '../data/rest_feed_repository.dart';
import 'feed_state.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final config = FlavorConfig.instance;
  if (config.isFeatureEnabled('useMockData')) {
    return MockFeedRepository();
  }
  final dio = ref.watch(dioProvider);
  return RestFeedRepository(dio);
});

final feedControllerProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedController(repository);
});

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository) : super(const FeedState()) {
    loadInitial();
  }

  final FeedRepository _repository;
  String? _cursor;
  bool _isFetching = false;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    _cursor = null;
    await _loadMore(reset: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, error: null);
    _cursor = null;
    await _loadMore(reset: true);
  }

  Future<void> loadMore() async => _loadMore();

  Future<void> toggleReaction(String postId) async {
    try {
      final updatedPost = await _repository.toggleReaction(postId: postId);
      final updatedPosts = state.posts
          .map((post) => post.id == updatedPost.id ? updatedPost : post)
          .toList(growable: false);
      state = state.copyWith(posts: updatedPosts);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_isFetching || (!state.hasMore && !reset)) {
      return;
    }
    _isFetching = true;
    try {
      final result = await _repository.fetchFeed(cursor: _cursor);
      _cursor = result.nextCursor;
      state = state.copyWith(
        posts: reset ? result.posts : [...state.posts, ...result.posts],
        isLoading: false,
        isRefreshing: false,
        hasMore: result.nextCursor != null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }
}
