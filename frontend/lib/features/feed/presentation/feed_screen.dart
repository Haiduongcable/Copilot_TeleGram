import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../posts/domain/post.dart';
import '../../posts/presentation/post_detail_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../../services/connectivity/connectivity_providers.dart';
import '../../../widgets/app_avatar.dart';
import '../../../widgets/offline_banner.dart';
import '../domain/feed_controller.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  static const routePath = '/home/feed';
  static const routeName = 'feed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedControllerProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOffline = connectivity.maybeWhen(
        data: (isConnected) => !isConnected, orElse: () => false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(SearchScreen.routePath),
          ),
          IconButton(
            icon: const Icon(Icons.create_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OfflineBanner(isVisible: isOffline)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = feedState.posts[index];
                    return _PostCard(post: post);
                  },
                  childCount: feedState.posts.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: feedState.hasMore
                      ? ElevatedButton.icon(
                          onPressed: () => ref
                              .read(feedControllerProvider.notifier)
                              .loadMore(),
                          icon: const Icon(Icons.more_horiz),
                          label: const Text('Load more'),
                        )
                      : const Text('You are all caught up!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => context.push('${FeedScreen.routePath}/post/${post.id}',
            extra: post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(
                    initials: post.author.name,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${post.author.role ?? ''} • ${timeago.format(post.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (post.isPinned)
                    Icon(Icons.push_pin, color: colors.primary, size: 18),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'pin', child: Text('Pin')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.content),
              if (post.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final attachment = post.attachments[index];
                      return AspectRatio(
                        aspectRatio: 3 / 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            attachment.thumbnailUrl ?? attachment.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colors.surfaceVariant,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: post.attachments.length,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLikedByMe
                          ? Icons.favorite
                          : Icons.favorite_outline,
                      color: post.isLikedByMe ? colors.primary : null,
                    ),
                    onPressed: () => ref
                        .read(feedControllerProvider.notifier)
                        .toggleReaction(post.id),
                  ),
                  Text('${post.likeCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.mode_comment_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: const Text('Share'),
                  ),
                ],
              ),
              if (post.commentsPreview.isNotEmpty) ...[
                const Divider(),
                ...post.commentsPreview.map(
                  (comment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppAvatar(
                          initials: comment.author.name,
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: '${comment.author.name} ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: comment.body),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View all comments'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
