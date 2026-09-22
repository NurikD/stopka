import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Курсы')),
      body: const EmptyState(
        message: 'Создание курсов и юнитов появится в фазе 1.',
      ),
    );
  }
}
