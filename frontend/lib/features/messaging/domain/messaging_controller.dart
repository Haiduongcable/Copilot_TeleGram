import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../flavors/flavor_config.dart';
import '../data/messaging_repository.dart';
import '../data/mock_messaging_repository.dart';
import '../data/rest_messaging_repository.dart';
import 'conversation.dart';
import 'message.dart';
import 'messaging_state.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  final config = FlavorConfig.instance;
  if (config.isFeatureEnabled('useMockData')) {
    return MockMessagingRepository();
  }
  final dio = ref.watch(dioProvider);
  return RestMessagingRepository(dio);
});

final conversationsControllerProvider = StateNotifierProvider<ConversationsController, MessagingState>((ref) {
  final repository = ref.watch(messagingRepositoryProvider);
  return ConversationsController(repository);
});

final conversationMessagesProvider = StateNotifierProvider.family<ConversationMessagesController, AsyncValue<List<Message>>, String>(
  (ref, conversationId) {
    final repository = ref.watch(messagingRepositoryProvider);
    return ConversationMessagesController(repository: repository, conversationId: conversationId);
  },
);

class ConversationsController extends StateNotifier<MessagingState> {
  ConversationsController(this._repository) : super(const MessagingState()) {
    loadConversations();
  }

  final MessagingRepository _repository;

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations = await _repository.fetchConversations();
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> markRead(String conversationId) async {
    final updated = state.conversations.map((conversation) {
      if (conversation.id == conversationId) {
        return conversation.copyWith(unreadCount: 0);
      }
      return conversation;
    }).toList(growable: false);
    state = state.copyWith(conversations: updated);
    try {
      await _repository.markConversationRead(conversationId);
    } catch (_) {
      // Silently ignore network errors; UI already optimistic.
    }
  }
}

class ConversationMessagesController extends StateNotifier<AsyncValue<List<Message>>> {
  ConversationMessagesController({required MessagingRepository repository, required this.conversationId})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    _subscription = _repository.subscribeToMessages(conversationId).listen(_handleIncomingMessage);
    _loadMessages();
  }

  final MessagingRepository _repository;
  final String conversationId;
  late final StreamSubscription<Message> _subscription;

  Future<void> _loadMessages() async {
    try {
      final messages = await _repository.fetchConversationMessages(conversationId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> sendMessage(String body) async {
    final current = state.value ?? const <Message>[];
    try {
      final message = await _repository.sendMessage(conversationId: conversationId, body: body);
      state = AsyncValue.data([...current, message]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _handleIncomingMessage(Message message) {
    final current = state.value ?? const <Message>[];
    state = AsyncValue.data([...current, message]);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
