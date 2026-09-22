import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class MistakesScreen extends StatelessWidget {
  const MistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибки')),
      body: const EmptyState(
        message: 'Как только пройдёте первые упражнения, здесь появится статистика по ошибкам.',
      ),
    );
  }
}
