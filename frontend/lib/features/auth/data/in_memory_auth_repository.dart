import 'package:uuid/uuid.dart';

import '../../profiles/domain/user.dart';
import '../domain/auth_state.dart';
import 'auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository();

  User? _currentUser;
  final _uuid = const Uuid();

  @override
  Future<AuthState> bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_currentUser == null) {
      return AuthState.unauthenticated();
    }
    return AuthState.authenticated(_currentUser!);
  }

  @override
  Future<AuthState> login({required String email, required String password}) async {
    _currentUser = User(
      id: _uuid.v4(),
      email: email,
      name: 'Sample User',
      username: email.split('@').first,
      department: 'Engineering',
      role: 'Developer',
      statusMessage: 'Online',
      lastSeen: DateTime.now(),
      isAdmin: true,
    );
    return AuthState.authenticated(_currentUser!);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    _currentUser = User(
      id: _uuid.v4(),
      email: email,
      name: name,
      username: name.toLowerCase().replaceAll(' ', '.'),
      department: department,
      role: 'Contributor',
      statusMessage: 'Setting up profile…',
      lastSeen: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<AuthState> refresh() async {
    if (_currentUser == null) {
      return AuthState.unauthenticated();
    }
    return AuthState.authenticated(_currentUser!);
  }
}
