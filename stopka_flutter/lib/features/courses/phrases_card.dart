import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/phrases/phrase_set_builder.dart';
import '../../core/providers/core_providers.dart';
import '../../core/text/russian_plural.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/app_card.dart';
import '../../domain/models/unit.dart';
import '../../domain/models/word_set.dart';
import '../dictation/dictation_setup_screen.dart';

/// The unit's phrases: an invitation to build them from the words' examples,
/// or the set itself, which opens the same dictation as words (RU / EN, EN /
/// RU, by ear).
class PhrasesCard extends ConsumerStatefulWidget {
  final Unit unit;

  const PhrasesCard({super.key, required this.unit});

  @override
  ConsumerState<PhrasesCard> createState() => _PhrasesCardState();
}

class _PhrasesCardState extends ConsumerState<PhrasesCard> {
  bool _building = false;

  String get _title => 'Фразы · ${widget.unit.code}';

  Future<void> _build() async {
    if (_building) return;
    setState(() => _building = true);
    final messenger = ScaffoldMessenger.of(context);
    final unit = widget.unit;
    final enrichment = ref.read(cardEnrichmentServiceProvider);
    final level = ref.read(currentProfileProvider).value?.level ?? '';
    final ai = await ref.read(aiAvailabilityProvider).isAvailable();

    final result = await PhraseSetBuilder(
      sets: ref.read(wordSetRepositoryProvider),
      cards: ref.read(wordCardRepositoryProvider),
      enrich: ai
          ? (terms) => enrichment.enrich(
              terms: terms,
              level: level,
              grammarTopic: unit.grammarTopic,
              vocabTopic: unit.vocabTopic,
            )
          : null,
    ).build(unitId: unit.id, title: _title);

    if (!mounted) return;
    setState(() => _building = false);
    messenger.showSnackBar(SnackBar(content: Text(_message(result, ai: ai))));
  }

  static String _message(PhraseSetResult r, {required bool ai}) {
    final parts = <String>[];
    if (r.added > 0) {
      parts.add('Добавлено ${r.added} ${pluralRu(r.added, one: 'фраза', few: 'фразы', many: 'фраз')}.');
    }
    if (r.withoutExamples > 0) {
      final words = pluralRu(r.withoutExamples, one: 'слова', few: 'слов', many: 'слов');
      final why = r.error ?? (ai ? 'ИИ не вернул примеры.' : 'Примеры добавит ИИ, когда сервер будет доступен.');
      parts.add('У ${r.withoutExamples} $words нет примеров с переводом. $why');
    }
    return parts.isEmpty ? 'Новых фраз нет: у всех слов фразы уже есть.' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sets = ref.watch(wordSetRepositoryProvider).watchWordSets(unitId: widget.unit.id);
    return StreamBuilder<List<WordSet>>(
      stream: sets,
      builder: (context, snapshot) {
        final phraseSet = (snapshot.data ?? const []).where((s) => s.source == WordSetSource.phrases).firstOrNull;
        if (phraseSet == null) {
          return AppCard(
            dashed: true,
            onTap: _building ? null : _build,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Фразы из примеров — слова юнита в предложениях',
                    style: AppTypography.caption.copyWith(color: colors.muted),
                  ),
                ),
                const SizedBox(width: AppSpacing.s14),
                _trailing(colors, Icons.add),
              ],
            ),
          );
        }

        return StreamBuilder(
          stream: ref.watch(wordCardRepositoryProvider).watchCards(phraseSet.id),
          builder: (context, cards) {
            final count = cards.data?.length ?? 0;
            return AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DictationSetupScreen(setId: phraseSet.id, setTitle: phraseSet.title)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Фразы юнита', style: AppTypography.heading.copyWith(color: colors.ink)),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          '$count ${pluralRu(count, one: 'фраза', few: 'фразы', many: 'фраз')} · диктант и на слух',
                          style: AppTypography.caption.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Добавить фразы для новых слов',
                    icon: _building
                        ? const SizedBox(
                            width: AppSpacing.s18,
                            height: AppSpacing.s18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    color: colors.muted,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    onPressed: _building ? null : _build,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _trailing(AppColorTokens colors, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.iconButton),
        border: Border.all(color: colors.lineStrong),
      ),
      child: _building
          ? const Padding(padding: EdgeInsets.all(AppSpacing.s14), child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: colors.ink),
    );
  }
}
