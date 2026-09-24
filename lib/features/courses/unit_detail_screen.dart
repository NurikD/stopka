import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ghost_button.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/unit.dart';
import '../../domain/models/word_card.dart';
import '../../domain/models/word_set.dart';
import '../dictation/dictation_setup_screen.dart';
import 'add_words/add_words_screen.dart';
import 'card_form_sheet.dart';

class UnitDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String unitId;

  const UnitDetailScreen({super.key, required this.courseId, required this.unitId});

  @override
  ConsumerState<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends ConsumerState<UnitDetailScreen> {
  String? _setId;
  Unit? _unit;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final unit = await ref.read(unitRepositoryProvider).getUnit(widget.unitId);
    final sets = await ref.read(wordSetRepositoryProvider).watchWordSets(unitId: widget.unitId).first;
    String setId;
    if (sets.isNotEmpty) {
      setId = sets.first.id;
    } else {
      final created = await ref.read(wordSetRepositoryProvider).createWordSet(
            unitId: widget.unitId,
            title: unit?.code ?? 'Слова юнита',
            source: WordSetSource.manual,
          );
      setId = created.id;
    }
    if (!mounted) return;
    setState(() {
      _unit = unit;
      _setId = setId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final setId = _setId;
    final unit = _unit;

    if (setId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(unit == null ? 'Юнит' : '${unit.code} · ${unit.title}'.trim())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<WordCard>>(
      stream: ref.watch(wordCardRepositoryProvider).watchCards(setId),
      builder: (context, snapshot) {
        final allCards = snapshot.data ?? const [];
        final cards = _query.isEmpty
            ? allCards
            : allCards
                .where((c) =>
                    c.term.toLowerCase().contains(_query.toLowerCase()) ||
                    c.translation.toLowerCase().contains(_query.toLowerCase()))
                .toList();

        return Scaffold(
          appBar: AppBar(title: Text(unit == null ? 'Юнит' : '${unit.code} · ${unit.title}'.trim())),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : allCards.isEmpty
                  ? EmptyState(
                      message: 'Сфоткайте список слов с урока — разберу и переведу. '
                          'Или добавьте слова вручную/вставкой.',
                      actionLabel: 'Добавить слова',
                      onAction: () => _openAddWords(context, setId, unit),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.s14, AppSpacing.s10, AppSpacing.s14, 0),
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Поиск по слову или переводу',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _query = v),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.s14),
                            itemCount: cards.length,
                            itemBuilder: (context, i) => _CardTile(card: cards[i]),
                          ),
                        ),
                      ],
                    ),
          bottomNavigationBar: StickyActionBar(
            children: [
              if (allCards.isNotEmpty)
                GhostButton(
                  label: 'Диктант',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DictationSetupScreen(setId: setId, setTitle: unit?.code ?? 'слова'),
                    ),
                  ),
                ),
              PrimaryButton(
                label: 'Добавить слова',
                onPressed: () => _openAddWords(context, setId, unit),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAddWords(BuildContext context, String setId, Unit? unit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddWordsScreen(
          setId: setId,
          level: '', // course level isn't loaded on this screen; enrichment still works without it
          grammarTopic: unit?.grammarTopic ?? '',
          vocabTopic: unit?.vocabTopic ?? '',
        ),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  final WordCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14),
        margin: const EdgeInsets.only(bottom: AppSpacing.s10),
        decoration: BoxDecoration(
          color: colors.danger,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(wordCardRepositoryProvider).deleteCard(card.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => showCardFormSheet(context, ref, card: card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            card.term,
                            style: AppTypography.heading.copyWith(
                              fontFamily: 'Literata',
                              color: colors.ink,
                            ),
                          ),
                          if (card.transcription.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.s8),
                            Text(
                              card.transcription,
                              style: AppTypography.transcription.copyWith(color: colors.muted),
                            ),
                          ],
                        ],
                      ),
                      if (card.translation.isNotEmpty)
                        Text(
                          card.translation,
                          style: AppTypography.bodyText.copyWith(color: colors.muted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_outlined),
                  color: colors.muted,
                  onPressed: () => ref.read(ttsServiceProvider).speak(card.term),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
