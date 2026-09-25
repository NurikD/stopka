import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/text/russian_plural.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/theme/tokens.dart';
import 'package:stopka/core/widgets/diff_row.dart';
import 'package:stopka/core/widgets/stack_progress.dart';

Widget _host(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: Scaffold(body: Center(child: child)));
}

List<RichText> _wordLines(WidgetTester tester) {
  return tester
      .widgetList<RichText>(find.byType(RichText))
      .where((r) {
        final text = r.text.toPlainText();
        return text.length > 2 && text != 'верно';
      })
      .toList();
}

/// The single-letter spans of a line, with the style each one resolves to
/// (Text.rich nests our spans one level under its own root).
List<TextSpan> _letters(RichText line) {
  final leaves = <TextSpan>[];
  line.text.visitChildren((span) {
    if (span is TextSpan && span.text != null && span.text!.length == 1) leaves.add(span);
    return true;
  });
  return leaves;
}

void main() {
  group('DiffRow', () {
    testWidgets('both lines start at the same x, so letters share columns', (tester) async {
      await tester.pumpWidget(_host(const DiffRow(user: 'achive', correct: 'achieve')));

      final lines = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().length > 2 && w.text.toPlainText() != 'верно',
      );
      expect(lines, findsNWidgets(2));
      expect(tester.getTopLeft(lines.at(0)).dx, tester.getTopLeft(lines.at(1)).dx);
    });

    testWidgets('both lines use the identical mono font, size and tracking', (tester) async {
      await tester.pumpWidget(_host(const DiffRow(user: 'achive', correct: 'achieve')));

      final lines = _wordLines(tester);
      final a = _letters(lines[0]).first.style!;
      final b = _letters(lines[1]).first.style!;
      expect(a.fontFamily, 'JetBrainsMono');
      expect(a.fontFamily, b.fontFamily);
      expect(a.fontSize, b.fontSize);
      expect(a.letterSpacing, b.letterSpacing);
    });

    testWidgets('a wrong letter is danger in "вы" and accent-underlined in "верно"', (tester) async {
      await tester.pumpWidget(_host(const DiffRow(user: 'achive', correct: 'achieve')));
      final colors = AppColorTokens.light;

      final lines = _wordLines(tester);
      final userLetters = _letters(lines[0]);
      final correctLetters = _letters(lines[1]);

      // a c h i | v e vs e v e -> positions 4 and 5 differ.
      expect(userLetters[0].style!.color, colors.ink);
      expect(userLetters[4].style!.color, colors.danger);
      expect(userLetters[5].style!.color, colors.danger);

      expect(correctLetters[0].style!.color, colors.ink);
      expect(correctLetters[4].style!.color, colors.accent);
      expect(correctLetters[4].style!.decoration, TextDecoration.underline);
      expect(correctLetters[4].style!.decorationThickness, 2);
      // The final letter the user never typed is marked too.
      expect(correctLetters[6].style!.color, colors.accent);
    });

    testWidgets('a skipped (empty) answer shows a dash, not danger letters', (tester) async {
      await tester.pumpWidget(_host(const DiffRow(user: '', correct: 'goal')));
      expect(find.text('—', findRichText: true), findsOneWidget);
    });
  });

  group('StackProgress', () {
    testWidgets('colours segments: passed ink, current accent, upcoming line, wrong danger', (tester) async {
      await tester.pumpWidget(_host(const SizedBox(width: 200, child: StackProgress(total: 4, current: 2, wrong: {1}))));
      final colors = AppColorTokens.light;

      final segments = tester.widgetList<ColoredBox>(find.descendant(
        of: find.byType(StackProgress),
        matching: find.byType(ColoredBox),
      )).map((c) => c.color).toList();

      expect(segments, [colors.ink, colors.danger, colors.accent, colors.line]);
    });
  });

  group('pluralRu', () {
    String letters(int n) => pluralRu(n, one: 'буква', few: 'буквы', many: 'букв');

    test('picks the right form', () {
      expect(letters(0), 'букв');
      expect(letters(1), 'буква');
      expect(letters(2), 'буквы');
      expect(letters(5), 'букв');
      expect(letters(11), 'букв');
      expect(letters(12), 'букв');
      expect(letters(21), 'буква');
      expect(letters(22), 'буквы');
    });
  });
}
