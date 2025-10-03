import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../widgets/app_avatar.dart';
import '../../../widgets/app_badge.dart';

import '../domain/conversation.dart';
import '../domain/messaging_controller.dart';
import 'conversation_screen.dart';

class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  static const routePath = '/home/messaging';
  static const routeName = 'messaging';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsControllerProvider);
    final controller = ref.read(conversationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadConversations,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = state.conversations[index];
                  return _ConversationTile(conversation: conversation);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New chat'),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: AppAvatar(
        initials: conversation.title,
        radius: 24,
        statusColor: conversation.unreadCount > 0 ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(conversation.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        conversation.lastMessage?.body ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            timeago.format(conversation.updatedAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (conversation.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AppBadge(value: conversation.unreadCount.toString()),
            ),
        ],
      ),
      onTap: () {
        ref.read(conversationsControllerProvider.notifier).markRead(conversation.id);
        context.push('${MessagingScreen.routePath}/${conversation.id}', extra: conversation);
      },
    );
  }
}
