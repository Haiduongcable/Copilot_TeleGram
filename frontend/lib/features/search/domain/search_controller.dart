import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../flavors/flavor_config.dart';
import '../data/mock_search_repository.dart';
import '../data/rest_search_repository.dart';
import '../data/search_repository.dart';
import 'search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final config = FlavorConfig.instance;
  if (config.isFeatureEnabled('useMockData')) {
    return MockSearchRepository();
  }
  final dio = ref.watch(dioProvider);
  return RestSearchRepository(dio);
});

final globalSearchControllerProvider = StateNotifierProvider<GlobalSearchController, AsyncValue<List<SearchResult>>>(
  (ref) {
    final repository = ref.watch(searchRepositoryProvider);
    return GlobalSearchController(repository);
  },
);

class GlobalSearchController extends StateNotifier<AsyncValue<List<SearchResult>>> {
  GlobalSearchController(this._repository) : super(const AsyncValue.data([]));

  final SearchRepository _repository;
  Timer? _debounce;

  void search(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncValue.loading();
      try {
        final results = await _repository.globalSearch(query);
        state = AsyncValue.data(results);
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
