import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../domain/conversation.dart';
import '../domain/message.dart';
import '../domain/messaging_controller.dart';
import 'messaging_screen.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({
    super.key,
    required this.conversationId,
    this.initialConversation,
  });

  static const routeName = 'conversation';

  static String routePath(String conversationId) => '${MessagingScreen.routePath}/$conversationId';

  final String conversationId;
  final Conversation? initialConversation;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    final conversation = widget.initialConversation;

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.title ?? 'Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed to load messages: $error')),
              data: (messages) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final myId = conversation != null && conversation.participants.isNotEmpty
                        ? conversation.participants.first.id
                        : null;
                    final isMine = myId != null && myId == message.sender.id;
                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        filled: true,
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      ref.read(conversationMessagesProvider(widget.conversationId).notifier).sendMessage(text);
                      _messageController.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final colors = Theme.of(context).colorScheme;
    final bubbleColor = isMine ? colors.primary : colors.surfaceVariant;
    final textColor = isMine ? colors.onPrimary : colors.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isMine ? 64 : 0,
        right: isMine ? 0 : 64,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(message.body, style: TextStyle(color: textColor)),
          ),
          const SizedBox(height: 4),
          Text(
            timeago.format(message.createdAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
