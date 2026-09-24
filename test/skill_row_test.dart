import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/theme/tokens.dart';
import 'package:stopka/core/widgets/skill_row.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
  );
}

void main() {
  testWidgets('fills the straight 3px track in proportion to progress', (tester) async {
    await tester.pumpWidget(_host(const SkillRow(
      number: '01',
      label: 'Слова',
      counter: '18 / 24',
      progress: 0.75,
      started: true,
    )));

    final fill = tester.widgetList<Positioned>(find.byType(Positioned)).firstWhere((p) => p.width != null);
    // Card is 300 wide; horizontal padding 18*2, number 22, gap 14.
    const trackWidth = 300 - 18 * 2 - 22 - 14;
    expect(fill.width, closeTo(trackWidth * 0.75, 1));
  });

  testWidgets('a progress above 1 is clamped to a full track', (tester) async {
    await tester.pumpWidget(_host(const SkillRow(
      number: '01',
      label: 'Слова',
      counter: '30 / 24',
      progress: 1.25,
      started: true,
    )));

    final fill = tester.widgetList<Positioned>(find.byType(Positioned)).firstWhere((p) => p.width != null);
    const trackWidth = 300 - 18 * 2 - 22 - 14;
    expect(fill.width, closeTo(trackWidth, 1));
  });

  testWidgets('an unstarted block shows its number in lineStrong', (tester) async {
    await tester.pumpWidget(_host(const SkillRow(
      number: '02',
      label: 'Чтение',
      counter: '0 / 1',
      progress: 0,
      started: false,
    )));

    expect(tester.widget<Text>(find.text('02')).style!.color, AppColorTokens.dark.lineStrong);
  });
}
