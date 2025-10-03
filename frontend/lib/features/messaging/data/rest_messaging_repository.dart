import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../flavors/flavor_config.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'messaging_repository.dart';

class RestMessagingRepository implements MessagingRepository {
  RestMessagingRepository(this._dio) : _config = FlavorConfig.instance;

  final Dio _dio;
  final FlavorConfig _config;
  final _channels = <String, WebSocketChannel>{};

  ApiEndpoints get _api => _config.apiEndpoints;
  WebSocketEndpoints get _ws => _config.wsEndpoints;

  @override
  Future<List<Conversation>> fetchConversations() async {
    final response = await _dio.get<dynamic>(_api.messaging);
    final payload = response.data;
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic>
            ? payload['conversations'] as List<dynamic>? ?? payload['items'] as List<dynamic>? ?? []
            : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Conversation.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Message>> fetchConversationMessages(String conversationId) async {
    final response = await _dio.get<dynamic>('${_api.messaging}/$conversationId/messages');
    final payload = response.data;
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic>
            ? payload['messages'] as List<dynamic>? ?? payload['items'] as List<dynamic>? ?? []
            : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Message.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    await _dio.post('${_api.messaging}/$conversationId/read');
  }

  @override
  Future<Message> sendMessage({required String conversationId, required String body}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_api.messaging}/$conversationId/messages',
      data: {'body': body},
    );
    return Message.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Stream<Message> subscribeToMessages(String conversationId) {
    final existing = _channels[conversationId];
    if (existing != null) {
      return existing.stream.map(_decodeMessage);
    }

    final uri = Uri.parse('${_ws.baseUrl}${_ws.messaging}?conversationId=$conversationId');
    final channel = WebSocketChannel.connect(uri);
    _channels[conversationId] = channel;
    return channel.stream.map(_decodeMessage).handleError((error, stackTrace) {
      channel.sink.add(jsonEncode({'type': 'ping'}));
    });
  }

  Message _decodeMessage(dynamic data) {
    if (data is String) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return Message.fromJson(decoded);
    }
    if (data is Map<String, dynamic>) {
      return Message.fromJson(data);
    }
    throw StateError('Unsupported message payload: $data');
  }
}
