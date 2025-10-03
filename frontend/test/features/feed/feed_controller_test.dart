import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telegram_app_frontend/features/feed/data/mock_feed_repository.dart';
import 'package:telegram_app_frontend/features/feed/domain/feed_controller.dart';

void main() {
  group('FeedController', () {
    test('loadInitial populates posts', () async {
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(MockFeedRepository()),
        ],
      );
      addTearDown(container.dispose);

      await waitForFeedToLoad(container);

      final state = container.read(feedControllerProvider);
      expect(state.posts, isNotEmpty);
      expect(state.isLoading, isFalse);
    });

    test('toggleReaction updates post like state', () async {
      final container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(MockFeedRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(feedControllerProvider.notifier);
      await waitForFeedToLoad(container);

      final stateBefore = container.read(feedControllerProvider);
      final postId = stateBefore.posts.first.id;
      final wasLiked = stateBefore.posts.first.isLikedByMe;

      await notifier.toggleReaction(postId);

      final stateAfter = container.read(feedControllerProvider);
      final updatedPost = stateAfter.posts.firstWhere((post) => post.id == postId);
      expect(updatedPost.isLikedByMe, equals(!wasLiked));
    });
  });
}

Future<void> waitForFeedToLoad(ProviderContainer container) async {
  final completer = Completer<void>();
  final subscription = container.listen(
    feedControllerProvider,
    (previous, next) {
      if (!completer.isCompleted && next.posts.isNotEmpty && !next.isLoading) {
        completer.complete();
      }
    },
    fireImmediately: true,
  );

  try {
    await completer.future.timeout(const Duration(seconds: 2));
  } finally {
    subscription.close();
  }
}
