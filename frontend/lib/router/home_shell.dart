import 'package:flutter/material.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.currentIndex,
    required this.onNavigate,
    required this.child,
    super.key,
  });

  final int currentIndex;
  final void Function(int index) onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onNavigate,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Directory'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.notifications_none_rounded), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
