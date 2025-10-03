import 'dart:math';

import '../domain/search_result.dart';
import 'search_repository.dart';

class MockSearchRepository implements SearchRepository {
  @override
  Future<List<SearchResult>> globalSearch(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final random = Random(query.hashCode);
    return List.generate(12, (index) {
      final category = SearchCategory.values[index % SearchCategory.values.length];
      return SearchResult(
        id: '${category.name}-${index + 1}',
        title: '${query.toUpperCase()} result ${index + 1}',
        subtitle: category == SearchCategory.people
            ? 'Department • Role'
            : category == SearchCategory.posts
                ? 'Snippet of a post containing $query'
                : 'Latest message preview mentioning $query',
        type: SearchResultType.values[index % SearchResultType.values.length],
        category: category,
      );
    })..shuffle(random);
  }
}
