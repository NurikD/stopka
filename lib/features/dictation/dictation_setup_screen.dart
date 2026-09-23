import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/dictation_session.dart';
import 'dictation_session_screen.dart';

/// Direction, stack size, and streak all live here rather than as global
/// settings — DESIGN.md's dictation screens assume you decide this right
/// before you start, not in a settings menu.
class DictationSetupScreen extends ConsumerStatefulWidget {
  final String setId;
  final String setTitle;

  const DictationSetupScreen({super.key, required this.setId, required this.setTitle});

  @override
  ConsumerState<DictationSetupScreen> createState() => _DictationSetupScreenState();
}

class _DictationSetupScreenState extends ConsumerState<DictationSetupScreen> {
  DictationDirection _direction = DictationDirection.ruEn;
  int _stackSize = 12;
  int _requiredStreak = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Диктант · ${widget.setTitle}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Направление', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<DictationDirection>(
            segments: const [
              ButtonSegment(value: DictationDirection.ruEn, label: Text('RU → EN')),
              ButtonSegment(value: DictationDirection.enRu, label: Text('EN → RU')),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() => _direction = s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Размер стопки', style: Theme.of(context).textTheme.titleLarge),
          Slider(
            value: _stackSize.toDouble(),
            min: 5,
            max: 20,
            divisions: 15,
            label: '$_stackSize',
            onChanged: (v) => setState(() => _stackSize = v.round()),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Верных подряд для освоения слова', style: Theme.of(context).textTheme.titleLarge),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
            ],
            selected: {_requiredStreak},
            onSelectionChanged: (s) => setState(() => _requiredStreak = s.first),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: 'Начать диктант',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DictationSessionScreen(
                  setId: widget.setId,
                  direction: _direction,
                  stackSize: _stackSize,
                  requiredStreak: _requiredStreak,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
