# Frontend Loading Issue - Analysis & Fix

## Problem
The Flutter web frontend gets stuck on a loading screen and never displays any content.

## Root Causes

### 1. FlutterSecureStorage on Web (? FIXED)
- **Issue**: `FlutterSecureStorage` doesn't work reliably on web browsers
- **Symptom**: The `bootstrap()` method was hanging when trying to read tokens
- **Fix**: Modified `token_storage.dart` to use `InMemoryTokenStorage` for web:
```dart
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  if (kIsWeb) {
    return InMemoryTokenStorage();
  }
  return SecureTokenStorage();
});
```

### 2. Infinite Rebuild Loop (? NEEDS FIX)
- **Issue**: The splash screen calls `bootstrap()` in `addPostFrameCallback`, causing infinite rebuilds
- **Flow**:
  1. Splash screen mounts Å® calls `bootstrap()`
  2. Bootstrap updates auth state to `unauthenticated`
  3. Router's `refreshListenable` detects state change Å® triggers rebuild
  4. Splash screen remounts Å® calls `bootstrap()` again
  5. Loop continues indefinitely

- **Evidence from logs**:
  ```
  [LOG] SplashScreen.initState: START
  [LOG] SplashScreen: Calling authController.bootstrap()
  [LOG] AuthController.bootstrap: START
  [LOG] RestAuthRepository.bootstrap: START
  [LOG] RestAuthRepository.bootstrap: Token = NULL
  [LOG] RestAuthRepository.bootstrap: No token, returning unauthenticated
  [LOG] AuthController.bootstrap: Got state: AuthStatus.unauthenticated
  [LOG] AuthController.bootstrap: State updated to: AuthStatus.unauthenticated
  // Router rebuilds...
  [LOG] SplashScreen.initState: START  Å© Called again!
  [LOG] SplashScreen: Calling authController.bootstrap()
  // Infinite loop continues...
  ```

## Recommended Fixes

### Option 1: Call Bootstrap Once (Recommended)
Move the bootstrap call to app initialization instead of splash screen:

**File**: `frontend/lib/main_development.dart`
```dart
Future<void> main() async {
  final config = FlavorConfig(/* ... */);

  await bootstrap(
    configuration: config,
    builder: () async {
      // Initialize providers
      final container = ProviderContainer();
      
      // Call bootstrap ONCE before the app starts
      await container.read(authControllerProvider.notifier).bootstrap();
      
      return UncontrolledProviderScope(
        container: container,
        child: const App(),
      );
    },
  );
}
```

**File**: `frontend/lib/features/onboarding/presentation/splash_screen.dart`
```dart
// Remove the bootstrap call from initState
@override
void initState() {
  super.initState();
  debugPrint('SplashScreen.initState: START');
  // REMOVE THIS:
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   debugPrint('SplashScreen: Calling authController.bootstrap()');
  //   ref.read(authControllerProvider.notifier).bootstrap();
  // });
}
```

### Option 2: Add Bootstrap Guard
Prevent multiple bootstrap calls by tracking if it's already been called:

**File**: `frontend/lib/features/auth/domain/auth_controller.dart`
```dart
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(AuthState.unknown());

  final AuthRepository _repository;
  bool _hasBootstrapped = false;  // Add this flag

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
  
  // Rest of the code...
}
```

## Testing the Fix

1. Apply one of the recommended fixes above
2. Restart the Flutter web server:
   ```bash
   cd frontend
   flutter run -d web-server --web-port=8080
   ```
3. Navigate to `http://localhost:8080`
4. Expected behavior:
   - Splash screen shows briefly
   - App redirects to `/auth` (login screen)
   - No infinite loading

## Files Modified

1. ? `frontend/lib/core/storage/token_storage.dart` - Use InMemoryTokenStorage for web
2. ? `frontend/lib/features/auth/data/rest_auth_repository.dart` - Added debug logging
3. ? `frontend/lib/features/auth/domain/auth_controller.dart` - Added debug logging
4. ? `frontend/lib/features/onboarding/presentation/splash_screen.dart` - NEEDS FIX (remove bootstrap call)
5. ? `frontend/lib/main_development.dart` - NEEDS FIX (call bootstrap once)

## Additional Notes

- The backend API at `http://localhost:8000` is running and accessible
- Network requests to the backend will only happen after the infinite loop is fixed
- The auth flow logic is correct, just needs to be triggered properly
