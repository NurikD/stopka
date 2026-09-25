import '../../domain/models/profile.dart';
import '../../domain/models/unit.dart';
import '../onboarding/starter_content.dart';
import 'pack_content.dart';

/// The pack a unit uses: the learner's level (or the course level), the
/// unit's own topics, and their first interest. Two units with the same
/// answers share one pack, so nothing is generated twice.
PackKey packKeyFor({required Unit unit, required Profile? profile, String courseLevel = ''}) {
  final chosen = profile?.level ?? '';
  final level = effectiveLevel(chosen.isNotEmpty ? chosen : courseLevel);
  return PackKey(
    level: level,
    grammarTopic: unit.grammarTopic,
    vocabTopic: unit.vocabTopic.isNotEmpty ? unit.vocabTopic : (profile?.currentTopic ?? ''),
    interest: (profile?.interests ?? const <String>[]).firstOrNull ?? '',
  );
}
