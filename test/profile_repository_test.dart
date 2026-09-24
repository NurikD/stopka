import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopka/data/db/app_database.dart';
import 'package:stopka/data/repositories/profile_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftProfileRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('a fresh profile is not onboarded and has no level or interests', () async {
    final profile = await repo.ensureProfile();
    expect(profile.isOnboarded, isFalse);
    expect(profile.level, '');
    expect(profile.interests, isEmpty);
  });

  test('onboarding answers survive a round trip', () async {
    final profile = await repo.ensureProfile();
    await repo.updateProfile(profile.copyWith(
      level: 'A2',
      interests: ['travel', 'games'],
      currentTopic: 'Past simple',
      onboardedAt: DateTime.now(),
    ));

    final again = await repo.ensureProfile();
    expect(again.level, 'A2');
    expect(again.interests, ['travel', 'games']);
    expect(again.currentTopic, 'Past simple');
    expect(again.isOnboarded, isTrue);
  });
}
