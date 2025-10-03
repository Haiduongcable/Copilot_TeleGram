import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/search_controller.dart';
import '../domain/search_result.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const routePath = '/search';
  static const routeName = 'search';

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(globalSearchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users, posts, or conversations…',
            border: InputBorder.none,
          ),
          onChanged: ref.read(globalSearchControllerProvider.notifier).search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              ref.read(globalSearchControllerProvider.notifier).search('');
            },
          ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Search failed: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Start typing to search.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final result = items[index];
              return _SearchResultTile(result: result);
            },
          );
        },
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result});

  final SearchResult result;

  IconData _iconForResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.user:
        return Icons.person_outline;
      case SearchResultType.post:
        return Icons.article_outlined;
      case SearchResultType.conversation:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.surfaceVariant,
          child: Icon(_iconForResult(result)),
        ),
        title: Text(result.title),
        subtitle: Text(result.subtitle),
        trailing: Text(result.category.name.toUpperCase()),
        onTap: () {},
      ),
    );
  }
}
