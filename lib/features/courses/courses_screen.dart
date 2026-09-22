import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Курсы')),
      body: const Center(
        child: Text('Создание курсов и юнитов появится в фазе 1.'),
      ),
    );
  }
}
