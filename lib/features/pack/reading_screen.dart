import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pack/pack_content.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/mark.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/models/word_set.dart';
import 'exercise_flow.dart';
import 'pack_context.dart';

final RegExp _wordPattern = RegExp("[A-Za-z]+(?:['’-][A-Za-z]+)*");

class ReadingScreen extends StatelessWidget {
  final PackContext pack;

  const ReadingScreen({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    return PackPartView(
      pack: pack,
      part: PackPart.reading,
      title: 'чтение',
      builder: (context, payload) => _ReadingBody(
        pack: pack,
        content: ReadingContent.fromJson(payload, level: pack.key.level),
      ),
    );
  }
}

class _ReadingBody extends ConsumerStatefulWidget {
  final PackContext pack;
  final ReadingContent content;

  const _ReadingBody({required this.pack, required this.content});

  @override
  ConsumerState<_ReadingBody> createState() => _ReadingBodyState();
}

class _ReadingBodyState extends ConsumerState<_ReadingBody> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// The text as spans: grammar marks highlighted, glossary words marked as
  /// unfamiliar, and every word tappable.
  TextSpan _buildText(AppColorTokens colors) {
    final content = widget.content;
    final text = content.text;
    final marks = content.marks;
    final base = AppTypography.bodyText.copyWith(
      fontSize: 17,
      height: 1.6,
      color: colors.body,
    );
    final glossary = {for (final g in content.glossary) g.word.toLowerCase()};

    bool inMark(int start, int end) =>
        marks.any((m) => start >= m.start && end <= m.end);

    TextSpan styled(String piece, int start, {String? tapWord}) {
      final end = start + piece.length;
      TextSpan span;
      if (inMark(start, end)) {
        span = Mark.grammar(piece, base, colors);
      } else if (tapWord != null && glossary.contains(tapWord.toLowerCase())) {
        span = Mark.unfamiliar(piece, base, colors);
      } else {
        span = TextSpan(text: piece, style: base);
      }
      if (tapWord == null) return span;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _showWord(tapWord);
      _recognizers.add(recognizer);
      return TextSpan(
        text: span.text,
        style: span.style,
        recognizer: recognizer,
      );
    }

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final m in _wordPattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(styled(text.substring(cursor, m.start), cursor));
      }
      spans.add(styled(m.group(0)!, m.start, tapWord: m.group(0)));
      cursor = m.end;
    }
    if (cursor < text.length) spans.add(styled(text.substring(cursor), cursor));
    return TextSpan(children: spans, style: base);
  }

  Future<void> _showWord(String word) async {
    final translation = widget.content.translate(word);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _WordSheet(
        word: word,
        translation: translation,
        onAdd: () async {
          Navigator.of(sheetContext).pop();
          await _addToDeck(word, translation ?? '');
        },
      ),
    );
  }

  Future<void> _addToDeck(String word, String translation) async {
    final messenger = ScaffoldMessenger.of(context);
    final sets = ref.read(wordSetRepositoryProvider);
    final existing = await sets.watchWordSets(unitId: widget.pack.unitId).first;
    final set = existing.isNotEmpty
        ? existing.first
        : await sets.createWordSet(
            unitId: widget.pack.unitId,
            title: 'Слова юнита',
            source: WordSetSource.manual,
          );
    await ref
        .read(wordCardRepositoryProvider)
        .createCard(
          setId: set.id,
          term: word.toLowerCase(),
          translation: translation,
        );
    messenger.showSnackBar(
      SnackBar(content: Text('«${word.toLowerCase()}» добавлено в колоду')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = widget.content;
    final repo = ref.read(packRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.s8,
        AppSpacing.screen,
        AppSpacing.s30,
      ),
      children: [
        Text(
          content.title,
          style: AppTypography.title.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Подсвечена грамматика юнита. Тапните слово — покажу перевод и добавлю в колоду.',
          style: AppTypography.caption.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.s18),
        Text.rich(_buildText(colors)),
        const SizedBox(height: AppSpacing.s30),
        Text(
          'Вопросы',
          style: AppTypography.heading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.s14),
        ExerciseFlow(
          items: [for (final q in content.questions) exerciseFromQuestion(q)],
          onAnswer: (i, answer, correct) => repo.logAttempt(
            widget.pack.packId,
            PackPart.reading,
            itemIndex: i,
            userAnswer: answer,
            isCorrect: correct,
          ),
          onFinished: (score, total) => repo.saveProgress(
            widget.pack.packId,
            PackPart.reading,
            score: score,
            total: total,
          ),
        ),
      ],
    );
  }
}

class _WordSheet extends StatelessWidget {
  final String word;
  final String? translation;
  final VoidCallback onAdd;

  const _WordSheet({
    required this.word,
    required this.translation,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              word,
              style: AppTypography.monoWord.copyWith(
                fontSize: 26,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              translation ?? 'Перевода этого слова в тексте нет — добавлю без него, перевод можно вписать в юните.',
              style: AppTypography.bodyText.copyWith(
                color: translation == null ? colors.muted : colors.body,
              ),
            ),
            const SizedBox(height: AppSpacing.s18),
            PrimaryButton(label: 'В колоду', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
