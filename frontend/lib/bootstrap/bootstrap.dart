import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../core/logging/logger_provider.dart';
import '../flavors/flavor_config.dart';

Future<void> bootstrap({
  required FlavorConfig configuration,
  required FutureOr<Widget> Function() builder,
}) async {
  try {
    // Configure logging first (before ensureInitialized)
    _configureLogging();
    
    debugPrint('Bootstrap: Step 1 - ensureInitialized');
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('Bootstrap: Step 2 - FlavorConfig.init');
    // Initialize flavor configuration
    FlavorConfig.init(configuration);

    debugPrint('Bootstrap: Step 3 - Error handler');
    // Set up error handler
    FlutterError.onError = (details) {
      debugPrint('FLUTTER ERROR: ${details.exceptionAsString()}');
      Logger('FlutterError').severe(details.exceptionAsString(), details.exception, details.stack);
    };

    debugPrint('Bootstrap: Step 4 - Calling builder...');
    // Build and run the app
    final widgetFuture = builder();
    debugPrint('Bootstrap: Step 4b - Builder called, awaiting widget...');
    
    final widget = await widgetFuture;
    debugPrint('Bootstrap: Step 4c - Widget received: ${widget.runtimeType}');
    
    debugPrint('Bootstrap: Step 5 - Calling runApp...');
    runApp(widget);
    debugPrint('Bootstrap: Step 5b - runApp returned');
    
    debugPrint('Bootstrap: Step 6 - COMPLETE!');
  } catch (error, stackTrace) {
    debugPrint('BOOTSTRAP ERROR: $error');
    debugPrint('STACKTRACE: $stackTrace');
    Logger('BootstrapError').severe('Bootstrap failed', error, stackTrace);
  }
}

void _configureLogging() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('[\\${record.level.name}] \\${record.loggerName}: \\${record.time.toIso8601String()} - \\${record.message}');
    if (record.error != null) {
      debugPrint('Error: \\${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stacktrace: \\${record.stackTrace}');
    }
  });
}
