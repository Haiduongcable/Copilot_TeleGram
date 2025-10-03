import '../../profiles/domain/user.dart';

enum AuthStatus { unknown, unauthenticated, onboarding, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);
  factory AuthState.unauthenticated() => const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.onboarding(User user) => AuthState(status: AuthStatus.onboarding, user: user);
  factory AuthState.authenticated(User user) => AuthState(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isOnboarding => status == AuthStatus.onboarding;
  bool get isUnknown => status == AuthStatus.unknown;
}
