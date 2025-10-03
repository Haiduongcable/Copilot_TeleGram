import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/app_avatar.dart';
import '../domain/directory_controller.dart';
import '../domain/directory_state.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  static const routePath = '/home/directory';
  static const routeName = 'directory';

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();
  final _departments = const ['Engineering', 'Design', 'Operations'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directoryControllerProvider);
    final controller = ref.read(directoryControllerProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search by name, username, email…',
                filled: true,
                fillColor: colors.surfaceVariant.withOpacity(0.35),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: controller.search,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.filter.department == null,
                  onSelected: (_) => controller.filterByDepartment(null),
                ),
                const SizedBox(width: 12),
                ..._departments.map(
                  (department) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(department),
                      selected: state.filter.department == department,
                      onSelected: (_) => controller.filterByDepartment(department),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Online'),
                  selected: state.filter.onlyOnline,
                  onSelected: controller.toggleOnline,
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Admins'),
                  selected: state.filter.onlyAdmins,
                  onSelected: controller.toggleAdmins,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = state.filtered[index];
                      final isOnline = user.lastSeen != null &&
                          DateTime.now().difference(user.lastSeen!).inMinutes < 5;
                      return ListTile(
                        leading: AppAvatar(
                          initials: user.name,
                          radius: 22,
                          statusColor: isOnline ? colors.primary : colors.outlineVariant,
                        ),
                        title: Text(user.name),
                        subtitle: Text('${user.role ?? 'Member'} • ${user.department ?? 'General'}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: isOnline ? colors.primary : colors.outline,
                            ),
                            const SizedBox(height: 4),
                            Text(user.email, style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        onTap: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
