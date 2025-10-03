import 'package:equatable/equatable.dart';

enum SearchCategory { people, posts, conversations }

enum SearchResultType { user, post, conversation }

class SearchResult extends Equatable {
  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.category,
  });

  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final SearchCategory category;

  @override
  List<Object?> get props => [id, title, subtitle, type, category];
}
