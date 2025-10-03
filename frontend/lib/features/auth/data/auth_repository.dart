import '../../profiles/domain/user.dart';
import '../domain/auth_state.dart';

abstract class AuthRepository {
  Future<AuthState> bootstrap();
  Future<AuthState> login({required String email, required String password});
  Future<void> logout();
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String department,
  });
  Future<AuthState> refresh();
}
