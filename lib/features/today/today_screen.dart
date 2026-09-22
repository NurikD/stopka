import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сегодня')),
      body: const Center(
        child: Text('Повторение появится в следующих фазах.'),
      ),
    );
  }
}
