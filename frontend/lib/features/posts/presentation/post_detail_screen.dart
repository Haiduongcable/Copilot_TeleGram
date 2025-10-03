import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../comments/domain/comment.dart';
import '../domain/post.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.post});

  static const routeName = 'post-detail';

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Post details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(post.author.name.characters.first.toUpperCase())),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(timeago.format(post.createdAt), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(post.content, style: Theme.of(context).textTheme.bodyLarge),
          if (post.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...post.attachments.map(
              (attachment) => Card(
                clipBehavior: Clip.antiAlias,
                child: switch (attachment.type) {
                  PostAttachmentType.image => Image.network(attachment.url, fit: BoxFit.cover),
                  PostAttachmentType.file => ListTile(
                      leading: const Icon(Icons.insert_drive_file_outlined),
                      title: Text(attachment.name),
                      subtitle: Text('${attachment.size ?? 0} bytes • ${attachment.mimeType ?? 'file'}'),
                    ),
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Comments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (post.commentsPreview.isEmpty)
            const Text('No comments yet. Be the first to respond!')
          else
            ...post.commentsPreview.map((comment) => _CommentTile(comment: comment, colors: colors)),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: () {},
              child: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.colors});

  final Comment comment;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text(comment.author.name.characters.first.toUpperCase())),
                const SizedBox(width: 8),
                Text(comment.author.name, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(timeago.format(comment.createdAt), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.body),
            if (comment.isReply) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colors.surfaceVariant,
                ),
                padding: const EdgeInsets.all(8),
                child: Text('Replying to ${comment.parentId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
