# TeleGramApp Frontend

Flutter mobile client for the internal team social network. The app targets Flutter 3.22+ and Dart 3.3+, supports Android and iOS, and follows a feature-first project layout.

## Project Layout

```
lib/
  app.dart                 # MaterialApp.router setup
  bootstrap/               # Environment bootstrap + logging
  core/                    # Shared constants, networking, storage
  features/
    auth/                  # Authentication flow (data/domain/presentation)
    feed/                  # Home feed and post interactions
    directory/             # Member directory and profile lookup
    messaging/             # Conversations, messages, WebSocket glue
    notifications/         # In-app notification center
    onboarding/            # Profile completion and splash handling
    posts/                 # Post details, composer helpers
    search/                # Global search UX
    settings/              # Preferences, theme, account controls
  router/                  # GoRouter config + shells
  services/                # Flavors, connectivity, analytics facades
  theme/                   # Color schemes, theme controller
  widgets/                 # Reusable UI primitives (avatars, badges, empty states)
assets/                    # Icons, images, translations placeholders
test/                      # Unit/widget tests (Riverpod controllers, etc.)
```

## Getting Started

```bash
flutter pub get
flutter run -t lib/main_development.dart
```

Use `lib/main_staging.dart` or `lib/main_production.dart` for alternate flavors. `lib/main.dart` defaults to the development flavor.

## Key Packages

- `flutter_riverpod` for state management with ProviderScope overrides per flavor.
- `go_router` for declarative navigation and deep links.
- `dio` + interceptors for HTTP + retry, `web_socket_channel` for live messaging.
- `isar`/`hive` placeholders for offline caching (to be wired to real datasources).
- `cached_network_image`, `image_picker`, `file_picker` for media workflows.

## Running Tests & Lint

```bash
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
```

## Notes

- API endpoints and WebSocket paths are supplied via `FlavorConfig`; override `authRepositoryProvider`, `feedRepositoryProvider`, etc., at the app root for real integrations.
- Mock repositories back the demo experience so the UI is fully navigable without a backend.
- Shared widgets (`lib/widgets`) provide consistent avatars, badges, offline banners, and async-state handling across features.

