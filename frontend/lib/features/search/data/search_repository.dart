import '../domain/search_result.dart';

abstract class SearchRepository {
  Future<List<SearchResult>> globalSearch(String query);
}
