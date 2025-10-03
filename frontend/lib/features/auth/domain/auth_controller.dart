import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../profiles/domain/user.dart';
import '../data/auth_repository.dart';
import '../data/rest_auth_repository.dart';
import 'auth_state.dart';

typedef Credentials = ({String email, String password});

typedef RegistrationData = ({
  String name,
  String email,
  String password,
  String department,
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokens = ref.watch(tokenStorageProvider);
  return RestAuthRepository(dio: dio, tokenStorage: tokens);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.unknown());

  final AuthRepository _repository;
  bool _hasBootstrapped = false;

  Future<void> bootstrap() async {
    if (_hasBootstrapped) {
      debugPrint('AuthController.bootstrap: Already bootstrapped, skipping');
      return;
    }
    _hasBootstrapped = true;
    
    debugPrint('AuthController.bootstrap: START');
    try {
      final newState = await _repository.bootstrap();
      debugPrint('AuthController.bootstrap: Got state: ${newState.status}');
      state = newState;
      debugPrint('AuthController.bootstrap: State updated to: ${state.status}');
    } catch (e, stackTrace) {
      debugPrint('AuthController.bootstrap: ERROR: $e');
      debugPrint('AuthController.bootstrap: STACK: $stackTrace');
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(Credentials credentials) async {
    state = await _repository.login(
      email: credentials.email,
      password: credentials.password,
    );
  }

  Future<void> register(RegistrationData data) async {
    final user = await _repository.register(
      name: data.name,
      email: data.email,
      password: data.password,
      department: data.department,
    );
    state = AuthState.onboarding(user);
  }

  Future<void> refresh() async {
    state = await _repository.refresh();
  }

  Future<void> completeOnboarding(User user) async {
    state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState.unauthenticated();
  }
}
