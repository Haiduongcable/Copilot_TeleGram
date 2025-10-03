import 'dart:async';
import 'dart:math';

import '../../profiles/domain/user.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'messaging_repository.dart';

class MockMessagingRepository implements MessagingRepository {
  MockMessagingRepository() {
    _seedData();
  }

  final _conversations = <Conversation>[];
  final _messages = <String, List<Message>>{};
  final _controllers = <String, StreamController<Message>>{};
  final _random = Random();

  void _seedData() {
    final users = List.generate(
      6,
      (index) => User(
        id: 'chat-user-$index',
        email: 'chat$index@example.com',
        name: 'Chat User $index',
        username: 'chat$index',
        department: index % 2 == 0 ? 'Engineering' : 'Design',
        role: index.isEven ? 'Developer' : 'Designer',
        lastSeen: DateTime.now().subtract(Duration(minutes: index * 4)),
      ),
    );

    for (var i = 0; i < 5; i++) {
      final conversationId = 'conversation-$i';
      final participants = users.sublist(0, 2 + _random.nextInt(3));
      final messageList = <Message>[];
      for (var j = 0; j < 12; j++) {
        final sender = participants[_random.nextInt(participants.length)];
        final message = Message(
          id: 'msg-$i-$j',
          conversationId: conversationId,
          sender: sender,
          body: 'Sample message $j in conversation $i from ${sender.name}',
          createdAt: DateTime.now().subtract(Duration(minutes: 5 * j)),
          status: MessageStatus.read,
        );
        messageList.add(message);
      }
      messageList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _messages[conversationId] = messageList;
      _conversations.add(
        Conversation(
          id: conversationId,
          title: participants.map((user) => user.name.split(' ').first).take(3).join(', '),
          type: participants.length > 2 ? ConversationType.group : ConversationType.direct,
          participants: participants,
          lastMessage: messageList.first,
          updatedAt: messageList.first.createdAt,
          unreadCount: i % 2 == 0 ? _random.nextInt(5) : 0,
          isMuted: i == 2,
        ),
      );
      _controllers[conversationId] = StreamController<Message>.broadcast();
    }
  }

  @override
  Future<List<Conversation>> fetchConversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(_conversations);
  }

  @override
  Future<List<Message>> fetchConversationMessages(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final messages = _messages[conversationId] ?? [];
    return List.unmodifiable(messages.reversed);
  }

  @override
  Stream<Message> subscribeToMessages(String conversationId) {
    return _controllers[conversationId]!.stream;
  }

  @override
  Future<Message> sendMessage({required String conversationId, required String body}) async {
    final participants =
        _conversations.firstWhere((conversation) => conversation.id == conversationId).participants;
    final sender = participants.first;
    final message = Message(
      id: 'msg-${conversationId}-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      sender: sender,
      body: body,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.putIfAbsent(conversationId, () => []).add(message);
    _controllers[conversationId]?.add(message);
    final index = _conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(lastMessage: message, unreadCount: 0);
    }
    return message;
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    final index = _conversations.indexWhere((conversation) => conversation.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(unreadCount: 0);
    }
  }
}
