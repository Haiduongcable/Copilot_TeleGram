import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'flavors/flavor.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  final config = FlavorConfig(
    flavor: Flavor.production,
    apiEndpoints: const ApiEndpoints(
      baseUrl: 'https://api.telegramapp.company',
      auth: '/auth',
      feed: '/feed',
      messaging: '/messaging',
      notifications: '/notifications',
      admin: '/admin',
      search: '/search',
      storage: '/storage',
      directory: '/directory',
    ),
    wsEndpoints: const WebSocketEndpoints(
      baseUrl: 'wss://api.telegramapp.company',
      messaging: '/ws/messages',
      presence: '/ws/presence',
      notifications: '/ws/notifications',
    ),
    featureFlags: const {
      'stories': false,
      'voiceMessages': true,
      'adminAnalytics': true,
      'useMockData': false,
    },
  );

  await bootstrap(
    configuration: config,
    builder: () async {
      return const ProviderScope(child: App());
    },
  );
}
