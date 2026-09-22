import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Практика')),
      body: const EmptyState(
        message: 'Диктант и практика в предложениях появятся здесь в следующих фазах.',
      ),
    );
  }
}
