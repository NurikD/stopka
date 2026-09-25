import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/share/share_target_service.dart';
import '../../../core/widgets/app_header_bar.dart';
import 'add_words_screen.dart';

/// Where text shared from another app lands: finds (or makes) the unit to add
/// to, then opens the usual draft review with the text already parsed.
class SharedTextScreen extends ConsumerStatefulWidget {
  final String text;

  const SharedTextScreen({super.key, required this.text});

  @override
  ConsumerState<SharedTextScreen> createState() => _SharedTextScreenState();
}

class _SharedTextScreenState extends ConsumerState<SharedTextScreen> {
  late final Future<ShareTarget> _target;

  @override
  void initState() {
    super.initState();
    _target = ShareTargetService(
      courses: ref.read(courseRepositoryProvider),
      units: ref.read(unitRepositoryProvider),
      wordSets: ref.read(wordSetRepositoryProvider),
    ).resolve();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShareTarget>(
      future: _target,
      builder: (context, snapshot) {
        final target = snapshot.data;
        if (target == null) {
          return Scaffold(
            appBar: const AppHeaderBar(nested: true, title: 'Слова из другого приложения'),
            body: Center(
              child: snapshot.hasError
                  ? const Text('Не удалось подготовить набор слов.')
                  : const CircularProgressIndicator(),
            ),
          );
        }
        return AddWordsScreen(
          setId: target.setId,
          level: '',
          grammarTopic: target.unit.grammarTopic,
          vocabTopic: target.unit.vocabTopic,
          initialPaste: widget.text,
        );
      },
    );
  }
}
