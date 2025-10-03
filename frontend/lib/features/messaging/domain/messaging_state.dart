import 'package:equatable/equatable.dart';

import 'conversation.dart';

class MessagingState extends Equatable {
  const MessagingState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  MessagingState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [conversations, isLoading, error];
}
