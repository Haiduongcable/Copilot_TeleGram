import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'flavors/flavor.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  final config = FlavorConfig(
    flavor: Flavor.staging,
    apiEndpoints: const ApiEndpoints(
      baseUrl: 'https://staging.api.telegramapp.local',
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
      baseUrl: 'wss://staging.api.telegramapp.local',
      messaging: '/ws/messages',
      presence: '/ws/presence',
      notifications: '/ws/notifications',
    ),
    featureFlags: const {
      'stories': true,
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
