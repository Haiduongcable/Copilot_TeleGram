import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routePath = '/home/settings';
  static const routeName = 'settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle theme between light and dark'),
            value: mode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeControllerProvider.notifier).toggleDarkMode(),
          ),
          const Divider(),
          const ListTile(
            title: Text('Account'),
            subtitle: Text('Manage profile, password, and sessions'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Notifications'),
            subtitle: Text('Push, email, and in-app preferences'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('Storage & Media'),
            subtitle: Text('Cache usage, downloads, and uploads'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            title: Text('About'),
            subtitle: Text('Version, licenses, diagnostics'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
