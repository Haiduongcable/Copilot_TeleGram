import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../flavors/flavor_config.dart';
import '../../profiles/domain/user.dart';
import '../data/directory_repository.dart';
import '../data/mock_directory_repository.dart';
import '../data/rest_directory_repository.dart';
import 'directory_state.dart';

final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) {
  final config = FlavorConfig.instance;
  if (config.isFeatureEnabled('useMockData')) {
    return const MockDirectoryRepository();
  }
  final dio = ref.watch(dioProvider);
  return RestDirectoryRepository(dio);
});

final directoryControllerProvider = StateNotifierProvider<DirectoryController, DirectoryState>((ref) {
  final repository = ref.watch(directoryRepositoryProvider);
  return DirectoryController(repository);
});

class DirectoryController extends StateNotifier<DirectoryState> {
  DirectoryController(this._repository) : super(const DirectoryState()) {
    loadUsers();
  }

  final DirectoryRepository _repository;

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.fetchUsers();
      state = state.copyWith(
        isLoading: false,
        users: users,
        filtered: _applyFilter(filter: state.filter, users: users),
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> search(String query) async {
    final filter = state.filter.copyWith(query: query);
    state = state.copyWith(filter: filter);

    try {
      final users = await _repository.fetchUsers(query: query.isEmpty ? null : query);
      state = state.copyWith(
        users: query.isEmpty ? state.users : users,
        filtered: _applyFilter(filter: filter, users: query.isEmpty ? state.users : users),
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  void filterByDepartment(String? department) {
    final filter = state.filter.copyWith(department: department);
    state = state.copyWith(
      filter: filter,
      filtered: _applyFilter(filter: filter, users: state.users),
    );
  }

  void toggleAdmins(bool value) {
    final filter = state.filter.copyWith(onlyAdmins: value);
    state = state.copyWith(
      filter: filter,
      filtered: _applyFilter(filter: filter, users: state.users),
    );
  }

  void toggleOnline(bool value) {
    final filter = state.filter.copyWith(onlyOnline: value);
    state = state.copyWith(
      filter: filter,
      filtered: _applyFilter(filter: filter, users: state.users),
    );
  }

  List<User> _applyFilter({required DirectoryFilter filter, required List<User> users}) {
    return users.where((user) {
      final matcher = filter.query.toLowerCase();
      final matchesQuery = filter.query.isEmpty ||
          user.name.toLowerCase().contains(matcher) ||
          user.username.toLowerCase().contains(matcher) ||
          user.email.toLowerCase().contains(matcher);
      final matchesDepartment = filter.department == null || filter.department == user.department;
      final matchesAdmins = !filter.onlyAdmins || user.isAdmin;
      final matchesOnline = !filter.onlyOnline ||
          (user.lastSeen != null && DateTime.now().difference(user.lastSeen!).inMinutes < 5);
      return matchesQuery && matchesDepartment && matchesAdmins && matchesOnline;
    }).toList(growable: false);
  }
}
