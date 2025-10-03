import 'package:flutter/foundation.dart';

import 'flavor.dart';

typedef FeatureFlags = Map<String, bool>;

class FlavorConfig {
  FlavorConfig({
    required this.flavor,
    required this.apiEndpoints,
    required this.wsEndpoints,
    FeatureFlags? featureFlags,
  }) : featureFlags = featureFlags ?? <String, bool>{};

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('FlavorConfig has not been initialized.');
    }
    return config;
  }

  final Flavor flavor;
  final ApiEndpoints apiEndpoints;
  final WebSocketEndpoints wsEndpoints;
  final FeatureFlags featureFlags;

  static void init(FlavorConfig configuration) {
    debugPrint('FlavorConfig.init: START');
    _instance = configuration;
    debugPrint('FlavorConfig.init: Instance set');
    if (kDebugMode) {
      debugPrint('Flavor initialized: ${configuration.flavor}');
    }
    debugPrint('FlavorConfig.init: END');
  }

  bool isFeatureEnabled(String key) => featureFlags[key] ?? false;
}

class ApiEndpoints {
  const ApiEndpoints({
    required this.baseUrl,
    required this.auth,
    required this.feed,
    required this.messaging,
    required this.notifications,
    required this.admin,
    required this.search,
    required this.storage,
    required this.directory,
  });

  final String baseUrl;
  final String auth;
  final String feed;
  final String messaging;
  final String notifications;
  final String admin;
  final String search;
  final String storage;
  final String directory;
}

class WebSocketEndpoints {
  const WebSocketEndpoints({
    required this.baseUrl,
    required this.messaging,
    required this.presence,
    required this.notifications,
  });

  final String baseUrl;
  final String messaging;
  final String presence;
  final String notifications;
}
