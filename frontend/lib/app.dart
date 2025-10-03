import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('App.build: START');
    
    try {
      debugPrint('App.build: Getting router...');
      final router = ref.watch(appRouterProvider);
      debugPrint('App.build: Router obtained');
      
      debugPrint('App.build: Getting theme...');
      final themeMode = ref.watch(themeControllerProvider);
      debugPrint('App.build: Theme obtained: $themeMode');
      
      debugPrint('App.build: Creating MaterialApp...');
      return MaterialApp.router(
        title: 'TeleGram Internal Network',
        themeMode: themeMode,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
        supportedLocales: L10n.supportedLocales,
        localizationsDelegates: L10n.localizationsDelegates,
        debugShowCheckedModeBanner: false,
      );
    } catch (e, stack) {
      debugPrint('App.build ERROR: $e');
      debugPrint('STACK: $stack');
      rethrow;
    }
  }
}
