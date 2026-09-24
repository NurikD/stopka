import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/core/llm/unit_page_service.dart';
import 'package:stopka/core/onboarding/onboarding_service.dart';
import 'package:stopka/core/providers/core_providers.dart';
import 'package:stopka/core/router/app_router.dart';
import 'package:stopka/core/theme/app_theme.dart';
import 'package:stopka/features/onboarding/onboarding_screen.dart';

class _FakeService implements OnboardingService {
  String? level;
  List<String>? interests;
  String? topic;
  UnitPageInfo? page;

  @override
  Future<OnboardingResult> finish({
    required String level,
    required List<String> interestIds,
    String topic = '',
    UnitPageInfo? page,
  }) async {
    this.level = level;
    interests = interestIds;
    this.topic = topic;
    this.page = page;
    return const OnboardingResult(courseId: 'c', unitId: 'u', setId: 's', wordCount: 12, personal: false);
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  test('redirect: unonboarded users are sent to onboarding, onboarded ones away from it', () {
    expect(onboardingRedirect(onboarded: null, location: '/today'), isNull);
    expect(onboardingRedirect(onboarded: false, location: '/today'), '/onboarding');
    expect(onboardingRedirect(onboarded: false, location: '/onboarding'), isNull);
    expect(onboardingRedirect(onboarded: true, location: '/onboarding'), '/today');
    expect(onboardingRedirect(onboarded: true, location: '/courses'), isNull);
  });

  testWidgets('a new user gets through three taps without a key and lands on the first set', (tester) async {
    final service = _FakeService();
    OnboardingResult? done;
    await tester.pumpWidget(ProviderScope(
      overrides: [onboardingServiceProvider.overrideWithValue(service)],
      child: MaterialApp(theme: AppTheme.light(), home: OnboardingScreen(onDone: (r) => done = r)),
    ));

    expect(find.text('Ваш уровень'), findsOneWidget);
    await tester.tap(find.text('B1'));
    await tester.pump();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(find.text('Что вам интересно'), findsOneWidget);
    await tester.tap(find.text('Игры'));
    await tester.tap(find.text('Кино и сериалы'));
    await tester.tap(find.text('Еда'));
    await tester.tap(find.text('Работа')); // a fourth pick is ignored
    await tester.pump();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    expect(find.text('Что проходите сейчас'), findsOneWidget);
    expect(find.text('Пропустить и начать'), findsOneWidget);
    await tester.tap(find.text('Пропустить и начать'));
    await tester.pump(); // the button spinner never settles, so no pumpAndSettle here
    await tester.pump();

    expect(service.level, 'B1');
    expect(service.interests, ['games', 'films', 'food']);
    expect(service.topic, '');
    expect(done?.setId, 's');
  });

  testWidgets('typing a topic changes the button, and Back keeps earlier answers', (tester) async {
    final service = _FakeService();
    await tester.pumpWidget(ProviderScope(
      overrides: [onboardingServiceProvider.overrideWithValue(service)],
      child: MaterialApp(theme: AppTheme.light(), home: OnboardingScreen(onDone: (_) {})),
    ));

    await tester.tap(find.text('A1'));
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Past simple');
    await tester.pump();
    expect(find.text('Начать'), findsOneWidget);

    await tester.tap(find.text('Назад'));
    await tester.tap(find.text('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дальше'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Начать'));
    await tester.pump();
    await tester.pump();

    expect(service.level, 'A1');
    expect(service.topic, 'Past simple');
  });
}
