import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/core/widgets/diff_row.dart';

void main() {
  testWidgets('a long sentence wraps on a narrow screen instead of shrinking', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: DiffRow(
            user: 'Yesterday we have visited the old museum in the city center with friends.',
            correct: 'Yesterday we visited the old museum in the city centre with our friends.',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsNothing);
    final line = tester.getSize(find.textContaining('museum', findRichText: true).last);
    expect(line.height, greaterThan(30)); // more than one line
  });
}
