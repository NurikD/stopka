import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сегодня')),
      body: const EmptyState(
        message: 'Сначала добавьте курс и слова — тогда здесь появится то, что нужно повторить сегодня.',
      ),
    );
  }
}
