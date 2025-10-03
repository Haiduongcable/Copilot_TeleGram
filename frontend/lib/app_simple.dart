import 'package:flutter/material.dart';

class AppSimple extends StatelessWidget {
  const AppSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleGram Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Flutter Web is Working!', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
