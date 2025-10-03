import 'package:flutter/material.dart';

class AppMinimal extends StatelessWidget {
  const AppMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('=== AppMinimal.build() CALLED! ===');
    
    return MaterialApp(
      title: 'Minimal Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IT WORKS!'),
        ),
        body: const Center(
          child: Text(
            'Hello Flutter Web!',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
