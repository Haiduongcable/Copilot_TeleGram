import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telegram_app_frontend/features/auth/data/in_memory_auth_repository.dart';
import 'package:telegram_app_frontend/features/auth/domain/auth_controller.dart';
import 'package:telegram_app_frontend/features/auth/domain/auth_state.dart';

void main() {
  group('AuthController', () {
    test('login updates state to authenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.login((email: 'member@example.com', password: 'password123'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.email, 'member@example.com');
    });

    test('logout resets to unauthenticated', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.login((email: 'member@example.com', password: 'password123'));
      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });
  });
}
