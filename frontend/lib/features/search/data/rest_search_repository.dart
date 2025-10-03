import 'package:dio/dio.dart';

import '../../../flavors/flavor_config.dart';
import '../domain/search_result.dart';
import 'search_repository.dart';

class RestSearchRepository implements SearchRepository {
  RestSearchRepository(this._dio) : _config = FlavorConfig.instance;

  final Dio _dio;
  final FlavorConfig _config;

  String get _searchPath => _config.apiEndpoints.search;

  @override
  Future<List<SearchResult>> globalSearch(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _searchPath,
      queryParameters: {'query': query},
    );
    final data = response.data ?? <String, dynamic>{};
    final results = <SearchResult>[];
    for (final entry in data.entries) {
      final category = _categoryFromString(entry.key);
      final items = entry.value as List<dynamic>? ?? [];
      results.addAll(
        items
            .whereType<Map<String, dynamic>>()
            .map((json) => SearchResult(
                  id: json['id']?.toString() ?? '',
                  title: json['title'] as String? ?? json['name'] as String? ?? '',
                  subtitle: json['subtitle'] as String? ?? json['summary'] as String? ?? '',
                  type: _typeFromString(json['type'] as String? ?? entry.key),
                  category: category,
                )),
      );
    }
    return results;
  }

  SearchCategory _categoryFromString(String value) {
    switch (value) {
      case 'people':
        return SearchCategory.people;
      case 'conversations':
        return SearchCategory.conversations;
      case 'posts':
      default:
        return SearchCategory.posts;
    }
  }

  SearchResultType _typeFromString(String value) {
    switch (value) {
      case 'user':
        return SearchResultType.user;
      case 'conversation':
        return SearchResultType.conversation;
      case 'post':
      default:
        return SearchResultType.post;
    }
  }
}
