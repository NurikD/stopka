import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/theme/tokens.dart';
import 'package:stopka/core/widgets/skill_row.dart';
import 'package:stopka/domain/repositories/card_state_repository.dart';
import 'package:stopka/features/today/today_screen.dart';

class _CountsRepo implements CardStateRepository {
  final int due;
  final int fresh;
  _CountsRepo({required this.due, required this.fresh});

  @override
  Stream<int> watchDueCount(DateTime now) => Stream.value(due);

  @override
  Stream<int> watchNewCount() => Stream.value(fresh);

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

Widget _app({required int due, required int fresh, int limit = 20, int done = 0, int streak = 0}) {
  return ProviderScope(
    key: UniqueKey(), // fresh scope per pump so new overrides really apply
    overrides: [
      cardStateRepositoryProvider.overrideWithValue(_CountsRepo(due: due, fresh: fresh)),
      newCardLimitProvider.overrideWith((ref) async => limit),
      reviewsTodayProvider.overrideWith((ref) async => done),
      streakDaysProvider.overrideWith((ref) async => streak),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const TodayScreen()),
  );
}

void main() {
  testWidgets('shows only the real "Слова" skill row, with honest done / planned numbers', (tester) async {
    // 12 due + 45 new, limit 20 -> 32 left; 5 already done today -> 5 / 37.
    await tester.pumpWidget(_app(due: 12, fresh: 45, limit: 20, done: 5));
    await tester.pumpAndSettle();

    expect(find.text('Слова'), findsOneWidget);
    expect(find.text('5 / 37'), findsOneWidget);
    expect(find.byType(SkillRow), findsOneWidget);
    // Blocks that do not exist yet must not be drawn.
    for (final placeholder in ['Чтение', 'Аудио', 'Письмо', '02', '03', '04']) {
      expect(find.text(placeholder), findsNothing, reason: placeholder);
    }
  });

  testWidgets('the promised count never exceeds what a session will serve', (tester) async {
    await tester.pumpWidget(_app(due: 0, fresh: 100, limit: 10, done: 0));
    await tester.pumpAndSettle();

    expect(find.text('0 / 10'), findsOneWidget);
  });

  testWidgets('the number is accent once something is done, lineStrong before', (tester) async {
    await tester.pumpWidget(_app(due: 3, fresh: 0, done: 0));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('01')).style!.color, AppColorTokens.light.lineStrong);

    await tester.pumpWidget(_app(due: 3, fresh: 0, done: 2));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('01')).style!.color, AppColorTokens.light.accent);
  });

  testWidgets('with nothing to do it shows the invitation, not an empty row', (tester) async {
    await tester.pumpWidget(_app(due: 0, fresh: 0, done: 0));
    await tester.pumpAndSettle();

    expect(find.byType(SkillRow), findsNothing);
    expect(find.textContaining('Пока нечего повторять'), findsOneWidget);
    expect(find.text('Начать повторение'), findsNothing);
  });

  testWidgets('shows the streak in the header', (tester) async {
    await tester.pumpWidget(_app(due: 1, fresh: 0, streak: 7));
    await tester.pumpAndSettle();

    expect(find.text('7 дней подряд'), findsOneWidget);
  });
}
