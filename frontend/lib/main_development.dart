import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'app_minimal.dart';
import 'app_simple.dart';
import 'bootstrap/bootstrap.dart';
import 'flavors/flavor.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  final config = FlavorConfig(
    flavor: Flavor.development,
    apiEndpoints: const ApiEndpoints(
      baseUrl: 'http://localhost:8000/api',
      auth: '/auth',
      feed: '/posts',
      messaging: '/messaging/chats',
      notifications: '/notifications',
      admin: '/admin',
      search: '/search',
      storage: '/files',
      directory: '/users',
    ),
    wsEndpoints: const WebSocketEndpoints(
      baseUrl: 'ws://localhost:8000',
      messaging: '/ws/chat',
      presence: '/ws/presence',
      notifications: '/ws/notifications',
    ),
    featureFlags: const {
      'stories': false,
      'voiceMessages': false,
      'adminAnalytics': true,
      'useMockData': false,
    },
  );

  await bootstrap(
    configuration: config,
    builder: () async {
      // Full app with Riverpod
      debugPrint('Builder: Creating ProviderScope with App...');
      return const ProviderScope(child: App());
    },
  );
}
