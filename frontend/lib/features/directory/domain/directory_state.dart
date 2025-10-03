import 'package:equatable/equatable.dart';

import '../../profiles/domain/user.dart';

enum DirectoryFilterType { all, department, online, admins }

class DirectoryFilter extends Equatable {
  const DirectoryFilter({
    this.query = '',
    this.department,
    this.onlyOnline = false,
    this.onlyAdmins = false,
  });

  final String query;
  final String? department;
  final bool onlyOnline;
  final bool onlyAdmins;

  DirectoryFilter copyWith({
    String? query,
    String? department,
    bool? onlyOnline,
    bool? onlyAdmins,
  }) {
    return DirectoryFilter(
      query: query ?? this.query,
      department: department ?? this.department,
      onlyOnline: onlyOnline ?? this.onlyOnline,
      onlyAdmins: onlyAdmins ?? this.onlyAdmins,
    );
  }

  @override
  List<Object?> get props => [query, department, onlyOnline, onlyAdmins];
}

class DirectoryState extends Equatable {
  const DirectoryState({
    this.isLoading = false,
    this.error,
    this.users = const [],
    this.filtered = const [],
    this.filter = const DirectoryFilter(),
  });

  final bool isLoading;
  final String? error;
  final List<User> users;
  final List<User> filtered;
  final DirectoryFilter filter;

  DirectoryState copyWith({
    bool? isLoading,
    String? error,
    List<User>? users,
    List<User>? filtered,
    DirectoryFilter? filter,
  }) {
    return DirectoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      users: users ?? this.users,
      filtered: filtered ?? this.filtered,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [isLoading, error, users, filtered, filter];
}
