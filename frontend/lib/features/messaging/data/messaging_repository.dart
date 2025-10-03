import '../domain/conversation.dart';
import '../domain/message.dart';

abstract class MessagingRepository {
  Future<List<Conversation>> fetchConversations();
  Future<List<Message>> fetchConversationMessages(String conversationId);
  Stream<Message> subscribeToMessages(String conversationId);
  Future<Message> sendMessage({
    required String conversationId,
    required String body,
  });
  Future<void> markConversationRead(String conversationId);
}
