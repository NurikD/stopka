import 'package:flutter/material.dart';

class MistakesScreen extends StatelessWidget {
  const MistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибки')),
      body: const Center(
        child: Text('Статистика ошибок появится в фазе 5.'),
      ),
    );
  }
}
